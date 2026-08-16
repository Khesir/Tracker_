import 'package:flutter_test/flutter_test.dart';
import 'package:time_track/core/models/note_model.dart';
import 'package:time_track/core/models/project_model.dart';
import 'package:time_track/core/models/session_model.dart';
import 'package:time_track/features/notes/domain/repository/notes_repository.dart';
import 'package:time_track/features/projects/domain/repository/projects_repository.dart';
import 'package:time_track/features/sessions/domain/repository/sessions_repository.dart';
import 'package:time_track/features/timer/domain/controller/timer_controller.dart';
import 'package:time_track/features/timer/domain/repository/timer_repository.dart';

class FakeTimerRepository implements TimerRepository {
  SessionModel? active;
  String? lastProjectId;
  final List<String> calls = [];

  @override
  Future<void> saveSession(SessionModel session) async {
    active = session;
    calls.add('saveSession:${session.id}');
  }

  @override
  Future<SessionModel?> getActiveSession() async => active;

  @override
  Future<void> clearActiveSession() async {
    active = null;
    calls.add('clearActiveSession');
  }

  @override
  Future<void> setLastProjectId(String? projectId) async {
    lastProjectId = projectId;
    calls.add('setLastProjectId:$projectId');
  }

  @override
  Future<String?> getLastProjectId() async => lastProjectId;
}

class FakeSessionsRepository implements SessionsRepository {
  final List<SessionModel> saved = [];

  @override
  Future<List<SessionModel>> getAll() async => saved;

  @override
  Future<List<SessionModel>> getByProject(String projectId) async =>
      saved.where((s) => s.projectId == projectId).toList();

  @override
  Future<List<SessionModel>> getByDateRange(DateTime from, DateTime to) async => [];

  @override
  Future<SessionModel?> getById(String id) async =>
      saved.where((s) => s.id == id).cast<SessionModel?>().firstOrNull;

  @override
  Future<void> save(SessionModel session) async {
    saved.add(session);
  }

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> softDeleteByProject(String projectId) async {}

  @override
  Future<void> restoreByProject(String projectId) async {}

  @override
  Future<void> purgeByProject(String projectId) async {}
}

class FakeProjectsRepository implements ProjectsRepository {
  final Map<String, ProjectModel> byId = {};

  @override
  Future<List<ProjectModel>> getAll() async => byId.values.toList();

  @override
  Future<ProjectModel?> getById(String id) async => byId[id];

  @override
  Future<void> save(ProjectModel project) async {
    byId[project.id] = project;
  }

  @override
  Future<void> delete(String id) async {
    byId.remove(id);
  }

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> restore(String id) async {}

  @override
  Future<void> purge(String id) async {}

  @override
  Future<List<ProjectModel>> getDeleted() async => [];

  @override
  Future<void> unlinkNote(String projectId) async {
    final p = byId[projectId];
    if (p == null) return;
    byId[projectId] = ProjectModel(
      id: p.id,
      name: p.name,
      colorHex: p.colorHex,
      targetMinutes: p.targetMinutes,
      createdAt: p.createdAt,
      deletedAt: p.deletedAt,
      noteId: null,
    );
  }
}

class FakeNotesRepository implements NotesRepository {
  final Map<String, NoteModel> byId = {};
  final List<NoteModel> saved = [];

  @override
  Future<List<NoteModel>> getAll() async => byId.values.toList();

  @override
  Future<NoteModel?> getById(String id) async => byId[id];

  @override
  Future<void> save(NoteModel note) async {
    byId[note.id] = note;
    saved.add(note);
  }

  @override
  Future<void> delete(String id) async {
    byId.remove(id);
  }

  @override
  Future<void> unlinkFromProject(String projectId) async {}
}

ProjectModel _project({required String id, String? noteId}) => ProjectModel(
      id: id,
      name: 'Project $id',
      colorHex: '#FFFFFF',
      createdAt: DateTime(2026, 1, 1),
      noteId: noteId,
    );

NoteModel _note({required String id, required String noteJson, DateTime? updatedAt}) =>
    NoteModel(
      id: id,
      noteJson: noteJson,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: updatedAt ?? DateTime(2026, 1, 1),
    );

