import 'package:flutter_test/flutter_test.dart';
import 'package:time_track/core/cache/local_cache.dart';
import 'package:time_track/core/models/note_model.dart';
import 'package:time_track/features/notes/data/datasource/notes_local_datasource.dart';
import 'package:time_track/features/notes/data/repository/notes_repository_impl.dart';

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

NoteModel _note({
  required String id,
  String noteJson = '{"ops":[]}',
}) {
  return NoteModel(
    id: id,
    noteJson: noteJson,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late FakeLocalCache cache;
  late NotesLocalDatasource datasource;
  late NotesRepositoryImpl repository;

  setUp(() {
    cache = FakeLocalCache();
    datasource = NotesLocalDatasource(cache);
    repository = NotesRepositoryImpl(datasource);
  });

  group('save', () {
    test('persists a note that can be retrieved by id', () async {
      await repository.save(_note(id: 'n1'));

      final result = await repository.getById('n1');

      expect(result, isNotNull);
      expect(result!.id, 'n1');
    });

    test('overwrites an existing note with the same id', () async {
      await repository.save(_note(id: 'n1', noteJson: '{"ops":[{"insert":"a"}]}'));
      await repository.save(_note(id: 'n1', noteJson: '{"ops":[{"insert":"b"}]}'));

      final result = await repository.getById('n1');

      expect(result!.noteJson, '{"ops":[{"insert":"b"}]}');
    });
  });

  group('getAll', () {
    test('returns all saved notes', () async {
      await repository.save(_note(id: 'n1'));
      await repository.save(_note(id: 'n2'));

      final all = await repository.getAll();

      expect(all.map((n) => n.id).toSet(), {'n1', 'n2'});
    });

    test('returns an empty list when no notes exist', () async {
      final all = await repository.getAll();

      expect(all, isEmpty);
    });
  });

  group('getById', () {
    test('returns null when the note does not exist', () async {
      final result = await repository.getById('missing');

      expect(result, isNull);
    });
  });

  group('delete', () {
    test('removes the note from the repository', () async {
      await repository.save(_note(id: 'n1'));

      await repository.delete('n1');

      final result = await repository.getById('n1');
      final all = await repository.getAll();

      expect(result, isNull);
      expect(all, isEmpty);
    });
  });
}
