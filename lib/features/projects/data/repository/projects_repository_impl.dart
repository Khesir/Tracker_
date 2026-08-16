import '../../../../core/models/project_model.dart';
import '../../../notes/domain/repository/notes_repository.dart';
import '../../../sessions/domain/repository/sessions_repository.dart';
import '../../domain/repository/projects_repository.dart';
import '../datasource/projects_local_datasource.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  final ProjectsLocalDatasource _datasource;
  final SessionsRepository _sessionsRepository;
  final NotesRepository _notesRepository;
  ProjectsRepositoryImpl(
    this._datasource,
    this._sessionsRepository,
    this._notesRepository,
  );

  @override
  Future<List<ProjectModel>> getAll() async {
    final all = await _datasource.getAll();
    return all.where((p) => !p.isDeleted).toList();
  }

  @override
  Future<List<ProjectModel>> getDeleted() async {
    final all = await _datasource.getAll();
    return all.where((p) => p.isDeleted).toList();
  }

  @override
  Future<ProjectModel?> getById(String id) => _datasource.getById(id);

  @override
  Future<void> save(ProjectModel project) => _datasource.save(project);

  @override
  Future<void> delete(String id) => _datasource.delete(id);

  @override
  Future<void> softDelete(String id) async {
    final project = await _datasource.getById(id);
    if (project == null) return;
    await _datasource.save(project.copyWith(deletedAt: DateTime.now()));
    await _sessionsRepository.softDeleteByProject(id);
  }

  @override
  Future<void> restore(String id) async {
    final project = await _datasource.getById(id);
    if (project == null) return;
    await _datasource.save(ProjectModel(
      id: project.id,
      name: project.name,
      colorHex: project.colorHex,
      targetMinutes: project.targetMinutes,
      createdAt: project.createdAt,
      deletedAt: null,
      noteId: project.noteId,
    ));
    await _sessionsRepository.restoreByProject(id);
  }

  @override
  Future<void> purge(String id) async {
    await unlinkNote(id);
    await _datasource.delete(id);
    await _sessionsRepository.purgeByProject(id);
    await _notesRepository.unlinkFromProject(id);
  }

  @override
  Future<void> unlinkNote(String projectId) async {
    final project = await _datasource.getById(projectId);
    if (project == null) return;
    await _datasource.save(ProjectModel(
      id: project.id,
      name: project.name,
      colorHex: project.colorHex,
      targetMinutes: project.targetMinutes,
      createdAt: project.createdAt,
      deletedAt: project.deletedAt,
      noteId: null,
    ));
  }
}
