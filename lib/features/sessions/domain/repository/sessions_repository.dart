import '../../../../core/models/session_model.dart';

abstract class SessionsRepository {
  Future<List<SessionModel>> getAll();
  Future<List<SessionModel>> getByProject(String projectId);
  Future<List<SessionModel>> getByDateRange(DateTime from, DateTime to);
  Future<SessionModel?> getById(String id);
  Future<void> save(SessionModel session);
  Future<void> delete(String id);
  Future<void> softDeleteByProject(String projectId);
  Future<void> restoreByProject(String projectId);
  Future<void> purgeByProject(String projectId);
}
