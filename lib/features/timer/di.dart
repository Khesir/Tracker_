import '../../core/di/service_locator.dart';
import '../../core/cache/local_cache.dart';
import 'data/datasource/timer_local_datasource.dart';
import 'data/repository/timer_repository_impl.dart';
import 'domain/repository/timer_repository.dart';
import 'domain/controller/timer_controller.dart';
import '../sessions/domain/repository/sessions_repository.dart';

void setupTimerDependencies() {
  locator.registerLazySingleton<TimerLocalDatasource>(
    () => TimerLocalDatasource(locator.get<LocalCache>()),
  );
  locator.registerLazySingleton<TimerRepository>(
    () => TimerRepositoryImpl(locator.get<TimerLocalDatasource>()),
  );
  locator.registerLazySingleton<TimerController>(
    () => TimerController(
      locator.get<TimerRepository>(),
      locator.get<SessionsRepository>(),
    ),
  );
}
