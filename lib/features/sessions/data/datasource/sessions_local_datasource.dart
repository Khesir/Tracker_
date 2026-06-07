import '../../../../core/cache/local_cache.dart';
import '../../../../core/models/session_model.dart';

class SessionsLocalDatasource {
  static const _box = 'sessions';

  final LocalCache _cache;
  SessionsLocalDatasource(this._cache);

  Future<List<SessionModel>> getAll() async {
    final all = await _cache.getAll(_box);
    return all.map(SessionModel.fromJson).toList();
  }

  Future<SessionModel?> getById(String id) async {
    final data = await _cache.get(_box, id);
    if (data == null) return null;
    return SessionModel.fromJson(data);
  }

  Future<void> save(SessionModel session) =>
      _cache.put(_box, session.id, session.toJson());

  Future<void> delete(String id) => _cache.delete(_box, id);

  Future<List<SessionModel>> getByProject(String projectId) async {
    final all = await getAll();
    return all.where((s) => s.projectId == projectId).toList();
  }

  Future<void> deleteAll(Iterable<String> ids) async {
    for (final id in ids) {
      await _cache.delete(_box, id);
    }
  }
}
