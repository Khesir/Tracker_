import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/state/stream_builder_widget.dart';
import '../../../../core/state/stream_state.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/scoped_screen.dart';
import '../../../projects/domain/controller/projects_controller.dart';
import '../../domain/controller/analytics_controller.dart';
import '../state/analytics_ui_state.dart';

class AnalyticsScreen extends ScopedScreen {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ScopedScreenState<AnalyticsScreen> {
  late final AnalyticsController _ctrl;
  late final ProjectsController _projects;

  @override
  void registerServices() {
    _ctrl = locator.get<AnalyticsController>();
    _projects = locator.get<ProjectsController>();
  }

  @override
  void onReady() {
    _ctrl.load();
    _projects.load();
  }

  String _fmtHours(int seconds) {
    if (seconds == 0) return '0h';
    final h = seconds / 3600;
    if (h >= 1) return '${h.toStringAsFixed(1)}h';
    final m = seconds ~/ 60;
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppStyling.bgDark : AppStyling.bgLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;

    return Scaffold(
      backgroundColor: bg,
      body: StreamStateBuilder<AsyncState<List<ProjectModel>>>(
        state: _projects.uiState,
        builder: (context, projectsState) {
          final projects = projectsState is AsyncData<List<ProjectModel>>
              ? projectsState.data
              : <ProjectModel>[];
          final nameMap = {for (final p in projects) p.id: p.name};
          final colorMap = {for (final p in projects) p.id: p.colorHex};

          return AsyncStreamBuilder<AnalyticsSummary>(
            state: _ctrl.uiState,
            builder: (context, summary) => CustomScrollView(
              slivers: [
                // weekly bar chart
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '// this_week',
                          style: spaceMono(size: 10, color: textMuted),
                        ),
                        const SizedBox(height: 16),
                        _WeekBarChart(
                          dailySeconds: summary.dailySeconds,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),

                // summary stat row
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        _StatPill(
                          label: 'week total',
                          value: _fmtHours(summary.weekSeconds),
                          isDark: isDark,
                          highlighted: summary.weekSeconds > 0,
                        ),
                        const SizedBox(width: AppStyling.cardGap),
                        _StatPill(
                          label: 'today',
                          value: _fmtHours(summary.todaySeconds),
                          isDark: isDark,
                          highlighted: summary.todaySeconds > 0,
                        ),
                        const SizedBox(width: AppStyling.cardGap),
                        _StatPill(
                          label: 'streak',
                          value: summary.streak > 0
                              ? '${summary.streak}d'
                              : '—',
                          isDark: isDark,
                          highlighted: summary.streak > 1,
                        ),
                      ],
                    ),
                  ),
                ),

                // project breakdown header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Text(
                      '// projects_this_week',
                      style: spaceMono(size: 10, color: textMuted),
                    ),
                  ),
                ),

                // ranked project list
                if (summary.projectTotals.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Text(
                        'no_sessions_this_week',
                        style: spaceMono(size: 11, color: textMuted),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: () {
                        final sorted = summary.projectTotals.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));
                        return sorted.length;
                      }(),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppStyling.cardGap),
                      itemBuilder: (context, i) {
                        final sorted = summary.projectTotals.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));
                        final entry = sorted[i];
                        final total = summary.projectTotals.values
                            .fold(0, (a, b) => a + b);
                        final fraction =
                            total == 0 ? 0.0 : entry.value / total;
                        return _ProjectRankRow(
                          rank: i + 1,
                          name: nameMap[entry.key] ?? 'unknown',
                          colorHex: colorMap[entry.key] ?? '#22C55E',
                          seconds: entry.value,
                          fraction: fraction,
                          isDark: isDark,
                          formatHours: _fmtHours,
                        );
                      },
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
            loadingBuilder: (context) => const Center(
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            errorBuilder: (context, msg) => Center(
              child: Text(
                'error: $msg',
                style: spaceMono(
                    size: 11,
                    color: isDark
                        ? AppStyling.textMutedDark
                        : AppStyling.textMutedLight),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Bar Chart ─────────────────────────────────────────────────────────────────

class _WeekBarChart extends StatelessWidget {
  final Map<DateTime, int> dailySeconds;
  final bool isDark;

  const _WeekBarChart({required this.dailySeconds, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final barBg = isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight;

    final days = dailySeconds.keys.toList()..sort();
    final maxSec = days.fold(0, (m, d) => dailySeconds[d]! > m ? dailySeconds[d]! : m);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    const labels = ['m', 't', 'w', 't', 'f', 's', 's'];

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(days.length, (i) {
          final day = days[i];
          final sec = dailySeconds[day] ?? 0;
          final isToday = day == todayDay;
          final fraction = maxSec == 0 ? 0.0 : sec / maxSec;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    width: double.infinity,
                    height: 80 * fraction.clamp(0.0, 1.0) + (fraction > 0 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: isToday
                          ? accent
                          : (fraction > 0
                              ? accent.withValues(alpha: 0.4)
                              : barBg),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ),
                  // day label
                  const SizedBox(height: 6),
                  Text(
                    labels[i % 7],
                    style: spaceMono(
                      size: 9,
                      color: isToday ? accent : textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Stat Pill ─────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool highlighted;

  const _StatPill({
    required this.label,
    required this.value,
    required this.isDark,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final accent = isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;
    final textPrimary =
        isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: highlighted
              ? (isDark ? AppStyling.accentDimDark : AppStyling.accentDimLight)
              : surface,
          borderRadius: BorderRadius.circular(AppStyling.statBoxRadius),
          border: Border.all(
              color: highlighted ? accent.withValues(alpha: 0.3) : border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: spaceMono(
                size: 18,
                weight: FontWeight.w700,
                color: highlighted ? accent : textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: dmSans(size: 10, color: textMuted)),
          ],
        ),
      ),
    );
  }
}

// ── Project Rank Row ─────────────────────────────────────────────────────────

class _ProjectRankRow extends StatelessWidget {
  final int rank;
  final String name;
  final String colorHex;
  final int seconds;
  final double fraction;
  final bool isDark;
  final String Function(int) formatHours;

  const _ProjectRankRow({
    required this.rank,
    required this.name,
    required this.colorHex,
    required this.seconds,
    required this.fraction,
    required this.isDark,
    required this.formatHours,
  });

  Color get _projectColor {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppStyling.accentLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textPrimary =
        isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final color = _projectColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppStyling.cardPaddingH,
        AppStyling.cardPaddingV,
        AppStyling.cardPaddingH,
        AppStyling.cardPaddingV,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppStyling.cardRadius),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#$rank',
                style: spaceMono(size: 10, color: textMuted),
              ),
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: dmSans(
                      size: AppStyling.bodySize,
                      weight: FontWeight.w600,
                      color: textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatHours(seconds),
                style: spaceMono(
                    size: 13, weight: FontWeight.w700, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: AppStyling.progressBarHeight,
              backgroundColor: border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
