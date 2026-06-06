import '../../../../core/models/project_model.dart';

abstract class ProjectsRepository {
  Future<List<ProjectModel>> getAll();
  Future<ProjectModel?> getById(String id);
  Future<void> save(ProjectModel project);
  Future<void> delete(String id);
  Future<void> archive(String id);
}
