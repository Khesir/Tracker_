import '../../../../core/models/session_model.dart';

abstract class AnalyticsRepository {
  Future<List<SessionModel>> getSessionsForDay(DateTime day);
  Future<List<SessionModel>> getSessionsForWeek(DateTime weekStart);
  Future<List<SessionModel>> getAllSessions();
  Future<Map<String, int>> getProjectTotalsForPeriod(DateTime from, DateTime to);
  Future<int> getCurrentStreak();
}