void main() {
  late FakeTimerRepository timerRepo;
  late FakeSessionsRepository sessionsRepo;
  late FakeProjectsRepository projectsRepo;
  late FakeNotesRepository notesRepo;

  setUp(() {
    timerRepo = FakeTimerRepository();
    sessionsRepo = FakeSessionsRepository();
    projectsRepo = FakeProjectsRepository();
    notesRepo = FakeNotesRepository();
  });

  TimerController buildController() =>
      TimerController(timerRepo, sessionsRepo, projectsRepo, notesRepo);

  group('start()', () {
    test('snapshots the started project\'s current noteId onto the new session', () async {
      projectsRepo.byId['p1'] = _project(id: 'p1', noteId: 'n1');
      final controller = buildController();

      await controller.start(projectId: 'p1', projectName: 'Project p1');

      expect(timerRepo.active, isNotNull);
      expect(timerRepo.active!.noteId, 'n1');
    });

    test('snapshots a null noteId when the project has no linked note', () async {
      projectsRepo.byId['p1'] = _project(id: 'p1');
      final controller = buildController();

      await controller.start(projectId: 'p1', projectName: 'Project p1');

      expect(timerRepo.active!.noteId, isNull);
    });

    test('updates the last-tracked project id', () async {
      projectsRepo.byId['p1'] = _project(id: 'p1');
      final controller = buildController();

      await controller.start(projectId: 'p1', projectName: 'Project p1');

      expect(timerRepo.lastProjectId, 'p1');
    });

    test('does not write to the legacy noteJson field', () async {
      projectsRepo.byId['p1'] = _project(id: 'p1', noteId: 'n1');
      final controller = buildController();

      await controller.start(projectId: 'p1', projectName: 'Project p1');

      // legacy field remains untouched/empty from new code — never written
      // with note content by the new start() path.
      expect(timerRepo.active!.noteJson, '');
    });
  });

  group('resolveNoteState() while running', () {
    test('resolves against the active session\'s project and reports hasNote', () async {
      projectsRepo.byId['p1'] = _project(id: 'p1', noteId: 'n1');
      notesRepo.byId['n1'] = _note(id: 'n1', noteJson: '{"hello":true}');
      final controller = buildController();
      await controller.start(projectId: 'p1', projectName: 'Project p1');

      final state = await controller.resolveNoteState();

      expect(state.resolution, NoteResolution.hasNote);
      expect(state.projectId, 'p1');
      expect(state.noteId, 'n1');
      expect(state.noteJson, '{"hello":true}');
    });

    test('reports noNoteLinked distinctly when the running project has no noteId', () async {
      projectsRepo.byId['p1'] = _project(id: 'p1');
      final controller = buildController();
      await controller.start(projectId: 'p1', projectName: 'Project p1');

      final state = await controller.resolveNoteState();

      expect(state.resolution, NoteResolution.noNoteLinked);
      expect(state.projectId, 'p1');
      expect(state.hasProject, isTrue);
      expect(state.hasNoteLinked, isFalse);
    });

    test('updateNote() writes through to the linked NoteModel and bumps updatedAt', () async {
      projectsRepo.byId['p1'] = _project(id: 'p1', noteId: 'n1');
      notesRepo.byId['n1'] =
          _note(id: 'n1', noteJson: 'old', updatedAt: DateTime(2020, 1, 1));
      final controller = buildController();
      await controller.start(projectId: 'p1', projectName: 'Project p1');

      await controller.updateNote('new content');

      final saved = notesRepo.byId['n1']!;
      expect(saved.noteJson, 'new content');
      expect(saved.updatedAt.isAfter(DateTime(2020, 1, 1)), isTrue);
    });
  });

  group('resolveNoteState() while idle', () {
    test('resolves against the last-tracked project instead of failing/no-oping', () async {
      projectsRepo.byId['p2'] = _project(id: 'p2', noteId: 'n2');
      notesRepo.byId['n2'] = _note(id: 'n2', noteJson: '{"idle":true}');
      timerRepo.lastProjectId = 'p2';
      // Fresh controller instance — nothing running, simulates a restart
      // reading persisted "last tracked project" state from TimerRepository.
      final controller = buildController();

      final state = await controller.resolveNoteState();

      expect(state.resolution, NoteResolution.hasNote);
      expect(state.projectId, 'p2');
      expect(state.noteJson, '{"idle":true}');
    });

    test('survives across a fresh TimerController instance reading the same repo', () async {
      projectsRepo.byId['p1'] = _project(id: 'p1', noteId: 'n1');
      notesRepo.byId['n1'] = _note(id: 'n1', noteJson: 'from before restart');
      final first = buildController();
      await first.start(projectId: 'p1', projectName: 'Project p1');
      await first.stop();

      // Simulate app restart: brand-new TimerController wired to the same
      // (persisted) TimerRepository.
      final second = buildController();
      final state = await second.resolveNoteState();

      expect(state.resolution, NoteResolution.hasNote);
      expect(state.projectId, 'p1');
      expect(state.noteJson, 'from before restart');
    });

    test('updateNote() while idle writes through to the last-tracked project\'s note', () async {
      projectsRepo.byId['p2'] = _project(id: 'p2', noteId: 'n2');
      notesRepo.byId['n2'] = _note(id: 'n2', noteJson: 'old idle content');
      timerRepo.lastProjectId = 'p2';
      final controller = buildController();

      await controller.updateNote('updated idle content');

      expect(notesRepo.byId['n2']!.noteJson, 'updated idle content');
    });

    test('reports noProject distinctly when nothing is running and nothing was ever tracked',
        () async {
      final controller = buildController();

      final state = await controller.resolveNoteState();

      expect(state.resolution, NoteResolution.noProject);
      expect(state.hasProject, isFalse);
      expect(state.hasNoteLinked, isFalse);
      expect(state.projectId, isNull);
    });

    test('updateNote() no-ops (does not throw, does not write) when there is no project at all',
        () async {
      final controller = buildController();

      await controller.updateNote('orphan content');

      expect(notesRepo.saved, isEmpty);
    });

    test('reports noNoteLinked distinctly from noProject when idle project has no note',
        () async {
      projectsRepo.byId['p3'] = _project(id: 'p3');
      timerRepo.lastProjectId = 'p3';
      final controller = buildController();

      final state = await controller.resolveNoteState();

      expect(state.resolution, NoteResolution.noNoteLinked);
      expect(state.hasProject, isTrue);
      expect(state.projectId, 'p3');
    });
  });
}
