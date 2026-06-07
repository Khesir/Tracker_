import '../../core/di/service_locator.dart';
import '../../core/cache/local_cache.dart';
import '../sessions/domain/repository/sessions_repository.dart';
import 'data/datasource/projects_local_datasource.dart';
import 'data/repository/projects_repository_impl.dart';
import 'domain/repository/projects_repository.dart';
import 'domain/controller/projects_controller.dart';
import '../timer/domain/controller/timer_controller.dart';

void setupProjectsDependencies() {
  locator.registerLazySingleton<ProjectsLocalDatasource>(
    () => ProjectsLocalDatasource(locator.get<LocalCache>()),
  );
  locator.registerLazySingleton<ProjectsRepository>(
    () => ProjectsRepositoryImpl(
      locator.get<ProjectsLocalDatasource>(),
      locator.get<SessionsRepository>(),
    ),
  );
  locator.registerLazySingleton<ProjectsController>(
    () => ProjectsController(
      locator.get<ProjectsRepository>(),
      locator.get<TimerController>(),
    ),
  );
}
