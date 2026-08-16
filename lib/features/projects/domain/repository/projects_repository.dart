import '../../../../core/models/project_model.dart';

abstract class ProjectsRepository {
  Future<List<ProjectModel>> getAll();
  Future<ProjectModel?> getById(String id);
  Future<void> save(ProjectModel project);
  Future<void> delete(String id);
  Future<void> softDelete(String id);
  Future<void> restore(String id);
  Future<void> purge(String id);
  Future<List<ProjectModel>> getDeleted();

  /// Clears the project's linked note (sets `noteId` to null) without
  /// touching anything else about the project. Independently callable —
  /// not only reachable via the [purge] cascade — so it can back a future
  /// explicit "unlink note" action (e.g. from the project drawer).
  Future<void> unlinkNote(String projectId);
}
