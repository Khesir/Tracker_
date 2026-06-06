import 'dart:math' as math;
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

  String _fmtTotal(int seconds) {
    if (seconds == 0) return '0';
    final h = seconds / 3600;
    if (h >= 1) return h.toStringAsFixed(1);
    return '${seconds ~/ 60}';
  }

  String _fmtTotalUnit(int seconds) {
    if (seconds >= 3600) return 'h';
    return 'm';
  }

  String _fmtAvg(int seconds) {
    final avg = seconds / 7;
    if (avg >= 3600) return '${(avg / 3600).toStringAsFixed(1)}h';
    return '${(avg / 60).round()}m';
  }

  List<int> _rhythmCounts(AnalyticsSummary summary) {
    return summary.hourBuckets;
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
            builder: (context, summary) {
              final sorted = summary.projectTotals.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final projectTotal =
                  summary.projectTotals.values.fold(0, (a, b) => a + b);

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _ChartCard(
                        summary: summary,
                        isDark: isDark,
                        fmtTotal: _fmtTotal,
                        fmtTotalUnit: _fmtTotalUnit,
                        fmtAvg: _fmtAvg,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: _StatsStrip(
                        summary: summary,
                        isDark: isDark,
                        fmtHours: _fmtHours,
                        fmtAvg: _fmtAvg,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ProjectsCard(
                              sorted: sorted,
                              total: projectTotal,
                              nameMap: nameMap,
                              colorMap: colorMap,
                              isDark: isDark,
                              fmtHours: _fmtHours,
                              textMuted: textMuted,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _RhythmCard(
                              counts: _rhythmCounts(summary),
                              isDark: isDark,
                              textMuted: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
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

// ── Chart Card ────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final AnalyticsSummary summary;
  final bool isDark;
  final String Function(int) fmtTotal;
  final String Function(int) fmtTotalUnit;
  final String Function(int) fmtAvg;

  const _ChartCard({
    required this.summary,
    required this.isDark,
    required this.fmtTotal,
    required this.fmtTotalUnit,
    required this.fmtAvg,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLightStrong;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final accentInk = isDark ? AppStyling.accentInkDark : AppStyling.accentInkLight;
    final accentDim = isDark ? AppStyling.accentDimDark : AppStyling.accentDimLight;
    final textPrimary = isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;

    final deltaLabel = summary.streak <= 1 ? '↑ first week' : '↑ active';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: fmtTotal(summary.weekSeconds),
                      style: spaceMono(
                        size: 30,
                        weight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: fmtTotalUnit(summary.weekSeconds),
                      style: spaceMono(
                        size: 16,
                        weight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'tracked · daily avg ${fmtAvg(summary.weekSeconds)}',
                  style: spaceMono(size: 10, color: textMuted),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accentDim,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  deltaLabel,
                  style: spaceMono(
                    size: 11,
                    weight: FontWeight.w700,
                    color: accentInk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _WeekBarChart(
            dailySeconds: summary.dailySeconds,
            isDark: isDark,
          ),
        ],
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
    final accentInk = isDark ? AppStyling.accentInkDark : AppStyling.accentInkLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final textFaint = isDark ? AppStyling.textFaintDark : AppStyling.textFaintLight;
    final emptyBar = isDark ? AppStyling.surfaceDark : const Color(0xFFEEF0F2);
    final gridColor = isDark ? AppStyling.borderDark : const Color(0xFFEEF0F2);

    final days = dailySeconds.keys.toList()..sort();
    final maxSec = days.fold(0, (m, d) => dailySeconds[d]! > m ? dailySeconds[d]! : m);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    const labels = ['m', 't', 'w', 't', 'f', 's', 's'];

    const chartHeight = 100.0;
    const labelHeight = 28.0;
    const yAxisWidth = 28.0;

    return SizedBox(
      height: 158,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (maxSec > 0)
            SizedBox(
              width: yAxisWidth,
              height: chartHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(maxSec >= 3600 ? '${(maxSec / 3600).toStringAsFixed(0)}h' : '${maxSec ~/ 60}m',
                      style: spaceMono(size: 8, color: textFaint)),
                  Text(maxSec >= 7200 ? '${(maxSec / 7200).toStringAsFixed(0)}h' : '${maxSec ~/ 120}m',
                      style: spaceMono(size: 8, color: textFaint)),
                  Text('0', style: spaceMono(size: 8, color: textFaint)),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: chartHeight,
                  child: CustomPaint(
                    painter: _GridPainter(color: gridColor),
                  ),
                ),
                Column(
                  children: [
                    SizedBox(
                      height: chartHeight,
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
                                  Text(
                                    sec == 0
                                        ? '0'
                                        : (sec >= 3600
                                            ? '${(sec / 3600).toStringAsFixed(1)}h'
                                            : '${sec ~/ 60}m'),
                                    style: spaceMono(
                                      size: 9.5,
                                      weight: FontWeight.w700,
                                      color: textFaint,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOut,
                                    width: double.infinity,
                                    height: math.max(
                                        3.0, (chartHeight - 22) * fraction.clamp(0.0, 1.0)),
                                    decoration: BoxDecoration(
                                      gradient: fraction == 0
                                          ? null
                                          : (isToday
                                              ? LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [accent, accentInk],
                                                )
                                              : LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    const Color(0xFF54CD8C),
                                                    accent,
                                                  ],
                                                )),
                                      color: fraction == 0 ? emptyBar : null,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4)),
                                      boxShadow: isToday && fraction > 0
                                          ? [
                                              BoxShadow(
                                                color: accent.withValues(alpha: 0.65),
                                                offset: const Offset(0, 3),
                                                blurRadius: 10,
                                                spreadRadius: -3,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: labelHeight,
                      child: Row(
                        children: List.generate(days.length, (i) {
                          final day = days[i];
                          final isToday = day == todayDay;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Text(
                                labels[i % 7],
                                textAlign: TextAlign.center,
                                style: spaceMono(
                                  size: 9,
                                  weight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isToday ? accentInk : textMuted,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  const _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 4.0;
    const dashSpace = 4.0;

    for (final t in [0.0, 0.5, 1.0]) {
      final y = size.height * (1 - t);
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
        x += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}

// ── Stats Strip ───────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final AnalyticsSummary summary;
  final bool isDark;
  final String Function(int) fmtHours;
  final String Function(int) fmtAvg;

  const _StatsStrip({
    required this.summary,
    required this.isDark,
    required this.fmtHours,
    required this.fmtAvg,
  });

  @override
  Widget build(BuildContext context) {
    final avg = fmtAvg(summary.weekSeconds);
    final streakVal = summary.streak > 0 ? '${summary.streak}' : '0';
    final streakUnit = 'd';

    return Row(
      children: [
        _StatCard(
          label: 'today',
          value: _numPart(fmtHours(summary.todaySeconds)),
          unit: _unitPart(fmtHours(summary.todaySeconds)),
          isDark: isDark,
          isHot: true,
        ),
        const SizedBox(width: AppStyling.cardGap),
        _StatCard(
          label: 'week total',
          value: _numPart(fmtHours(summary.weekSeconds)),
          unit: _unitPart(fmtHours(summary.weekSeconds)),
          isDark: isDark,
          isHot: false,
        ),
        const SizedBox(width: AppStyling.cardGap),
        _StatCard(
          label: 'daily avg',
          value: _numPart(avg),
          unit: _unitPart(avg),
          isDark: isDark,
          isHot: false,
        ),
        const SizedBox(width: AppStyling.cardGap),
        _StatCard(
          label: 'streak',
          value: streakVal,
          unit: summary.streak > 0 ? streakUnit : '',
          isDark: isDark,
          isHot: false,
        ),
      ],
    );
  }

  static String _numPart(String s) {
    if (s == '—') return '—';
    return s.replaceAll(RegExp(r'[hmd]$'), '');
  }

  static String _unitPart(String s) {
    if (s.endsWith('h')) return 'h';
    if (s.endsWith('m')) return 'm';
    return '';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool isDark;
  final bool isHot;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.isDark,
    required this.isHot,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLightStrong;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final textPrimary = isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final accentInk = isDark ? AppStyling.accentInkDark : AppStyling.accentInkLight;
    final accentDim = isDark ? AppStyling.accentDimDark : AppStyling.accentDimLight;

    final bg = isHot ? accentDim : Colors.transparent;
    final valueColor = isHot ? accentInk : textPrimary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: spaceMono(
                      size: 21,
                      weight: FontWeight.w800,
                      color: valueColor,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: unit,
                      style: spaceMono(
                        size: 13,
                        weight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(label, style: spaceMono(size: 10, color: textMuted)),
          ],
        ),
      ),
    );
  }
}

// ── Projects Card ─────────────────────────────────────────────────────────────

class _ProjectsCard extends StatelessWidget {
  final List<MapEntry<String, int>> sorted;
  final int total;
  final Map<String, String> nameMap;
  final Map<String, String> colorMap;
  final bool isDark;
  final String Function(int) fmtHours;
  final Color textMuted;

  const _ProjectsCard({
    required this.sorted,
    required this.total,
    required this.nameMap,
    required this.colorMap,
    required this.isDark,
    required this.fmtHours,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLightStrong;
    final rows = sorted.take(3).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(19, 17, 19, 17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// projects this week',
            style: spaceMono(size: 11, color: textMuted),
          ),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            Text('no sessions', style: spaceMono(size: 10, color: textMuted))
          else
            ...List.generate(rows.length, (i) {
              final entry = rows[i];
              final fraction = total == 0 ? 0.0 : entry.value / total;
              final colorHex = colorMap[entry.key] ?? '#22C55E';
              Color projectColor;
              try {
                projectColor =
                    Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
              } catch (_) {
                projectColor = AppStyling.accentLight;
              }
              return Padding(
                padding: EdgeInsets.only(bottom: i < rows.length - 1 ? 12 : 0),
                child: _ProjectRankRow(
                  rank: i + 1,
                  name: nameMap[entry.key] ?? 'unknown',
                  projectColor: projectColor,
                  seconds: entry.value,
                  fraction: fraction,
                  isDark: isDark,
                  fmtHours: fmtHours,
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Project Rank Row ─────────────────────────────────────────────────────────

class _ProjectRankRow extends StatelessWidget {
  final int rank;
  final String name;
  final Color projectColor;
  final int seconds;
  final double fraction;
  final bool isDark;
  final String Function(int) fmtHours;

  const _ProjectRankRow({
    required this.rank,
    required this.name,
    required this.projectColor,
    required this.seconds,
    required this.fraction,
    required this.isDark,
    required this.fmtHours,
  });

  @override
  Widget build(BuildContext context) {
    final textFaint = isDark ? AppStyling.textFaintDark : AppStyling.textFaintLight;
    final borderColor = isDark ? AppStyling.borderDark : AppStyling.borderLightStrong;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('#$rank', style: spaceMono(size: 10, color: textFaint)),
            const SizedBox(width: 8),
            Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(color: projectColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: spaceMono(
                  size: 11,
                  weight: FontWeight.w700,
                  color: projectColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              fmtHours(seconds),
              style: spaceMono(
                  size: 11, weight: FontWeight.w700, color: projectColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: AppStyling.progressBarHeight,
            backgroundColor: borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(projectColor),
          ),
        ),
      ],
    );
  }
}

// ── Rhythm Card ───────────────────────────────────────────────────────────────

class _RhythmCard extends StatelessWidget {
  final List<int> counts;
  final bool isDark;
  final Color textMuted;

  const _RhythmCard({
    required this.counts,
    required this.isDark,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLightStrong;
    final accent = isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;
    final accentTint = isDark ? AppStyling.accentDimDark : AppStyling.accentTint2Light;

    const bucketLabels = ['6a', '9a', '12p', '3p', '6p', '9p'];
    const barHeight = 60.0;

    final maxCount = counts.fold(0, math.max);
    final peakIdx = counts.indexOf(maxCount);

    final peakLabel = bucketLabels[peakIdx];
    final afterIdx = peakIdx > 0 ? peakIdx - 1 : 0;
    final afterLabel = bucketLabels[afterIdx];

    return Container(
      padding: const EdgeInsets.fromLTRB(19, 17, 19, 17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// when you focus',
            style: spaceMono(size: 11, color: textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(counts.length, (i) {
              final isPeak = i == peakIdx;
              final fraction =
                  maxCount == 0 ? 0.0 : counts[i] / maxCount;
              final h = math.max(4.0, barHeight * fraction);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isPeak
                                ? [accent, accent.withValues(alpha: 0.6)]
                                : [accentTint, accentTint],
                          ),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(counts.length, (i) {
              return Expanded(
                child: Text(
                  bucketLabels[i],
                  textAlign: TextAlign.center,
                  style: spaceMono(size: 9, color: textMuted),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            'peak focus around $peakLabel · most sessions start after $afterLabel',
            style: spaceMono(size: 10, color: textMuted),
          ),
        ],
      ),
    );
  }
}
