import '../../../../core/models/session_model.dart';

abstract class TimerRepository {
  Future<void> saveSession(SessionModel session);
  Future<SessionModel?> getActiveSession();
  Future<void> clearActiveSession();

  /// The project id of the most recently started session, persisted
  /// independently of the active session so note editing can resolve a
  /// project context while idle (no session currently running).
  Future<void> setLastProjectId(String? projectId);
  Future<String?> getLastProjectId();
}
