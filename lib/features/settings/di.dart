import '../../core/di/service_locator.dart';
import '../../core/cache/local_cache.dart';
import 'data/datasource/settings_local_datasource.dart';
import 'data/repository/settings_repository_impl.dart';
import 'domain/repository/settings_repository.dart';
import 'domain/controller/settings_controller.dart';

void setupSettingsDependencies() {
  locator.registerLazySingleton<SettingsLocalDatasource>(
    () => SettingsLocalDatasource(locator.get<LocalCache>()),
  );
  locator.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(locator.get<SettingsLocalDatasource>()),
  );
  locator.registerLazySingleton<SettingsController>(
    () => SettingsController(locator.get<SettingsRepository>()),
  );
}
