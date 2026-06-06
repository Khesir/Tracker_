import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/hotkey/hotkey_service.dart';
import '../../../../core/models/app_settings_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/state/stream_builder_widget.dart';
import '../../../../core/state/stream_state.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/scoped_screen.dart';
import '../../../projects/domain/controller/projects_controller.dart';
import '../../../sessions/domain/controller/sessions_controller.dart';
import '../../../timer/domain/controller/timer_controller.dart';
import '../../domain/controller/settings_controller.dart';

class SettingsScreen extends ScopedScreen {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ScopedScreenState<SettingsScreen> {
  late final SettingsController _ctrl;
  late final TimerController _timer;
  late final SessionsController _sessions;
  late final ProjectsController _projects;
  late final HotkeyService _hotkeys;

  @override
  void registerServices() {
    _ctrl = locator.get<SettingsController>();
    _timer = locator.get<TimerController>();
    _sessions = locator.get<SessionsController>();
    _projects = locator.get<ProjectsController>();
    _hotkeys = locator.get<HotkeyService>();
  }

  @override
  void onReady() {
    _ctrl.load();
    _projects.load();
    _sessions.load();
  }

  Future<void> _setTheme(String themeKey, AppSettingsModel current) async {
    if (current.themeKey == themeKey) return;
    await _ctrl.update(current.copyWith(themeKey: themeKey));
  }

  Future<void> _setInactivity(int seconds, AppSettingsModel current) async {
    await _ctrl.update(current.copyWith(inactivityTimeoutSeconds: seconds));
    _timer.setInactivityTimeout(seconds);
  }

  Future<void> _setInactivityBehavior(String behavior, AppSettingsModel current) async {
    await _ctrl.update(current.copyWith(inactivityBehavior: behavior));
    _timer.setInactivityBehavior(behavior);
  }

  Future<void> _setFloatLocked(bool locked, AppSettingsModel current) async {
    await _ctrl.update(current.copyWith(floatLocked: locked));
  }

  Future<void> _setAlwaysOnTop(bool v, AppSettingsModel current) async {
    await _ctrl.update(current.copyWith(alwaysOnTop: v));
  }

  Future<void> _setRoundToNearest(bool v, AppSettingsModel current) async {
    await _ctrl.update(current.copyWith(roundToNearest: v));
  }

  Future<void> _setAnchorVinyl(bool v, AppSettingsModel current) async {
    await _ctrl.update(current.copyWith(anchorVinyl: v));
  }

