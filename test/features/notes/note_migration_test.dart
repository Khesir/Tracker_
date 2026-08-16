import 'package:flutter_test/flutter_test.dart';
import 'package:time_track/core/models/music_entry_model.dart';
import 'package:time_track/core/models/note_model.dart';
import 'package:time_track/core/models/project_model.dart';
import 'package:time_track/core/models/session_model.dart';
import 'package:time_track/features/notes/data/note_migration.dart';
import 'package:time_track/features/notes/domain/repository/notes_repository.dart';
import 'package:time_track/features/projects/domain/repository/projects_repository.dart';
import 'package:time_track/features/sessions/domain/repository/sessions_repository.dart';

class FakeProjectsRepository implements ProjectsRepository {
  final Map<String, ProjectModel> byId = {};
  final List<String> savedIds = [];

  @override
  Future<List<ProjectModel>> getAll() async => byId.values.toList();

  @override
  Future<ProjectModel?> getById(String id) async => byId[id];

  @override
  Future<void> save(ProjectModel project) async {
    byId[project.id] = project;
    savedIds.add(project.id);
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

class FakeSessionsRepository implements SessionsRepository {
  final Map<String, List<SessionModel>> byProject = {};

  @override
  Future<List<SessionModel>> getAll() async =>
      byProject.values.expand((s) => s).toList();

  @override
  Future<List<SessionModel>> getByProject(String projectId) async =>
      byProject[projectId] ?? [];

  @override
  Future<List<SessionModel>> getByDateRange(DateTime from, DateTime to) async =>
      [];

  @override
  Future<SessionModel?> getById(String id) async => null;

  @override
  Future<void> save(SessionModel session) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> softDeleteByProject(String projectId) async {}

  @override
  Future<void> restoreByProject(String projectId) async {}

  @override
  Future<void> purgeByProject(String projectId) async {}
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

ProjectModel _project({
  required String id,
  String name = 'Project',
  String? noteId,
}) {
  return ProjectModel(
    id: id,
    name: name,
    colorHex: '#FFFFFF',
    createdAt: DateTime(2026, 1, 1),
    noteId: noteId,
  );
}

SessionModel _session({
  required String id,
  required String projectId,
  required DateTime startedAt,
  String noteJson = '',
}) {
  return SessionModel(
    id: id,
    projectId: projectId,
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 30)),
    durationSeconds: 1800,
    noteJson: noteJson,
    musicLog: const <MusicEntryModel>[],
  );
}

void main() {
  late FakeProjectsRepository projects;
  late FakeSessionsRepository sessions;
  late FakeNotesRepository notes;

  setUp(() {
    projects = FakeProjectsRepository();
    sessions = FakeSessionsRepository();
    notes = FakeNotesRepository();
  });

  test('seeds a note from the most-recent-by-startedAt session with noteJson', () async {
    projects.byId['p1'] = _project(id: 'p1');
    sessions.byProject['p1'] = [
      _session(
        id: 's1',
        projectId: 'p1',
        startedAt: DateTime(2026, 1, 1),
        noteJson: '{"old":true}',
      ),
      _session(
        id: 's2',
        projectId: 'p1',
        startedAt: DateTime(2026, 3, 1),
        noteJson: '{"newest":true}',
      ),
      _session(
        id: 's3',
        projectId: 'p1',
        startedAt: DateTime(2026, 2, 1),
        noteJson: '{"middle":true}',
      ),
    ];

    await runLegacyNoteMigration(
      projects: projects,
      sessions: sessions,
      notes: notes,
    );

    expect(notes.saved, hasLength(1));
    expect(notes.saved.single.noteJson, '{"newest":true}');

    final p1 = projects.byId['p1']!;
    expect(p1.noteId, notes.saved.single.id);
  });

  test('creates exactly one note per eligible project', () async {
    projects.byId['p1'] = _project(id: 'p1');
    projects.byId['p2'] = _project(id: 'p2');
    sessions.byProject['p1'] = [
      _session(id: 's1', projectId: 'p1', startedAt: DateTime(2026, 1, 1), noteJson: '{"a":1}'),
    ];
    sessions.byProject['p2'] = [
      _session(id: 's2', projectId: 'p2', startedAt: DateTime(2026, 1, 1), noteJson: '{"b":1}'),
    ];

    await runLegacyNoteMigration(
      projects: projects,
      sessions: sessions,
      notes: notes,
    );

    expect(notes.saved, hasLength(2));
    expect(projects.byId['p1']!.noteId, isNotNull);
    expect(projects.byId['p2']!.noteId, isNotNull);
    expect(projects.byId['p1']!.noteId, isNot(projects.byId['p2']!.noteId));
  });

  test('projects with no sessions get no note', () async {
    projects.byId['p1'] = _project(id: 'p1');

    await runLegacyNoteMigration(
      projects: projects,
      sessions: sessions,
      notes: notes,
    );

    expect(notes.saved, isEmpty);
    expect(projects.byId['p1']!.noteId, isNull);
  });

  test('projects with only empty-noteJson sessions get no note', () async {
    projects.byId['p1'] = _project(id: 'p1');
    sessions.byProject['p1'] = [
      _session(id: 's1', projectId: 'p1', startedAt: DateTime(2026, 1, 1), noteJson: ''),
      _session(id: 's2', projectId: 'p1', startedAt: DateTime(2026, 2, 1), noteJson: ''),
    ];

    await runLegacyNoteMigration(
      projects: projects,
      sessions: sessions,
      notes: notes,
    );

    expect(notes.saved, isEmpty);
    expect(projects.byId['p1']!.noteId, isNull);
  });

  test('projects that already have a noteId are left completely untouched', () async {
    projects.byId['p1'] = _project(id: 'p1', noteId: 'existing-note');
    sessions.byProject['p1'] = [
      _session(id: 's1', projectId: 'p1', startedAt: DateTime(2026, 1, 1), noteJson: '{"legacy":true}'),
    ];

    await runLegacyNoteMigration(
      projects: projects,
      sessions: sessions,
      notes: notes,
    );

    expect(notes.saved, isEmpty);
    expect(projects.byId['p1']!.noteId, 'existing-note');
  });

  test('running twice produces no duplicates and no changes on the second run', () async {
    projects.byId['p1'] = _project(id: 'p1');
    sessions.byProject['p1'] = [
      _session(id: 's1', projectId: 'p1', startedAt: DateTime(2026, 1, 1), noteJson: '{"a":1}'),
    ];

    await runLegacyNoteMigration(
      projects: projects,
      sessions: sessions,
      notes: notes,
    );

    final noteIdAfterFirstRun = projects.byId['p1']!.noteId;
    final savedCountAfterFirstRun = notes.saved.length;

    await runLegacyNoteMigration(
      projects: projects,
      sessions: sessions,
      notes: notes,
    );

    expect(notes.saved, hasLength(savedCountAfterFirstRun));
    expect(projects.byId['p1']!.noteId, noteIdAfterFirstRun);
  });

  test('does not modify or clear legacy SessionModel.noteJson', () async {
    projects.byId['p1'] = _project(id: 'p1');
    final session = _session(
      id: 's1',
      projectId: 'p1',
      startedAt: DateTime(2026, 1, 1),
      noteJson: '{"legacy":true}',
    );
    sessions.byProject['p1'] = [session];

    await runLegacyNoteMigration(
      projects: projects,
      sessions: sessions,
      notes: notes,
    );

    expect(sessions.byProject['p1']!.single.noteJson, '{"legacy":true}');
  });
}
