import '../../core/di/service_locator.dart';
import '../sessions/data/datasource/sessions_local_datasource.dart';
import 'data/repository/analytics_repository_impl.dart';
import 'domain/repository/analytics_repository.dart';
import 'domain/controller/analytics_controller.dart';

void setupAnalyticsDependencies() {
  locator.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(locator.get<SessionsLocalDatasource>()),
  );
  locator.registerLazySingleton<AnalyticsController>(
    () => AnalyticsController(locator.get<AnalyticsRepository>()),
  );
}
