import 'package:flutter_test/flutter_test.dart';
import 'package:time_track/core/cache/local_cache.dart';
import 'package:time_track/core/models/project_model.dart';
import 'package:time_track/features/projects/data/datasource/projects_local_datasource.dart';
import 'package:time_track/features/projects/data/repository/projects_repository_impl.dart';
import 'package:time_track/features/sessions/domain/repository/sessions_repository.dart';
import 'package:time_track/core/models/session_model.dart';

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

ProjectModel _project({
  required String id,
  String name = 'Project',
  DateTime? deletedAt,
}) {
  return ProjectModel(
    id: id,
    name: name,
    colorHex: '#FFFFFF',
    createdAt: DateTime(2026, 1, 1),
    deletedAt: deletedAt,
  );
}

void main() {
  late FakeLocalCache cache;
  late ProjectsLocalDatasource datasource;
  late FakeSessionsRepository sessionsRepository;
  late ProjectsRepositoryImpl repository;

  setUp(() async {
    cache = FakeLocalCache();
    datasource = ProjectsLocalDatasource(cache);
    sessionsRepository = FakeSessionsRepository();
    repository = ProjectsRepositoryImpl(datasource, sessionsRepository);

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
  });

  group('purge', () {
    test('permanently removes the project and purges its sessions', () async {
      await repository.purge('p1');

      final all = await datasource.getAll();

      expect(all.any((p) => p.id == 'p1'), isFalse);
      expect(all.map((p) => p.id), ['p2']);
      expect(sessionsRepository.purgedProjectIds, ['p1']);
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
