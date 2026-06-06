import '../../../../core/models/session_model.dart';
import '../../domain/repository/analytics_repository.dart';
import '../../../sessions/data/datasource/sessions_local_datasource.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final SessionsLocalDatasource _datasource;
  AnalyticsRepositoryImpl(this._datasource);

  @override
  Future<List<SessionModel>> getSessionsForDay(DateTime day) async {
    final all = await _datasource.getAll();
    return all.where((s) {
      final d = s.startedAt;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  @override
  Future<List<SessionModel>> getSessionsForWeek(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final all = await _datasource.getAll();
    return all.where((s) =>
        s.startedAt.isAfter(weekStart) && s.startedAt.isBefore(weekEnd)).toList();
  }

  @override
  Future<Map<String, int>> getProjectTotalsForPeriod(DateTime from, DateTime to) async {
    final all = await _datasource.getAll();
    final inRange = all.where((s) =>
        s.startedAt.isAfter(from) && s.startedAt.isBefore(to));
    final totals = <String, int>{};
    for (final s in inRange) {
      totals[s.projectId] = (totals[s.projectId] ?? 0) + s.durationSeconds;
    }
    return totals;
  }

  @override
  Future<int> getCurrentStreak() async {
    final all = await _datasource.getAll();
    if (all.isEmpty) return 0;
    final byDay = <String>{};
    for (final s in all) {
      final d = s.startedAt;
      byDay.add('${d.year}-${d.month}-${d.day}');
    }
    int streak = 0;
    var day = DateTime.now();
    while (true) {
      final key = '${day.year}-${day.month}-${day.day}';
      if (!byDay.contains(key)) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
