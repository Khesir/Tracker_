import '../../core/di/service_locator.dart';
import '../../core/cache/local_cache.dart';
import '../projects/domain/repository/projects_repository.dart';
import 'data/datasource/notes_local_datasource.dart';
import 'data/repository/notes_repository_impl.dart';
import 'domain/controller/notes_controller.dart';
import 'domain/repository/notes_repository.dart';

void setupNotesDependencies() {
  locator.registerLazySingleton<NotesLocalDatasource>(
    () => NotesLocalDatasource(locator.get<LocalCache>()),
  );
  locator.registerLazySingleton<NotesRepository>(
    () => NotesRepositoryImpl(locator.get<NotesLocalDatasource>()),
  );
  locator.registerLazySingleton<NotesController>(
    () => NotesController(
      locator.get<NotesRepository>(),
      locator.get<ProjectsRepository>(),
    ),
  );
}
