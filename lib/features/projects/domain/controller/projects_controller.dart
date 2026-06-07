import 'package:uuid/uuid.dart';
import '../../../../core/state/stream_state.dart';
import '../../../../core/models/project_model.dart';
import '../../domain/repository/projects_repository.dart';
import '../../presentation/state/projects_ui_state.dart';
import '../../../timer/domain/controller/timer_controller.dart';

class ProjectsController {
  final ProjectsRepository _repo;
  final TimerController _timer;
  final ProjectsUiState uiState;

  ProjectsController(this._repo, this._timer) : uiState = ProjectsUiState();

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

  Future<void> softDelete(String id) async {
    if (_timer.uiState.state.isRunning && _timer.uiState.state.projectId == id) {
      await _timer.stop();
    }
    await _repo.softDelete(id);
    await load();
  }

  Future<void> restore(String id) async {
    await _repo.restore(id);
    await load();
  }

  Future<void> purge(String id) async {
    await _repo.purge(id);
    await load();
  }

  Future<List<ProjectModel>> getDeleted() => _repo.getDeleted();

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }

  void dispose() => uiState.dispose();
}
