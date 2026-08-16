import 'package:flutter_test/flutter_test.dart';
import 'package:time_track/core/cache/local_cache.dart';
import 'package:time_track/core/models/project_model.dart';
import 'package:time_track/features/projects/data/datasource/projects_local_datasource.dart';
import 'package:time_track/features/projects/data/repository/projects_repository_impl.dart';
import 'package:time_track/features/sessions/domain/repository/sessions_repository.dart';
import 'package:time_track/core/models/session_model.dart';
import 'package:time_track/features/notes/domain/repository/notes_repository.dart';
import 'package:time_track/core/models/note_model.dart';

class FakeLocalCache implements LocalCache {
  final Map<String, Map<String, Map<String, dynamic>>> _boxes = {};

  Map<String, Map<String, dynamic>> _boxFor(String box) =>
      _boxes.putIfAbsent(box, () => {});

  @override
  Future<Map<String, dynamic>?> get(String box, String key) async =>
      _boxFor(box)[key];

  @override
  Future<List<Map<String, dynamic>>> getAll(String box) async =>
      _boxFor(box).values.toList();

  @override
  Future<void> put(String box, String key, Map<String, dynamic> data) async {
    _boxFor(box)[key] = data;
  }

  @override
  Future<void> putAll(String box, Map<String, Map<String, dynamic>> entries) async {
    _boxFor(box).addAll(entries);
  }

  @override
  Future<void> delete(String box, String key) async {
    _boxFor(box).remove(key);
  }

  @override
  Future<void> clear(String box) async {
    _boxFor(box).clear();
  }

  @override
  Future<void> clearAll() async {
    _boxes.clear();
  }

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async {}
}

class FakeSessionsRepository implements SessionsRepository {
  final List<String> softDeletedProjectIds = [];
  final List<String> restoredProjectIds = [];
  final List<String> purgedProjectIds = [];

  @override
  Future<void> softDeleteByProject(String projectId) async {
    softDeletedProjectIds.add(projectId);
  }

  @override
  Future<void> restoreByProject(String projectId) async {
    restoredProjectIds.add(projectId);
  }

  @override
  Future<void> purgeByProject(String projectId) async {
    purgedProjectIds.add(projectId);
  }

  @override
  Future<List<SessionModel>> getAll() async => [];

  @override
  Future<List<SessionModel>> getByProject(String projectId) async => [];

  @override
  Future<List<SessionModel>> getByDateRange(DateTime from, DateTime to) async =>
      [];

  @override
  Future<SessionModel?> getById(String id) async => null;

  @override
  Future<void> save(SessionModel session) async {}

  @override
  Future<void> delete(String id) async {}
}

class FakeNotesRepository implements NotesRepository {
  final List<String> unlinkedProjectIds = [];

  @override
  Future<void> unlinkFromProject(String projectId) async {
    unlinkedProjectIds.add(projectId);
  }

  @override
  Future<List<NoteModel>> getAll() async => [];

  @override
  Future<NoteModel?> getById(String id) async => null;

  @override
  Future<void> save(NoteModel note) async {}

  @override
  Future<void> delete(String id) async {}
}

ProjectModel _project({
  required String id,
  String name = 'Project',
  DateTime? deletedAt,
  String? noteId,
}) {
  return ProjectModel(
    id: id,
    name: name,
    colorHex: '#FFFFFF',
    createdAt: DateTime(2026, 1, 1),
    deletedAt: deletedAt,
    noteId: noteId,
  );
}

