import '../../../../core/state/stream_state.dart';

class AnalyticsSummary {
  final int todaySeconds;
  final int weekSeconds;
  final int streak;
  final Map<String, int> projectTotals;
  final Map<DateTime, int> dailySeconds;
  final List<int> hourBuckets; // 6 buckets: [6-9, 9-12, 12-15, 15-18, 18-21, 21-24]

  const AnalyticsSummary({
    this.todaySeconds = 0,
    this.weekSeconds = 0,
    this.streak = 0,
    this.projectTotals = const {},
    this.dailySeconds = const {},
    this.hourBuckets = const [0, 0, 0, 0, 0, 0],
  });
}

class AnalyticsUiState extends StreamState<AsyncState<AnalyticsSummary>> {
  AnalyticsUiState() : super(const AsyncLoading());
}
