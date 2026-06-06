import 'package:flutter/material.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';

enum ProjectStatus { active, queued, done }

class ProjectCardWidget extends StatefulWidget {
  final ProjectModel project;
  final int loggedSeconds;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onStart;

  const ProjectCardWidget({
    super.key,
    required this.project,
    required this.loggedSeconds,
    required this.isActive,
    required this.onTap,
    required this.onStart,
  });

  @override
  State<ProjectCardWidget> createState() => _ProjectCardWidgetState();
}

class _ProjectCardWidgetState extends State<ProjectCardWidget> {
  bool _hovered = false;

  ProjectStatus get _status {
    if (widget.isActive) return ProjectStatus.active;
    if (widget.loggedSeconds > 0) return ProjectStatus.done;
    return ProjectStatus.queued;
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textPrimary = isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final accent = isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;
    final hoverBg = isDark
        ? AppStyling.surfaceRaisedDark
        : AppStyling.surfaceLight;

    final targetSecs = (widget.project.targetMinutes ?? 0) * 60;
    final hasTarget = targetSecs > 0;
    final progress = hasTarget
        ? (widget.loggedSeconds / targetSecs).clamp(0.0, 1.0)
        : 0.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyling.cardPaddingH,
            vertical: AppStyling.cardPaddingV,
          ),
          decoration: BoxDecoration(
            color: _hovered ? hoverBg : surface,
            borderRadius: BorderRadius.circular(AppStyling.cardRadius),
            border: Border.all(
              color: widget.isActive ? accent.withValues(alpha: 0.4) : border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 115) return const SizedBox.shrink();
                  return Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(
                            int.parse(widget.project.colorHex.replaceFirst('#', '0xFF')),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.project.name,
                          style: spaceMono(
                            size: 12,
                            weight: FontWeight.w700,
                            color: textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _StatusBadge(status: _status, isDark: isDark),
                      if (!widget.isActive) ...[
                        const SizedBox(width: 8),
                        _StartButton(isDark: isDark, onTap: widget.onStart),
                      ],
                    ],
                  );
                },
              ),
              if (widget.loggedSeconds > 0 || hasTarget) ...[
                const SizedBox(height: 8),
                Text(
                  hasTarget
                      ? '${_formatDuration(widget.loggedSeconds)} of ${_formatDuration(targetSecs)}'
                      : _formatDuration(widget.loggedSeconds),
                  style: dmSans(size: 12, color: textMuted),
                ),
              ],
              if (hasTarget) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: AppStyling.progressBarHeight,
                    backgroundColor: border,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: spaceMono(size: 10, color: textMuted),
                    ),
                    Text(
                      '${_formatDuration(targetSecs - widget.loggedSeconds)} left',
                      style: dmSans(size: 10, color: textMuted),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ProjectStatus status;
  final bool isDark;

  const _StatusBadge({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      ProjectStatus.active => (
          'active_',
          isDark ? AppStyling.accentDimDark : AppStyling.accentDimLight,
          isDark ? AppStyling.accentBadgeTextDark : AppStyling.accentDarkLight,
        ),
      ProjectStatus.done => (
          'done_',
          isDark ? AppStyling.accentDimDark : AppStyling.accentDimLight,
          isDark ? AppStyling.accentBadgeTextDark : AppStyling.accentDarkLight,
        ),
      ProjectStatus.queued => (
          'queued_',
          isDark ? AppStyling.borderDark : AppStyling.borderLight,
          isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppStyling.badgeRadius),
      ),
      child: Text(label, style: spaceMono(size: AppStyling.badgeSize, color: fg)),
    );
  }
}

class _StartButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _StartButton({required this.isDark, required this.onTap});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _hovered ? accent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.play_arrow_rounded, size: 16, color: accent),
        ),
      ),
    );
  }
}
