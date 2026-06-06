import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/app_styling.dart';
import '../theme/app_theme.dart';
import '../window/window_service.dart';
import '../di/service_locator.dart';
import '../../features/timer/domain/controller/timer_controller.dart';
import '../../features/timer/presentation/state/timer_ui_state.dart';

class DesktopTitleBar extends StatelessWidget {
  const DesktopTitleBar({super.key});

  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppStyling.bgDark : AppStyling.bgLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;

    return Container(
      height: AppStyling.titleBarHeight,
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: DragToMoveArea(child: SizedBox.expand())),
          Row(
            children: [
              const SizedBox(width: 14),
              Text(
                'trackr_',
                style: spaceMono(
                  size: 13,
                  weight: FontWeight.w700,
                  color: isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight,
                ),
              ),
              const _LiveIndicator(),
              const Spacer(),
              _MiniModeButton(isDark: isDark),
              const SizedBox(width: 4),
              _WindowControls(isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveIndicator extends StatefulWidget {
  const _LiveIndicator();

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _opacity;
  late final StreamSubscription<TimerUiData> _sub;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    final ctrl = locator.get<TimerController>();
    _isRunning = ctrl.uiState.state.isRunning;
    if (_isRunning) _pulse.repeat(reverse: true);

    _sub = ctrl.uiState.stream.listen((data) {
      if (!mounted) return;
      if (data.isRunning != _isRunning) {
        setState(() => _isRunning = data.isRunning);
        if (_isRunning) {
          _pulse.repeat(reverse: true);
        } else {
          _pulse.stop();
          _pulse.value = 0;
        }
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final accent = isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;
    final color = _isRunning ? accent : muted;
    final label = _isRunning ? '• live' : 'idle';

    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _isRunning ? _opacity : AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 5),
          Text(label, style: spaceMono(size: 10, color: color)),
        ],
      ),
    );
  }
}

class _MiniModeButton extends StatelessWidget {
  final bool isDark;
  const _MiniModeButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _TitleBarButton(
      isDark: isDark,
      tooltip: 'mini mode',
      icon: Icons.picture_in_picture_alt_rounded,
      onTap: () => locator.get<WindowService>().enterMiniMode(),
    );
  }
}

class _WindowControls extends StatelessWidget {
  final bool isDark;
  const _WindowControls({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? const Color(0xFFA0A09A) : AppStyling.textMutedLight;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WinButton(
          isDark: isDark,
          onTap: () => windowManager.minimize(),
          child: Container(width: 10, height: 1.5, color: iconColor),
        ),
        _MaximizeButton(isDark: isDark),
        _WinButton(
          isDark: isDark,
          isClose: true,
          onTap: () => windowManager.close(),
          child: Icon(Icons.close, size: 14, color: iconColor),
        ),
      ],
    );
  }
}

class _TitleBarButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;
  final IconData icon;
  final String? tooltip;

  const _TitleBarButton({
    required this.isDark,
    required this.onTap,
    required this.icon,
    this.tooltip,
  });

  @override
  State<_TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<_TitleBarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverBg = widget.isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.07);
    final iconColor = widget.isDark ? const Color(0xFFA0A09A) : AppStyling.textMutedLight;

    final btn = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: _hovered ? hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(widget.icon, size: 16, color: iconColor),
        ),
      ),
    );

    return widget.tooltip != null
        ? Tooltip(message: widget.tooltip!, child: btn)
        : btn;
  }
}

class _WinButton extends StatefulWidget {
  final bool isDark;
  final bool isClose;
  final VoidCallback onTap;
  final Widget child;

  const _WinButton({
    required this.isDark,
    required this.onTap,
    required this.child,
    this.isClose = false,
  });

  @override
  State<_WinButton> createState() => _WinButtonState();
}

class _WinButtonState extends State<_WinButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverBg = widget.isClose
        ? const Color(0xFFEF4444)
        : (widget.isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 44,
          height: AppStyling.titleBarHeight,
          color: _hovered ? hoverBg : Colors.transparent,
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

class _MaximizeButton extends StatefulWidget {
  final bool isDark;
  const _MaximizeButton({required this.isDark});

  @override
  State<_MaximizeButton> createState() => _MaximizeButtonState();
}

class _MaximizeButtonState extends State<_MaximizeButton> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.isMaximized().then((v) {
      if (mounted) setState(() => _isMaximized = v);
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _isMaximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _isMaximized = false);

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isDark ? const Color(0xFFA0A09A) : AppStyling.textMutedLight;
    return _WinButton(
      isDark: widget.isDark,
      onTap: () async {
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
      child: _isMaximized
          ? Icon(Icons.filter_none, size: 11, color: iconColor)
          : Icon(Icons.crop_square_outlined, size: 14, color: iconColor),
    );
  }
}
