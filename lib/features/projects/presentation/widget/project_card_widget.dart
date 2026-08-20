import 'package:flutter/material.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/state/stream_builder_widget.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../timer/presentation/state/timer_ui_state.dart';

class ProjectCardWidget extends StatefulWidget {
  final ProjectModel project;
  final int loggedSeconds;
  final int todaySeconds;
  final TimerUiState timerUiState;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const ProjectCardWidget({
    super.key,
    required this.project,
    required this.loggedSeconds,
    required this.todaySeconds,
    required this.timerUiState,
    required this.onTap,
    required this.onStart,
    required this.onStop,
    required this.onPause,
    required this.onResume,
  });

  @override
  State<ProjectCardWidget> createState() => _ProjectCardWidgetState();
}

class _ProjectCardWidgetState extends State<ProjectCardWidget> {
  bool _hovered = false;

  Color get _projectColor => Color(
        int.parse(widget.project.colorHex.replaceFirst('#', '0xFF')),
      );

  String _statusLine({required bool isRunning, required bool isPaused}) {
    if (isRunning) {
      final now = DateTime.now();
      final h = now.hour.toString().padLeft(2, '0');
      final min = now.minute.toString().padLeft(2, '0');
      return 'active · today $h:$min';
    }
    if (isPaused) return 'paused';
    return 'idle';
  }

  String _fmtElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return StreamStateBuilder<TimerUiData>(
      state: widget.timerUiState,
      builder: (context, timerData) {
        final isThisProject = timerData.projectId == widget.project.id;
        final isRunning = isThisProject && timerData.isRunning;
        final isPaused = isThisProject && timerData.isPaused;
        return _buildCard(
          context,
          isRunning: isRunning,
          isPaused: isPaused,
          elapsed: timerData.elapsed,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required bool isRunning,
    required bool isPaused,
    required Duration elapsed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight;
    final borderColor = isDark ? AppStyling.borderDark : AppStyling.borderLightStrong;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final progressBg = isDark ? AppStyling.borderDark : const Color(0xFFEEF0F2);

    final targetSecs = (widget.project.targetMinutes ?? 0) * 60;
    final hasTarget = targetSecs > 0;
    final progress =
        hasTarget ? (widget.todaySeconds / targetSecs).clamp(0.0, 1.0) : 0.0;

    final projectColor = _projectColor;

    final h = widget.loggedSeconds ~/ 3600;
    final m = (widget.loggedSeconds % 3600) ~/ 60;
    final mainDur = h > 0 ? '$h' : '$m';
    final unitDur = h > 0 ? 'h' : 'm';
    final subDur = h > 0 && m > 0 ? ' ${m}m' : '';

    final todayH = widget.todaySeconds ~/ 3600;
    final todayM = (widget.todaySeconds % 3600) ~/ 60;
    final todayLabel = todayH > 0 ? '${todayH}h' : '${todayM}m';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: borderColor),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 14,
                      spreadRadius: -8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: projectColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      bottomLeft: Radius.circular(11),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 128, maxWidth: 240),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.project.name,
                                style: spaceMono(
                                  size: 13,
                                  weight: FontWeight.w700,
                                  color: projectColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isRunning || isPaused)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.access_time_rounded,
                                        size: 10, color: textMuted),
                                    const SizedBox(width: 3),
                                    Text(
                                      _fmtElapsed(elapsed),
                                      style: spaceMono(
                                        size: 10.5,
                                        weight: FontWeight.w700,
                                        color: textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _statusLine(isRunning: isRunning, isPaused: isPaused),
                          style: spaceMono(size: 10.5, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: hasTarget
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 13, horizontal: 12),
                          child: Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: progressBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: LinearGradient(
                                        colors: [
                                          Color.lerp(
                                              projectColor, Colors.white, 0.4)!,
                                          projectColor,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 13, 17, 13),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: mainDur,
                                    style: spaceMono(
                                      size: 14,
                                      weight: FontWeight.w800,
                                      color: isDark
                                          ? AppStyling.textPrimaryDark
                                          : AppStyling.textPrimaryLight,
                                    ),
                                  ),
                                  TextSpan(
                                    text: unitDur,
                                    style: spaceMono(
                                      size: 10,
                                      weight: FontWeight.w400,
                                      color: textMuted,
                                    ),
                                  ),
                                  if (subDur.isNotEmpty)
                                    TextSpan(
                                      text: subDur,
                                      style: spaceMono(
                                        size: 10,
                                        weight: FontWeight.w400,
                                        color: textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'today $todayLabel',
                              style: spaceMono(size: 9, color: textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        if (isRunning)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _CardIconButton(
                                icon: Icons.stop_rounded,
                                color: projectColor,
                                onTap: widget.onStop,
                              ),
                              const SizedBox(width: 6),
                              _CardIconButton(
                                icon: Icons.pause_rounded,
                                color: projectColor,
                                onTap: widget.onPause,
                              ),
                            ],
                          )
                        else if (isPaused)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _CardIconButton(
                                icon: Icons.stop_rounded,
                                color: projectColor,
                                onTap: widget.onStop,
                              ),
                              const SizedBox(width: 6),
                              _CardIconButton(
                                icon: Icons.play_arrow_rounded,
                                color: projectColor,
                                onTap: widget.onResume,
                              ),
                            ],
                          )
                        else
                          AnimatedOpacity(
                            opacity: _hovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: _CardIconButton(
                              icon: Icons.play_arrow_rounded,
                              color: projectColor,
                              onTap: widget.onStart,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CardIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}
