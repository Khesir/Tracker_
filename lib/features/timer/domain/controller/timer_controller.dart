import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../core/models/session_model.dart';
import '../../../../core/models/note_model.dart';
import '../../../../core/media/media_info.dart';
import '../../domain/repository/timer_repository.dart';
import '../../presentation/state/timer_ui_state.dart';
import '../../../sessions/domain/repository/sessions_repository.dart';
import '../../../notes/domain/repository/notes_repository.dart';
import '../../../projects/domain/repository/projects_repository.dart';

/// Where a [TimerController] note read/write resolved against, distinctly
/// separating "nothing to resolve a project from at all" from "resolved a
/// project, but it has no note linked" — issue 011's UI reacts differently
/// to each (no create-or-link prompt possible without a project; a
/// create-or-link prompt when there's a project but no note).
enum NoteResolution { noProject, noNoteLinked, hasNote }

/// Result of resolving "the current note" for the timer widget — i.e. the
/// note linked to whichever project is currently in scope (the running
/// session's project, or the last-tracked project while idle).
class TimerNoteState {
  final NoteResolution resolution;
  final String? projectId;
  final String? noteId;
  final String? noteJson;

  const TimerNoteState._({
    required this.resolution,
    this.projectId,
    this.noteId,
    this.noteJson,
  });

  const TimerNoteState.noProject() : this._(resolution: NoteResolution.noProject);

  const TimerNoteState.noNoteLinked(String projectId)
      : this._(resolution: NoteResolution.noNoteLinked, projectId: projectId);

  const TimerNoteState.hasNote({
    required String projectId,
    required String noteId,
    required String noteJson,
  }) : this._(
          resolution: NoteResolution.hasNote,
          projectId: projectId,
          noteId: noteId,
          noteJson: noteJson,
        );

  bool get hasProject => resolution != NoteResolution.noProject;
  bool get hasNoteLinked => resolution == NoteResolution.hasNote;
}

class TimerController {
  final TimerRepository _timerRepo;
  final SessionsRepository _sessionsRepo;
  final ProjectsRepository _projectsRepo;
  final NotesRepository _notesRepo;
  final TimerUiState uiState;

  Timer? _ticker;
  Timer? _inactivityTimer;
  SessionModel? _activeSession;
  int _inactivityTimeoutSeconds = 300;
  String _inactivityBehavior = 'stop'; // 'disabled', 'pause', 'stop'

  TimerController(
    this._timerRepo,
    this._sessionsRepo,
    this._projectsRepo,
    this._notesRepo,
  ) : uiState = TimerUiState();

  void setInactivityTimeout(int seconds) {
    _inactivityTimeoutSeconds = seconds;
  }

  void setInactivityBehavior(String behavior) {
    _inactivityBehavior = behavior;
  }

  Future<void> resume() async {
    final saved = await _timerRepo.getActiveSession();
    if (saved == null || saved.endedAt != null) return;
    _activeSession = saved;
    _startTicker();
    _resetInactivityTimer();
    uiState.update((s) => s.copyWith(
          status: TimerStatus.running,
          projectId: saved.projectId,
        ));
  }

  Future<void> start({
    required String projectId,
    required String projectName,
  }) async {
    if (uiState.state.isRunning) return;

    final project = await _projectsRepo.getById(projectId);

    _activeSession = SessionModel(
      id: const Uuid().v4(),
      projectId: projectId,
      startedAt: DateTime.now(),
      durationSeconds: 0,
      // Legacy field — required by the model but no longer written to by
      // new code; note content now lives on NoteModel, linked below.
      noteJson: '',
      noteId: project?.noteId,
      musicLog: [],
    );

    await _timerRepo.saveSession(_activeSession!);
    await _timerRepo.setLastProjectId(projectId);
    _startTicker();
    _resetInactivityTimer();

    uiState.emit(TimerUiData(
      status: TimerStatus.running,
      elapsed: Duration.zero,
      projectId: projectId,
      projectName: projectName,
    ));
  }

  Future<void> pause() async {
    if (!uiState.state.isRunning) return;
    _ticker?.cancel();
    _ticker = null;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    uiState.update((s) => s.copyWith(status: TimerStatus.paused));
  }

  Future<void> unpause() async {
    if (!uiState.state.isPaused) return;
    _startTicker();
    _resetInactivityTimer();
    uiState.update((s) => s.copyWith(status: TimerStatus.running));
  }

  Future<void> stop() async {
    _ticker?.cancel();
    _inactivityTimer?.cancel();
    _ticker = null;
    _inactivityTimer = null;

    if (_activeSession == null) return;

    final elapsed = uiState.state.elapsed;
    final ended = _activeSession!.copyWith(
      endedAt: DateTime.now(),
      durationSeconds: elapsed.inSeconds,
    );

    await _sessionsRepo.save(ended);
    await _timerRepo.clearActiveSession();
    _activeSession = null;

    uiState.emit(const TimerUiData(status: TimerStatus.idle));
  }

  /// Resolves "the current project" as the active session's project while
  /// running, otherwise the last-tracked project (persisted via
  /// [TimerRepository.getLastProjectId]) — so note editing works
  /// identically whether a session is active or the app is idle.
  Future<String?> _currentProjectId() async {
    if (_activeSession != null) return _activeSession!.projectId;
    return _timerRepo.getLastProjectId();
  }

  /// Resolves the note linked to the current project (see
  /// [_currentProjectId]), distinguishing "no project to resolve at all"
  /// from "resolved a project with no note linked" from "resolved a note".
  Future<TimerNoteState> resolveNoteState() async {
    final projectId = await _currentProjectId();
    if (projectId == null) return const TimerNoteState.noProject();

    final project = await _projectsRepo.getById(projectId);
    final noteId = project?.noteId;
    if (noteId == null) return TimerNoteState.noNoteLinked(projectId);

    final note = await _notesRepo.getById(noteId);
    return TimerNoteState.hasNote(
      projectId: projectId,
      noteId: noteId,
      noteJson: note?.noteJson ?? '',
    );
  }

  /// Writes [noteJson] to the `NoteModel` linked to the current project
  /// (see [_currentProjectId]). No-ops (does not throw) when there is no
  /// current project, or the current project has no note linked — issue
  /// 011's UI is responsible for offering to create/link a note first in
  /// that case, using [resolveNoteState] to detect it.
  Future<void> updateNote(String noteJson) async {
    final projectId = await _currentProjectId();
    if (projectId == null) return;

    final project = await _projectsRepo.getById(projectId);
    final noteId = project?.noteId;
    if (noteId == null) return;

    final now = DateTime.now();
    final existing = await _notesRepo.getById(noteId);
    final updated = (existing ??
            NoteModel(id: noteId, noteJson: '', createdAt: now, updatedAt: now))
        .copyWith(noteJson: noteJson, updatedAt: now);
    await _notesRepo.save(updated);
  }

  void onMediaChanged(MediaInfo info) {
    uiState.update((s) => s.copyWith(media: info));
  }

  void _startTicker() {
    _ticker?.cancel();
    final base = _activeSession?.durationSeconds ?? 0;
    final start = DateTime.now().subtract(Duration(seconds: base));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(start);
      uiState.update((s) => s.copyWith(elapsed: elapsed));
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    if (_inactivityBehavior == 'disabled') return;
    _inactivityTimer = Timer(
      Duration(seconds: _inactivityTimeoutSeconds),
      () => _inactivityBehavior == 'pause' ? pause() : stop(),
    );
  }

  void dispose() {
    _ticker?.cancel();
    _inactivityTimer?.cancel();
    uiState.dispose();
  }
}
