import '../../../../core/state/stream_state.dart';
import '../../domain/repository/analytics_repository.dart';
import '../../presentation/state/analytics_ui_state.dart';

class AnalyticsController {
  final AnalyticsRepository _repo;
  final AnalyticsUiState uiState;

  AnalyticsController(this._repo) : uiState = AnalyticsUiState();

  Future<void> load() async {
    await uiState.execute(() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Start of current week (Monday)
      final weekStart = today.subtract(Duration(days: today.weekday - 1));

      final todaySessions = await _repo.getSessionsForDay(now);
      final weekSessions = await _repo.getSessionsForWeek(weekStart);
      final allSessions = await _repo.getAllSessions();
      final streak = await _repo.getCurrentStreak();
      final projectTotals = await _repo.getProjectTotalsForPeriod(
        weekStart,
        now.add(const Duration(days: 1)),
      );

      // Build last-7-days daily breakdown
      final daily = <DateTime, int>{};
      for (var i = 6; i >= 0; i--) {
        final day = today.subtract(Duration(days: i));
        daily[day] = 0;
      }
      for (final s in weekSessions) {
        final d = DateTime(
            s.startedAt.year, s.startedAt.month, s.startedAt.day);
        if (daily.containsKey(d)) {
          daily[d] = daily[d]! + s.durationSeconds;
        }
      }

      final buckets = List<int>.filled(6, 0);
      for (final s in allSessions) {
        final h = s.startedAt.hour;
        if (h >= 6 && h < 9) buckets[0]++;
        else if (h >= 9 && h < 12) buckets[1]++;
        else if (h >= 12 && h < 15) buckets[2]++;
        else if (h >= 15 && h < 18) buckets[3]++;
        else if (h >= 18 && h < 21) buckets[4]++;
        else if (h >= 21) buckets[5]++;
      }

      return AnalyticsSummary(
        todaySeconds: todaySessions.fold(0, (sum, s) => sum + s.durationSeconds),
        weekSeconds: weekSessions.fold(0, (sum, s) => sum + s.durationSeconds),
        streak: streak,
        projectTotals: projectTotals,
        dailySeconds: daily,
        hourBuckets: buckets,
      );
    });
  }

  void dispose() => uiState.dispose();
}