void main() {
  late FakeLocalCache cache;
  late ProjectsLocalDatasource datasource;
  late FakeSessionsRepository sessionsRepository;
  late FakeNotesRepository notesRepository;
  late ProjectsRepositoryImpl repository;

  setUp(() async {
    cache = FakeLocalCache();
    datasource = ProjectsLocalDatasource(cache);
    sessionsRepository = FakeSessionsRepository();
    notesRepository = FakeNotesRepository();
    repository = ProjectsRepositoryImpl(datasource, sessionsRepository, notesRepository);

    await datasource.save(_project(id: 'p1'));
    await datasource.save(_project(id: 'p2'));
  });

  group('softDelete', () {
    test('sets deletedAt on the project and cascades to sessions', () async {
      await repository.softDelete('p1');

      final p1 = await datasource.getById('p1');
      final p2 = await datasource.getById('p2');

      expect(p1!.deletedAt, isNotNull);
      expect(p2!.deletedAt, isNull);
      expect(sessionsRepository.softDeletedProjectIds, ['p1']);
    });

    test('does not modify the note link and does not call notesRepository', () async {
      await datasource.save(_project(id: 'p1', noteId: 'n1'));

      await repository.softDelete('p1');

      final p1 = await datasource.getById('p1');
      expect(p1!.noteId, 'n1');
      expect(notesRepository.unlinkedProjectIds, isEmpty);
    });
  });

  group('restore', () {
    test('clears deletedAt on the project and restores its sessions', () async {
      await repository.softDelete('p1');
      await repository.softDelete('p2');

      await repository.restore('p1');

      final p1 = await datasource.getById('p1');
      final p2 = await datasource.getById('p2');

      expect(p1!.deletedAt, isNull);
      expect(p2!.deletedAt, isNotNull);
      expect(sessionsRepository.restoredProjectIds, ['p1']);
    });

    test('does not modify the note link and does not call notesRepository', () async {
      await datasource.save(_project(id: 'p1', noteId: 'n1'));
      await repository.softDelete('p1');

      await repository.restore('p1');

      final p1 = await datasource.getById('p1');
      expect(p1!.noteId, 'n1');
      expect(notesRepository.unlinkedProjectIds, isEmpty);
    });
  });

  group('purge', () {
    test('permanently removes the project and purges its sessions', () async {
      await repository.purge('p1');

      final all = await datasource.getAll();

      expect(all.any((p) => p.id == 'p1'), isFalse);
      expect(all.map((p) => p.id), ['p2']);
      expect(sessionsRepository.purgedProjectIds, ['p1']);
    });

    test('calls notesRepository.unlinkFromProject for the purged project but never deletes the note', () async {
      await datasource.save(_project(id: 'p1', noteId: 'n1'));

      await repository.purge('p1');

      expect(notesRepository.unlinkedProjectIds, ['p1']);
    });

  });

  group('unlinkNote', () {
    test('clears the noteId on the target project without affecting other fields', () async {
      await datasource.save(_project(id: 'p1', noteId: 'n1'));

      await repository.unlinkNote('p1');

      final p1 = await datasource.getById('p1');
      expect(p1!.noteId, isNull);
      expect(p1.id, 'p1');
      expect(p1.name, 'Project');
      expect(p1.colorHex, '#FFFFFF');
    });

    test('leaves other projects untouched', () async {
      await datasource.save(_project(id: 'p1', noteId: 'n1'));
      await datasource.save(_project(id: 'p2', noteId: 'n2'));

      await repository.unlinkNote('p1');

      final p2 = await datasource.getById('p2');
      expect(p2!.noteId, 'n2');
    });

    test('is a no-op when the project does not exist', () async {
      await repository.unlinkNote('does-not-exist');
      // Should not throw.
    });

    test('is callable independently of the purge cascade', () async {
      await datasource.save(_project(id: 'p1', noteId: 'n1'));

      await repository.unlinkNote('p1');

      final p1 = await datasource.getById('p1');
      expect(p1!.noteId, isNull);
      expect(notesRepository.unlinkedProjectIds, isEmpty);
      expect(sessionsRepository.purgedProjectIds, isEmpty);
    });
  });

  group('getDeleted', () {
    test('returns only projects where isDeleted is true', () async {
      await repository.softDelete('p1');

      final deleted = await repository.getDeleted();

      expect(deleted.map((p) => p.id), ['p1']);
    });
  });

  group('getAll', () {
    test('excludes soft-deleted projects by default', () async {
      await repository.softDelete('p1');

      final all = await repository.getAll();

      expect(all.any((p) => p.id == 'p1'), isFalse);
      expect(all.map((p) => p.id), ['p2']);
    });
  });
}
