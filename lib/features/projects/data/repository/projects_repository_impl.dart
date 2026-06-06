import '../../../../core/models/project_model.dart';
import '../../domain/repository/projects_repository.dart';
import '../datasource/projects_local_datasource.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  final ProjectsLocalDatasource _datasource;
  ProjectsRepositoryImpl(this._datasource);

  @override
  Future<List<ProjectModel>> getAll() => _datasource.getAll();

  @override
  Future<ProjectModel?> getById(String id) => _datasource.getById(id);

  @override
  Future<void> save(ProjectModel project) => _datasource.save(project);

  @override
  Future<void> delete(String id) => _datasource.delete(id);

  @override
  Future<void> archive(String id) async {
    final project = await _datasource.getById(id);
    if (project == null) return;
    await _datasource.save(project.copyWith(archivedAt: DateTime.now()));
  }
}
