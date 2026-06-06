import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/state/stream_builder_widget.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/window/window_service.dart';
import '../../../timer/domain/controller/timer_controller.dart';
import '../../../timer/presentation/state/timer_ui_state.dart';

class ActiveSessionHeaderWidget extends StatelessWidget {
  const ActiveSessionHeaderWidget({super.key});

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final controller = locator.get<TimerController>();

    return StreamStateBuilder<TimerUiData>(
      state: controller.uiState,
      builder: (context, data) {
        if (!data.isRunning) return const SizedBox.shrink();
        return _ActiveHeader(data: data, formatElapsed: _formatElapsed);
      },
    );
  }
}

class _ActiveHeader extends StatelessWidget {
  final TimerUiData data;
  final String Function(Duration) formatElapsed;

  const _ActiveHeader({required this.data, required this.formatElapsed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('// active session', style: spaceMono(size: 10, color: textMuted)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatElapsed(data.elapsed),
                style: spaceMono(
                  size: AppStyling.timerSize,
                  weight: FontWeight.w700,
                  color: accent,
                ),
              ),
              const Spacer(),
              _MiniModeButton(isDark: isDark),
            ],
          ),
          if (data.projectName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                _PulsingDot(color: accent),
                const SizedBox(width: 6),
                Text(
                  '${data.projectName} — running',
                  style: dmSans(size: 12, color: textMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.4 + (_anim.value * 0.6)),
        ),
      ),
    );
  }
}

class _MiniModeButton extends StatefulWidget {
  final bool isDark;
  const _MiniModeButton({required this.isDark});

  @override
  State<_MiniModeButton> createState() => _MiniModeButtonState();
}

class _MiniModeButtonState extends State<_MiniModeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textMuted = widget.isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final hoverBg = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => locator.get<WindowService>().enterMiniMode(),
        child: Tooltip(
          message: 'float timer',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _hovered ? hoverBg : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.isDark ? AppStyling.borderDark : AppStyling.borderLight,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.picture_in_picture_alt_rounded, size: 13, color: textMuted),
                const SizedBox(width: 6),
                Text('float_', style: spaceMono(size: 10, color: textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
