import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../core/models/session_model.dart';
import '../../../../core/media/media_info.dart';
import '../../domain/repository/timer_repository.dart';
import '../../presentation/state/timer_ui_state.dart';
import '../../../sessions/domain/repository/sessions_repository.dart';

class TimerController {
  final TimerRepository _timerRepo;
  final SessionsRepository _sessionsRepo;
  final TimerUiState uiState;

  Timer? _ticker;
  Timer? _inactivityTimer;
  SessionModel? _activeSession;
  int _inactivityTimeoutSeconds = 300;
  String _inactivityBehavior = 'stop'; // 'disabled', 'pause', 'stop'

  TimerController(this._timerRepo, this._sessionsRepo)
      : uiState = TimerUiState();

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

    _activeSession = SessionModel(
      id: const Uuid().v4(),
      projectId: projectId,
      startedAt: DateTime.now(),
      durationSeconds: 0,
      noteJson: '',
      musicLog: [],
    );

    await _timerRepo.saveSession(_activeSession!);
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

  void updateNote(String noteJson) {
    if (_activeSession == null) return;
    _activeSession = _activeSession!.copyWith(noteJson: noteJson);
    _timerRepo.saveSession(_activeSession!);
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
