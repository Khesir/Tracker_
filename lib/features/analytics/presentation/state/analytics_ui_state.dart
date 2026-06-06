import '../../../../core/state/stream_state.dart';

class AnalyticsSummary {
  final int todaySeconds;
  final int weekSeconds;
  final int streak;
  final Map<String, int> projectTotals;
  final Map<DateTime, int> dailySeconds;

  const AnalyticsSummary({
    this.todaySeconds = 0,
    this.weekSeconds = 0,
    this.streak = 0,
    this.projectTotals = const {},
    this.dailySeconds = const {},
  });
}

class AnalyticsUiState extends StreamState<AsyncState<AnalyticsSummary>> {
  AnalyticsUiState() : super(const AsyncLoading());
}
