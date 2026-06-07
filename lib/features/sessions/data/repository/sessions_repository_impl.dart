import '../../../../core/models/session_model.dart';
import '../../domain/repository/sessions_repository.dart';
import '../datasource/sessions_local_datasource.dart';

class SessionsRepositoryImpl implements SessionsRepository {
  final SessionsLocalDatasource _datasource;
  SessionsRepositoryImpl(this._datasource);

  @override
  Future<List<SessionModel>> getAll() async {
    final all = await _datasource.getAll();
    return all.where((s) => !s.isDeleted).toList();
  }

  @override
  Future<List<SessionModel>> getByProject(String projectId) async {
    final all = await _datasource.getAll();
    return all.where((s) => s.projectId == projectId && !s.isDeleted).toList();
  }

  @override
  Future<List<SessionModel>> getByDateRange(DateTime from, DateTime to) async {
    final all = await _datasource.getAll();
    return all
        .where((s) =>
            !s.isDeleted &&
            s.startedAt.isAfter(from) &&
            s.startedAt.isBefore(to))
        .toList();
  }

  @override
  Future<SessionModel?> getById(String id) => _datasource.getById(id);

  @override
  Future<void> save(SessionModel session) => _datasource.save(session);

  @override
  Future<void> delete(String id) => _datasource.delete(id);

  @override
  Future<void> softDeleteByProject(String projectId) async {
    final sessions = await _datasource.getByProject(projectId);
    final now = DateTime.now();
    for (final session in sessions) {
      await _datasource.save(session.copyWith(deletedAt: now));
    }
  }

  @override
  Future<void> restoreByProject(String projectId) async {
    final sessions = await _datasource.getByProject(projectId);
    for (final session in sessions) {
      await _datasource.save(SessionModel(
        id: session.id,
        projectId: session.projectId,
        startedAt: session.startedAt,
        endedAt: session.endedAt,
        durationSeconds: session.durationSeconds,
        noteJson: session.noteJson,
        musicLog: session.musicLog,
        deletedAt: null,
      ));
    }
  }

  @override
  Future<void> purgeByProject(String projectId) async {
    final sessions = await _datasource.getByProject(projectId);
    await _datasource.deleteAll(sessions.map((s) => s.id));
  }
}