  Future<void> _exportCsv(BuildContext context, bool isDark, Color textMuted) async {
    final projectsState = _projects.uiState.state;
    final projects = projectsState is AsyncData<List<ProjectModel>>
        ? projectsState.data
        : <ProjectModel>[];
    final nameMap = {for (final p in projects) p.id: p.name};

    await _sessions.load();
    final path = await _sessions.exportCsv(nameMap);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight,
        content: Text(
          path != null ? 'saved to $path' : 'no sessions to export',
          style: dmSans(size: 12, color: textMuted),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppStyling.bgDark : AppStyling.bgLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;

    return Scaffold(
      backgroundColor: bg,
      body: AsyncStreamBuilder<AppSettingsModel>(
        state: _ctrl.uiState,
        builder: (context, settings) => CustomScrollView(
          slivers: [
            // appearance
            _SectionHeader(label: '// appearance', textMuted: textMuted),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _ThemeCard(
                        label: 'ocean_deep_',
                        themeKey: 'dark',
                        previewBg: AppStyling.bgDark,
                        previewAccent: AppStyling.accentPrimaryDark,
                        previewBorder: AppStyling.borderDark,
                        selected: settings.themeKey == 'dark',
                        isDark: isDark,
                        onTap: () => _setTheme('dark', settings),
                      ),
                    ),
                    const SizedBox(width: AppStyling.cardGap),
                    Expanded(
                      child: _ThemeCard(
                        label: 'arctic_green_',
                        themeKey: 'light',
                        previewBg: AppStyling.bgLight,
                        previewAccent: AppStyling.accentLight,
                        previewBorder: AppStyling.borderLight,
                        selected: settings.themeKey == 'light',
                        isDark: isDark,
                        onTap: () => _setTheme('light', settings),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // session
            _SectionHeader(label: '// session', textMuted: textMuted),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: _SetCard(
                  isDark: isDark,
                  rows: [
                    _SetRow(
                      isDark: isDark,
                      isLast: false,
                      label: 'inactivity_timeout',
                      description: null,
                      right: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'on_inactivity',
                                style: spaceMono(size: 10.5, color: textMuted),
                              ),
                              const SizedBox(width: 8),
                              _InactivityBehaviorPicker(
                                isDark: isDark,
                                value: settings.inactivityBehavior,
                                onChanged: (v) => _setInactivityBehavior(v, settings),
                              ),
                            ],
                          ),
                          if (settings.inactivityBehavior != 'disabled') ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${settings.inactivityTimeoutSeconds ~/ 60} min',
                                  style: spaceMono(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: isDark
                                        ? AppStyling.textPrimaryDark
                                        : AppStyling.textPrimaryLight,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 200,
                              child: Slider(
                                value: (settings.inactivityTimeoutSeconds / 60).clamp(1.0, 60.0),
                                min: 1,
                                max: 60,
                                divisions: 59,
                                activeColor: isDark
                                    ? AppStyling.accentPrimaryDark
                                    : AppStyling.accentLight,
                                inactiveColor: isDark
                                    ? AppStyling.borderDark
                                    : AppStyling.borderLight,
                                onChanged: (v) => _setInactivity(v.round() * 60, settings),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _SetRow(
                      isDark: isDark,
                      isLast: true,
                      label: 'round_to_nearest',
                      description: 'snap logged durations for tidy reports',
                      right: Switch(
                        value: settings.roundToNearest,
                        activeTrackColor: isDark
                            ? AppStyling.accentPrimaryDark
                            : AppStyling.accentLight,
                        activeThumbColor: Colors.white,
                        inactiveTrackColor: isDark
                            ? AppStyling.borderDark
                            : AppStyling.borderLightStrong,
                        onChanged: (v) => _setRoundToNearest(v, settings),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // float
            _SectionHeader(label: '// float', textMuted: textMuted),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: _SetCard(
                  isDark: isDark,
                  rows: [
                    _SetRow(
                      isDark: isDark,
                      isLast: false,
                      label: 'always_on_top',
                      description: 'keep the mini widget above other windows',
                      right: Switch(
                        value: settings.alwaysOnTop,
                        activeTrackColor: isDark
                            ? AppStyling.accentPrimaryDark
                            : AppStyling.accentLight,
                        activeThumbColor: Colors.white,
                        inactiveTrackColor: isDark
                            ? AppStyling.borderDark
                            : AppStyling.borderLightStrong,
                        onChanged: (v) => _setAlwaysOnTop(v, settings),
                      ),
                    ),
                    _SetRow(
                      isDark: isDark,
                      isLast: false,
                      label: 'lock_position',
                      description: 'pin the mini widget so it can\'t be dragged',
                      right: Switch(
                        value: settings.floatLocked,
                        activeTrackColor: isDark
                            ? AppStyling.accentPrimaryDark
                            : AppStyling.accentLight,
                        activeThumbColor: Colors.white,
                        inactiveTrackColor: isDark
                            ? AppStyling.borderDark
                            : AppStyling.borderLightStrong,
                        onChanged: (v) => _setFloatLocked(v, settings),
                      ),
                    ),
                    _SetRow(
                      isDark: isDark,
                      isLast: true,
                      label: 'anchor_vinyl',
                      description: 'let the record overhang the widget edge',
                      right: Switch(
                        value: settings.anchorVinyl,
                        activeTrackColor: isDark
                            ? AppStyling.accentPrimaryDark
                            : AppStyling.accentLight,
                        activeThumbColor: Colors.white,
                        inactiveTrackColor: isDark
                            ? AppStyling.borderDark
                            : AppStyling.borderLightStrong,
                        onChanged: (v) => _setAnchorVinyl(v, settings),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // shortcuts & data
            _SectionHeader(label: '// shortcuts & data', textMuted: textMuted),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: _SetCard(
                  isDark: isDark,
                  rows: [
                    _SetRow(
                      isDark: isDark,
                      isLast: false,
                      label: 'start_/_stop_session',
                      description: null,
                      right: _HotkeyPicker(
                        isDark: isDark,
                        currentKey: settings.hotkeyKey ?? 'ctrl+shift+t',
                        onChanged: (keyStr) async {
                          await _ctrl.update(settings.copyWith(hotkeyKey: keyStr));
                          await _hotkeys.updateHotkey(keyStr);
                        },
                      ),
                    ),
                    _SetRow(
                      isDark: isDark,
                      isLast: false,
                      label: 'export_all_sessions',
                      description: 'download your full history as a .csv file',
                      right: _ExportButton(
                        isDark: isDark,
                        textMuted: textMuted,
                        onTap: () => _exportCsv(context, isDark, textMuted),
                      ),
                    ),
                    _SetRow(
                      isDark: isDark,
                      isLast: true,
                      label: 'storage',
                      description: 'everything stays on this device',
                      right: Text(
                        '~/.trackr',
                        style: spaceMono(
                          size: 11,
                          color: textMuted,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loadingBuilder: (context) => const Center(
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color textMuted;

  const _SectionHeader({required this.label, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Text(label, style: spaceMono(size: 10, color: textMuted)),
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> rows;

  const _SetCard({required this.isDark, required this.rows});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLightStrong;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

class _SetRow extends StatelessWidget {
  final bool isDark;
  final bool isLast;
  final String label;
  final String? description;
  final Widget right;

  const _SetRow({
    required this.isDark,
    required this.isLast,
    required this.label,
    required this.description,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textPrimary = isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: spaceMono(size: 12.5, weight: FontWeight.w700, color: textPrimary),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: spaceMono(size: 10.5, color: textMuted),
                  ),
                ],
              ],
            ),
          ),
          right,
        ],
      ),
    );
  }
}

class _ThemeCard extends StatefulWidget {
  final String label;
  final String themeKey;
  final Color previewBg;
  final Color previewAccent;
  final Color previewBorder;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.label,
    required this.themeKey,
    required this.previewBg,
    required this.previewAccent,
    required this.previewBorder,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent =
        widget.isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;
    final border =
        widget.isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textMuted =
        widget.isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.selected
                ? (widget.isDark
                    ? AppStyling.accentDimDark
                    : AppStyling.accentDimLight)
                : (widget.isDark
                    ? AppStyling.surfaceDark
                    : AppStyling.surfaceLight),
            borderRadius: BorderRadius.circular(AppStyling.cardRadius),
            border: Border.all(
              color: widget.selected
                  ? accent.withValues(alpha: 0.6)
                  : (_hovered
                      ? accent.withValues(alpha: 0.3)
                      : border),
              width: widget.selected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 54,
                decoration: BoxDecoration(
                  color: widget.previewBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: widget.previewBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      decoration: BoxDecoration(
                        color: widget.previewAccent.withValues(alpha: 0.15),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          bottomLeft: Radius.circular(5),
                        ),
                        border: Border(
                          right: BorderSide(color: widget.previewBorder),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 4,
                              width: 40,
                              decoration: BoxDecoration(
                                color: widget.previewAccent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              height: 3,
                              width: 55,
                              decoration: BoxDecoration(
                                color: widget.previewBorder,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: spaceMono(size: 10, color: textMuted),
                    ),
                  ),
                  if (widget.selected)
                    Icon(Icons.check_rounded, size: 13, color: accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportButton extends StatefulWidget {
  final bool isDark;
  final Color textMuted;
  final VoidCallback onTap;

  const _ExportButton({
    required this.isDark,
    required this.textMuted,
    required this.onTap,
  });

  @override
  State<_ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<_ExportButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final border =
        widget.isDark ? AppStyling.borderDark : AppStyling.borderLight;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.textMuted.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border),
          ),
          child: Text(
            'export_csv_',
            style: spaceMono(size: 10, color: widget.textMuted),
          ),
        ),
      ),
    );
  }
}

// ── Inactivity Behavior Picker ────────────────────────────────────────────────

class _InactivityBehaviorPicker extends StatelessWidget {
  final bool isDark;
  final String value;
  final ValueChanged<String> onChanged;

  const _InactivityBehaviorPicker({
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = ['disabled', 'pause', 'stop'];
    final accent = isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((opt) {
        final selected = value == opt;
        return GestureDetector(
          onTap: () => onChanged(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: selected
                  ? (isDark ? AppStyling.accentDimDark : AppStyling.accentDimLight)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected ? accent.withValues(alpha: 0.6) : border,
              ),
            ),
            child: Text(
              opt,
              style: spaceMono(
                size: 10,
                color: selected ? (isDark ? AppStyling.accentBadgeTextDark : accent) : textMuted,
                weight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Hotkey Picker ─────────────────────────────────────────────────────────────

class _HotkeyPicker extends StatefulWidget {
  final String currentKey;
  final bool isDark;
  final Future<void> Function(String keyStr) onChanged;

  const _HotkeyPicker({
    required this.currentKey,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<_HotkeyPicker> createState() => _HotkeyPickerState();
}

class _HotkeyPickerState extends State<_HotkeyPicker> {
  bool _capturing = false;
  bool _hovered = false;

  void _startCapture() {
    setState(() => _capturing = true);
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CaptureDialog(isDark: widget.isDark),
    ).then((keyStr) {
      if (!mounted) return;
      setState(() => _capturing = false);
      if (keyStr != null && keyStr.isNotEmpty) {
        widget.onChanged(keyStr);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textMuted = widget.isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final accent = widget.isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _capturing ? null : _startCapture,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered && !_capturing
                ? accent.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _capturing ? accent : border),
          ),
          child: Text(
            _capturing ? 'press keys...' : widget.currentKey,
            style: spaceMono(
              size: 11,
              color: _capturing ? accent : textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureDialog extends StatefulWidget {
  final bool isDark;
  const _CaptureDialog({required this.isDark});

  @override
  State<_CaptureDialog> createState() => _CaptureDialogState();
}

class _CaptureDialogState extends State<_CaptureDialog> {
  String _preview = '';
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  String _buildKeyStr(KeyDownEvent event) {
    final parts = <String>[];
    if (HardwareKeyboard.instance.isControlPressed) parts.add('ctrl');
    if (HardwareKeyboard.instance.isShiftPressed) parts.add('shift');
    if (HardwareKeyboard.instance.isAltPressed) parts.add('alt');
    if (HardwareKeyboard.instance.isMetaPressed) parts.add('meta');

    final label = event.logicalKey.keyLabel.toLowerCase();
    if (label.isNotEmpty &&
        !['control', 'shift', 'alt', 'meta', 'caps lock'].contains(label)) {
      parts.add(label);
    }
    return parts.join('+');
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppStyling.bgDark : AppStyling.bgLight;
    final border = widget.isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textPrimary = widget.isDark
        ? AppStyling.textPrimaryDark
        : AppStyling.textPrimaryLight;
    final textMuted = widget.isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final accent = widget.isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border),
      ),
      child: KeyboardListener(
        focusNode: _focus,
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) return;
          final keyStr = _buildKeyStr(event);
          if (keyStr.isEmpty) return;
          setState(() => _preview = keyStr);
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context, null);
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (_preview.isNotEmpty) Navigator.pop(context, _preview);
          } else if (_preview.contains('+')) {
            final captured = _preview;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.pop(context, captured);
            });
          }
        },
        child: SizedBox(
          width: 340,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'press a key combination',
                  style: spaceMono(
                      size: 12,
                      weight: FontWeight.w700,
                      color: textPrimary),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? AppStyling.surfaceDark
                        : AppStyling.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _preview.isEmpty ? '...' : _preview,
                    style: spaceMono(
                        size: 16,
                        weight: FontWeight.w700,
                        color: _preview.isEmpty ? textMuted : accent),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'esc to cancel · enter to confirm',
                  style: dmSans(size: 11, color: textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
