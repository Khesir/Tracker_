import '../../../../core/cache/local_cache.dart';
import '../../../../core/models/app_settings_model.dart';

class SettingsLocalDatasource {
  static const _box = 'settings';
  static const _key = 'app';

  final LocalCache _cache;
  SettingsLocalDatasource(this._cache);

  Future<AppSettingsModel> get() async {
    final data = await _cache.get(_box, _key);
    if (data == null) return const AppSettingsModel();
    return AppSettingsModel.fromJson(data);
  }

  Future<void> save(AppSettingsModel settings) =>
      _cache.put(_box, _key, settings.toJson());
}
