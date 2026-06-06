import '../../../../core/models/session_model.dart';
import '../../domain/repository/sessions_repository.dart';
import '../datasource/sessions_local_datasource.dart';

class SessionsRepositoryImpl implements SessionsRepository {
  final SessionsLocalDatasource _datasource;
  SessionsRepositoryImpl(this._datasource);

  @override
  Future<List<SessionModel>> getAll() => _datasource.getAll();

  @override
  Future<List<SessionModel>> getByProject(String projectId) async {
    final all = await _datasource.getAll();
    return all.where((s) => s.projectId == projectId).toList();
  }

  @override
  Future<List<SessionModel>> getByDateRange(DateTime from, DateTime to) async {
    final all = await _datasource.getAll();
    return all.where((s) => s.startedAt.isAfter(from) && s.startedAt.isBefore(to)).toList();
  }

  @override
  Future<SessionModel?> getById(String id) => _datasource.getById(id);

  @override
  Future<void> save(SessionModel session) => _datasource.save(session);

  @override
  Future<void> delete(String id) => _datasource.delete(id);
}
