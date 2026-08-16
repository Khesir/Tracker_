import '../../../../core/cache/local_cache.dart';
import '../../../../core/models/note_model.dart';

class NotesLocalDatasource {
  static const _box = 'notes';

  final LocalCache _cache;
  NotesLocalDatasource(this._cache);

  Future<List<NoteModel>> getAll() async {
    final all = await _cache.getAll(_box);
    return all.map(NoteModel.fromJson).toList();
  }

  Future<NoteModel?> getById(String id) async {
    final data = await _cache.get(_box, id);
    if (data == null) return null;
    return NoteModel.fromJson(data);
  }

  Future<void> save(NoteModel note) =>
      _cache.put(_box, note.id, note.toJson());

  Future<void> delete(String id) => _cache.delete(_box, id);
}
