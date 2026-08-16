import '../../../../core/cache/local_cache.dart';
import '../../../../core/models/session_model.dart';

class TimerLocalDatasource {
  static const _box = 'active_session';
  static const _key = 'current';
  static const _lastProjectBox = 'timer_last_project';
  static const _lastProjectKey = 'current';

  final LocalCache _cache;
  TimerLocalDatasource(this._cache);

  Future<void> saveActiveSession(SessionModel session) =>
      _cache.put(_box, _key, session.toJson());

  Future<SessionModel?> getActiveSession() async {
    final data = await _cache.get(_box, _key);
    if (data == null) return null;
    return SessionModel.fromJson(data);
  }

  Future<void> clearActiveSession() => _cache.delete(_box, _key);

  Future<void> setLastProjectId(String? projectId) async {
    if (projectId == null) {
      await _cache.delete(_lastProjectBox, _lastProjectKey);
      return;
    }
    await _cache.put(_lastProjectBox, _lastProjectKey, {'projectId': projectId});
  }

  Future<String?> getLastProjectId() async {
    final data = await _cache.get(_lastProjectBox, _lastProjectKey);
    if (data == null) return null;
    return data['projectId'] as String?;
  }
}
