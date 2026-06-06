import '../../../../core/models/session_model.dart';

abstract class TimerRepository {
  Future<void> saveSession(SessionModel session);
  Future<SessionModel?> getActiveSession();
  Future<void> clearActiveSession();
}
