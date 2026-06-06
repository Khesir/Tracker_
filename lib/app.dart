import 'dart:async';
import 'package:flutter/material.dart';
import 'core/di/service_locator.dart';
import 'core/models/app_settings_model.dart';
import 'core/routing/app_router.dart';
import 'core/state/stream_state.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_styling.dart';
import 'core/ui/desktop_title_bar.dart';
import 'core/window/window_service.dart';
import 'features/projects/presentation/screen/projects_screen.dart';
import 'features/sessions/presentation/screen/sessions_screen.dart';
import 'features/analytics/presentation/screen/analytics_screen.dart';
import 'features/settings/domain/controller/settings_controller.dart';
import 'features/settings/presentation/screen/settings_screen.dart';
import 'features/timer/presentation/screen/timer_screen.dart';

class TrackrApp extends StatefulWidget {
  const TrackrApp({super.key});

  @override
  State<TrackrApp> createState() => _TrackrAppState();
}

class _TrackrAppState extends State<TrackrApp> {
  late final WindowService _windowService;
  late final SettingsController _settingsCtrl;
  late final StreamSubscription<WindowMode> _modeSub;
  late final StreamSubscription<AsyncState<AppSettingsModel>> _settingsSub;
  WindowMode _mode = WindowMode.full;
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _windowService = locator.get<WindowService>();
    _modeSub = _windowService.modeStream.listen((mode) {
      if (mounted) setState(() => _mode = mode);
    });

    _settingsCtrl = locator.get<SettingsController>();
    _settingsSub = _settingsCtrl.uiState.stream.listen((state) {
      if (state is AsyncData<AppSettingsModel> && mounted) {
        final mode = state.data.themeKey == 'light'
            ? ThemeMode.light
            : ThemeMode.dark;
        setState(() => _themeMode = mode);
      }
    });
    _settingsCtrl.load();
  }

  @override
  void dispose() {
    _modeSub.cancel();
    _settingsSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'trackr_',
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: _mode == WindowMode.mini
          ? const TimerScreen()
          : const _FullAppShell(),
      builder: (context, child) {
        if (_mode == WindowMode.mini) return child ?? const SizedBox();
        if (!DesktopTitleBar.isDesktop) return child ?? const SizedBox();
        return Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (_) => Column(
                children: [
                  const DesktopTitleBar(),
                  Expanded(child: child ?? const SizedBox()),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FullAppShell extends StatefulWidget {
  const _FullAppShell();

  @override
  State<_FullAppShell> createState() => _FullAppShellState();
}

class _FullAppShellState extends State<_FullAppShell> {
  int _selectedIndex = 0;

  static const _screens = [
    ProjectsScreen(),
    SessionsScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  static const _navItems = [
    _NavItem(label: 'projects_', icon: Icons.folder_outlined),
    _NavItem(label: 'sessions_', icon: Icons.timer_outlined),
    _NavItem(label: 'analytics_', icon: Icons.bar_chart_rounded),
    _NavItem(label: 'settings_', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppStyling.bgDark : AppStyling.bgLight;
    final surface = isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;

    return Scaffold(
      backgroundColor: bg,
      body: Row(
        children: [
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: surface,
              border: Border(right: BorderSide(color: border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                ...List.generate(_navItems.length, (i) => _NavButton(
                  item: _navItems[i],
                  selected: _selectedIndex == i,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedIndex = i),
                )),
              ],
            ),
          ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem({required this.label, required this.icon});
}

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;
    final textPrimary = widget.isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted = widget.isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final selectedBg = widget.isDark
        ? AppStyling.accentDimDark
        : AppStyling.accentDimLight;
    final hoverBg = widget.isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.04);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? selectedBg
                : (_hovered ? hoverBg : Colors.transparent),
            borderRadius: BorderRadius.circular(AppStyling.cardRadius),
          ),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                size: 16,
                color: widget.selected ? accent : textMuted,
              ),
              const SizedBox(width: 10),
              Text(
                widget.item.label,
                style: spaceMono(
                  size: AppStyling.labelSize,
                  weight: widget.selected ? FontWeight.w700 : FontWeight.w400,
                  color: widget.selected ? textPrimary : textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
