import 'package:flutter_test/flutter_test.dart';
import 'package:time_track/core/cache/local_cache.dart';
import 'package:time_track/core/models/session_model.dart';
import 'package:time_track/features/sessions/data/datasource/sessions_local_datasource.dart';
import 'package:time_track/features/sessions/data/repository/sessions_repository_impl.dart';

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

SessionModel _session({
  required String id,
  required String projectId,
  DateTime? startedAt,
  DateTime? deletedAt,
}) {
  return SessionModel(
    id: id,
    projectId: projectId,
    startedAt: startedAt ?? DateTime(2026, 1, 1),
    endedAt: DateTime(2026, 1, 1, 1),
    durationSeconds: 3600,
    noteJson: '',
    musicLog: const [],
    deletedAt: deletedAt,
  );
}

void main() {
  late FakeLocalCache cache;
  late SessionsLocalDatasource datasource;
  late SessionsRepositoryImpl repository;

  setUp(() async {
    cache = FakeLocalCache();
    datasource = SessionsLocalDatasource(cache);
    repository = SessionsRepositoryImpl(datasource);

    await datasource.save(_session(id: 's1', projectId: 'p1'));
    await datasource.save(_session(id: 's2', projectId: 'p1'));
    await datasource.save(_session(id: 's3', projectId: 'p2'));
  });

  group('softDeleteByProject', () {
    test('sets deletedAt on every session of that project only', () async {
      await repository.softDeleteByProject('p1');

      final s1 = await datasource.getById('s1');
      final s2 = await datasource.getById('s2');
      final s3 = await datasource.getById('s3');

      expect(s1!.deletedAt, isNotNull);
      expect(s2!.deletedAt, isNotNull);
      expect(s3!.deletedAt, isNull);
    });
  });

  group('restoreByProject', () {
    test('clears deletedAt on every session of that project only', () async {
      await repository.softDeleteByProject('p1');
      await repository.softDeleteByProject('p2');

      await repository.restoreByProject('p1');

      final s1 = await datasource.getById('s1');
      final s2 = await datasource.getById('s2');
      final s3 = await datasource.getById('s3');

      expect(s1!.deletedAt, isNull);
      expect(s2!.deletedAt, isNull);
      expect(s3!.deletedAt, isNotNull);
    });
  });

  group('purgeByProject', () {
    test('permanently removes every session of that project', () async {
      await repository.purgeByProject('p1');

      final all = await datasource.getAll();
      expect(all.map((s) => s.id), containsAll(['s3']));
      expect(all.any((s) => s.projectId == 'p1'), isFalse);
      expect(all.length, 1);
    });
  });

  group('default queries exclude soft-deleted sessions', () {
    test('getAll excludes soft-deleted sessions', () async {
      await repository.softDeleteByProject('p1');

      final all = await repository.getAll();

      expect(all.any((s) => s.projectId == 'p1'), isFalse);
      expect(all.map((s) => s.id), ['s3']);
    });

    test('getByProject excludes soft-deleted sessions', () async {
      await repository.softDeleteByProject('p1');

      final result = await repository.getByProject('p1');

      expect(result, isEmpty);
    });

    test('getByDateRange excludes soft-deleted sessions', () async {
      await repository.softDeleteByProject('p1');

      final result = await repository.getByDateRange(
        DateTime(2025, 12, 31),
        DateTime(2026, 1, 2),
      );

      expect(result.any((s) => s.projectId == 'p1'), isFalse);
      expect(result.map((s) => s.id), ['s3']);
    });
  });
}
