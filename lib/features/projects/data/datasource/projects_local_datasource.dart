import '../../../../core/cache/local_cache.dart';
import '../../../../core/models/project_model.dart';

class ProjectsLocalDatasource {
  static const _box = 'projects';

  final LocalCache _cache;
  ProjectsLocalDatasource(this._cache);

  Future<List<ProjectModel>> getAll() async {
    final all = await _cache.getAll(_box);
    return all.map(ProjectModel.fromJson).toList();
  }

  Future<ProjectModel?> getById(String id) async {
    final data = await _cache.get(_box, id);
    if (data == null) return null;
    return ProjectModel.fromJson(data);
  }

  Future<void> save(ProjectModel project) =>
      _cache.put(_box, project.id, project.toJson());

  Future<void> delete(String id) => _cache.delete(_box, id);
}
