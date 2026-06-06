import 'package:uuid/uuid.dart';
import '../../../../core/state/stream_state.dart';
import '../../../../core/models/project_model.dart';
import '../../domain/repository/projects_repository.dart';
import '../../presentation/state/projects_ui_state.dart';

class ProjectsController {
  final ProjectsRepository _repo;
  final ProjectsUiState uiState;

  ProjectsController(this._repo) : uiState = ProjectsUiState();

  Future<void> load() => uiState.execute(() => _repo.getAll());

  Future<void> create({required String name, required String colorHex, int? targetMinutes}) async {
    final project = ProjectModel(
      id: const Uuid().v4(),
      name: name,
      colorHex: colorHex,
      targetMinutes: targetMinutes,
      createdAt: DateTime.now(),
    );
    await _repo.save(project);
    await load();
  }

  Future<void> update(ProjectModel project) async {
    await _repo.save(project);
    await load();
  }

  Future<void> archive(String id) async {
    await _repo.archive(id);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }

  void dispose() => uiState.dispose();
}
