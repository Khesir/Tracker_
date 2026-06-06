import 'package:flutter/material.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';

class SessionHeatmapWidget extends StatelessWidget {
  final Map<DateTime, int> dailySeconds;
  final String selectedView;
  final List<String> availableYears;
  final ValueChanged<String> onViewChanged;
  final String selectedProject;
  final List<({String id, String name, String colorHex})> projects;
  final ValueChanged<String> onProjectChanged;

  const SessionHeatmapWidget({
    super.key,
    required this.dailySeconds,
    required this.selectedView,
    required this.availableYears,
    required this.onViewChanged,
    required this.selectedProject,
    required this.projects,
    required this.onProjectChanged,
  });

  static const List<Color> _lightRamp = [
    Color(0xFFEEF0F2),
    Color(0xFFCDEFDD),
    Color(0xFF86DCAB),
    Color(0xFF3CBD7C),
    Color(0xFF0F8F4D),
  ];

  static const List<Color> _darkRamp = [
    Color(0xFF0F2340),
    Color(0xFF04342C),
    Color(0xFF0A6644),
    Color(0xFF0F8F4D),
    Color(0xFF15C488),
  ];

  ({DateTime start, DateTime end, int columns}) _computeRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (selectedView == '1y') {
      final daysUntilSat = (6 - today.weekday % 7) % 7;
      final end = today.add(Duration(days: daysUntilSat));
      final start = end.subtract(const Duration(days: 363));
      return (start: start, end: end, columns: 52);
    } else {
      final year = int.parse(selectedView);
      final start = DateTime(year, 1, 1);
      final end = year == now.year ? today : DateTime(year, 12, 31);
      final cols = ((end.difference(start).inDays + 1) / 7).ceil();
      return (start: start, end: end, columns: cols);
    }
  }

  Map<DateTime, int> _filteredData() {
    final range = _computeRange();
    final result = <DateTime, int>{};
    for (final entry in dailySeconds.entries) {
      if (!entry.key.isBefore(range.start) && !entry.key.isAfter(range.end)) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  int _computeCurrentStreak(Map<DateTime, int> data) {
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    var streak = 0;
    while (true) {
      final secs = data[day] ?? 0;
      if (secs <= 0) break;
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _computeLongestStreak(Map<DateTime, int> data) {
    if (data.isEmpty) return 0;
    final days = data.keys.where((d) => (data[d] ?? 0) > 0).toList()..sort();
    var longest = 0;
    var current = 0;
    DateTime? prev;
    for (final d in days) {
      if (prev == null || d.difference(prev).inDays == 1) {
        current++;
      } else {
        current = 1;
      }
      if (current > longest) longest = current;
      prev = d;
    }
    return longest;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final textPrimary = isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final borderColor = isDark ? AppStyling.borderDark : AppStyling.borderLightStrong;
    final surface = isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight;
    final ramp = isDark ? _darkRamp : _lightRamp;

    final viewOptions = ['1y', ...availableYears];
    final filtered = _filteredData();
    final range = _computeRange();

    final totalSeconds = filtered.values.fold(0, (a, b) => a + b);
    final currentStreak = _computeCurrentStreak(filtered);
    final longestStreak = _computeLongestStreak(filtered);
    final bestDaySeconds = filtered.values.isEmpty ? 0 : filtered.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
          child: Row(
            children: [
              Text('// activity', style: spaceMono(size: 10, color: textMuted)),
              const SizedBox(width: 12),
              _SegmentedButtons(
                options: viewOptions,
                selected: selectedView,
                isDark: isDark,
                textMuted: textMuted,
                textPrimary: textPrimary,
                onChanged: onViewChanged,
              ),
              const Spacer(),
              _ProjectChips(
                projects: projects,
                selectedProject: selectedProject,
                isDark: isDark,
                textMuted: textMuted,
                onChanged: onProjectChanged,
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surface,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeatmapGrid(
                range: range,
                dailySeconds: filtered,
                ramp: ramp,
                textMuted: textMuted,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('less', style: spaceMono(size: 9.5, color: textMuted)),
                  const SizedBox(width: 4),
                  ...List.generate(5, (i) => Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: ramp[i],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                  const SizedBox(width: 4),
                  Text('more', style: spaceMono(size: 9.5, color: textMuted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'total tracked',
                seconds: totalSeconds,
                isDark: isDark,
                textMuted: textMuted,
                textPrimary: textPrimary,
                isHighlighted: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StreakCard(
                label: 'current streak',
                value: currentStreak,
                unit: 'd',
                isDark: isDark,
                textMuted: textMuted,
                textPrimary: textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StreakCard(
                label: 'longest streak',
                value: longestStreak,
                unit: 'd',
                isDark: isDark,
                textMuted: textMuted,
                textPrimary: textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'best day',
                seconds: bestDaySeconds,
                isDark: isDark,
                textMuted: textMuted,
                textPrimary: textPrimary,
                isHighlighted: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final ({DateTime start, DateTime end, int columns}) range;
  final Map<DateTime, int> dailySeconds;
  final List<Color> ramp;
  final Color textMuted;

  const _HeatmapGrid({
    required this.range,
    required this.dailySeconds,
    required this.ramp,
    required this.textMuted,
  });

  int _level(int seconds) {
    final h = seconds / 3600.0;
    if (h <= 0) return 0;
    if (h < 0.5) return 1;
    if (h < 1.5) return 2;
    if (h < 3.0) return 3;
    return 4;
  }

  String _tooltipText(DateTime date, int seconds) {
    const weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final timeStr = h > 0 ? '${h}h ${m}m' : '${m}m';
    final wd = weekdays[date.weekday - 1];
    final mo = months[date.month - 1];
    final d = date.day.toString().padLeft(2, '0');
    return '$timeStr · $wd, $d $mo';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final startDow = range.start.weekday % 7;
    final cols = range.columns;

    final monthLabels = <int, String>{};
    const monthAbbr = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    for (var col = 0; col < cols; col++) {
      for (var row = 0; row < 7; row++) {
        final dayOffset = col * 7 + row - startDow;
        if (dayOffset < 0) continue;
        final date = range.start.add(Duration(days: dayOffset));
        if (date.isAfter(range.end)) break;
        if (date.day == 1 || (col == 0 && row == 0)) {
          if (!monthLabels.containsKey(col)) {
            monthLabels[col] = monthAbbr[date.month - 1];
          }
        }
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Column(
            children: [
              const SizedBox(height: 16),
              ...List.generate(7, (row) {
                final label = row == 0 ? 'mon' : row == 2 ? 'wed' : row == 4 ? 'fri' : null;
                return SizedBox(
                  height: 12,
                  child: label != null
                      ? Text(label, style: spaceMono(size: 8.5, color: textMuted))
                      : const SizedBox.shrink(),
                );
              }),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 16,
                child: Row(
                  children: List.generate(cols, (col) {
                    final label = monthLabels[col];
                    return SizedBox(
                      width: 12,
                      child: label != null
                          ? Text(label, style: spaceMono(size: 9, color: textMuted), overflow: TextOverflow.visible)
                          : const SizedBox.shrink(),
                    );
                  }),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(cols, (col) {
                  return Column(
                    children: List.generate(7, (row) {
                      final dayOffset = col * 7 + row - startDow;
                      if (dayOffset < 0) {
                        return const SizedBox(width: 12, height: 12);
                      }
                      final date = range.start.add(Duration(days: dayOffset));
                      if (date.isAfter(range.end)) {
                        return const SizedBox(width: 12, height: 12);
                      }
                      final isFuture = date.isAfter(today);
                      if (isFuture) {
                        return const SizedBox(width: 12, height: 12);
                      }
                      final secs = dailySeconds[date] ?? 0;
                      final level = _level(secs);
                      final cell = Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: ramp[level],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                      if (secs > 0) {
                        return Tooltip(
                          message: _tooltipText(date, secs),
                          child: cell,
                        );
                      }
                      return cell;
                    }),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentedButtons extends StatelessWidget {
  final List<String> options;
  final String selected;
  final bool isDark;
  final Color textMuted;
  final Color textPrimary;
  final ValueChanged<String> onChanged;

  const _SegmentedButtons({
    required this.options,
    required this.selected,
    required this.isDark,
    required this.textMuted,
    required this.textPrimary,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pillBg = isDark ? AppStyling.surfaceRaisedDark : const Color(0xFFF3F4F6);
    final activeBg = isDark ? AppStyling.surfaceDark : Colors.white;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isActive = opt == selected;
          return GestureDetector(
            onTap: () => onChanged(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: isActive
                    ? [BoxShadow(color: Colors.black.withValues(alpha: .1), offset: const Offset(0, 1), blurRadius: 3)]
                    : null,
              ),
              child: Text(
                opt,
                style: spaceMono(
                  size: 10,
                  weight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? textPrimary : textMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProjectChips extends StatelessWidget {
  final List<({String id, String name, String colorHex})> projects;
  final String selectedProject;
  final bool isDark;
  final Color textMuted;
  final ValueChanged<String> onChanged;

  const _ProjectChips({
    required this.projects,
    required this.selectedProject,
    required this.isDark,
    required this.textMuted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final borderColor = isDark ? AppStyling.borderDark : AppStyling.borderLightStrong;

    final allChips = <({String id, String name, String? colorHex})>[
      (id: 'all', name: 'all', colorHex: null),
      ...projects.map((p) => (id: p.id, name: p.name, colorHex: p.colorHex)),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: allChips.map((chip) {
        final isActive = chip.id == selectedProject;
        Color? dotColor;
        if (chip.colorHex != null) {
          try {
            dotColor = Color(int.parse(chip.colorHex!.replaceFirst('#', '0xFF')));
          } catch (_) {
            dotColor = AppStyling.accentLight;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(left: 5),
          child: GestureDetector(
            onTap: () => onChanged(chip.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? ink : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: isActive ? null : Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dotColor != null) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    chip.name,
                    style: spaceMono(
                      size: 10,
                      color: isActive ? (isDark ? AppStyling.bgDark : Colors.white) : textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int seconds;
  final bool isDark;
  final Color textMuted;
  final Color textPrimary;
  final bool isHighlighted;

  const _StatCard({
    required this.label,
    required this.seconds,
    required this.isDark,
    required this.textMuted,
    required this.textPrimary,
    required this.isHighlighted,
  });

  ({String value, String unit}) _split() {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h == 0) return (value: '$m', unit: 'm');
    return (value: '$h', unit: 'h');
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppStyling.borderDark : AppStyling.borderLightStrong;
    final bg = isHighlighted
        ? (isDark ? AppStyling.accentDimDark : AppStyling.accentDimLight)
        : Colors.transparent;
    final valueColor = isHighlighted
        ? (isDark ? AppStyling.accentInkDark : AppStyling.accentInkLight)
        : textPrimary;

    final split = _split();

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: isHighlighted ? Colors.transparent : borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: spaceMono(size: 21, weight: FontWeight.w800, color: valueColor),
              children: [
                TextSpan(text: split.value),
                TextSpan(
                  text: split.unit,
                  style: spaceMono(size: 12, weight: FontWeight.w500, color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: spaceMono(size: 10, color: textMuted)),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final bool isDark;
  final Color textMuted;
  final Color textPrimary;

  const _StreakCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.isDark,
    required this.textMuted,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppStyling.borderDark : AppStyling.borderLightStrong;

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: spaceMono(size: 21, weight: FontWeight.w800, color: textPrimary),
              children: [
                TextSpan(text: '$value'),
                TextSpan(
                  text: unit,
                  style: spaceMono(size: 12, weight: FontWeight.w500, color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: spaceMono(size: 10, color: textMuted)),
        ],
      ),
    );
  }
}
