import '../../../../core/models/app_settings_model.dart';

abstract class SettingsRepository {
  Future<AppSettingsModel> get();
  Future<void> save(AppSettingsModel settings);
}
