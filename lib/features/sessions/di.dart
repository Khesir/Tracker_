import '../../core/di/service_locator.dart';
import '../../core/cache/local_cache.dart';
import 'data/datasource/sessions_local_datasource.dart';
import 'data/repository/sessions_repository_impl.dart';
import 'domain/repository/sessions_repository.dart';
import 'domain/controller/sessions_controller.dart';

void setupSessionsDependencies() {
  locator.registerLazySingleton<SessionsLocalDatasource>(
    () => SessionsLocalDatasource(locator.get<LocalCache>()),
  );
  locator.registerLazySingleton<SessionsRepository>(
    () => SessionsRepositoryImpl(locator.get<SessionsLocalDatasource>()),
  );
  locator.registerLazySingleton<SessionsController>(
    () => SessionsController(locator.get<SessionsRepository>()),
  );
}
