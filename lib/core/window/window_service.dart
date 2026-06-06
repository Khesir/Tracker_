import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/app_styling.dart';

enum WindowMode { full, mini }

class WindowService {
  final _modeController = StreamController<WindowMode>.broadcast();
  WindowMode _mode = WindowMode.full;

  Stream<WindowMode> get modeStream => _modeController.stream;
  WindowMode get mode => _mode;
  bool get isMiniMode => _mode == WindowMode.mini;

  Future<void> initialize() async {
    if (kIsWeb) return;
    await windowManager.ensureInitialized();

    const options = WindowOptions(
      size: AppStyling.fullWindowSize,
      minimumSize: AppStyling.fullWindowMinSize,
      titleBarStyle: TitleBarStyle.hidden,
      backgroundColor: Colors.transparent,
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  Future<void> enterMiniMode() async {
    if (isMiniMode) return;
    // Switch widget tree to TimerScreen before resizing so the full app shell
    // is never laid out at the mini window dimensions.
    _emit(WindowMode.mini);
    await windowManager.setBackgroundColor(Colors.transparent);
    // Clear minimum size before shrinking — otherwise setSize is silently
    // ignored when the target is smaller than the full-mode minimum (800×600).
    await windowManager.setMinimumSize(Size.zero);
    await windowManager.setResizable(false);
    await windowManager.setAsFrameless();
    await windowManager.setSize(AppStyling.miniWindowSize);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSkipTaskbar(true);
    await windowManager.setHasShadow(false);

    // Place widget at top-right of the primary display.
    final screen = WidgetsBinding.instance.platformDispatcher.views.first;
    final screenW = screen.physicalSize.width / screen.devicePixelRatio;
    await windowManager.setPosition(Offset(screenW - AppStyling.miniWindowSize.width - 24, 26));
  }

  Future<void> exitMiniMode() async {
    if (!isMiniMode) return;
    await windowManager.setHasShadow(true);
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setSkipTaskbar(false);
    await windowManager.setResizable(true);
    await windowManager.setMinimumSize(AppStyling.fullWindowMinSize);
    await windowManager.setSize(AppStyling.fullWindowSize);
    _emit(WindowMode.full);
  }

  Future<void> toggleMode() async {
    if (isMiniMode) {
      await exitMiniMode();
    } else {
      await enterMiniMode();
    }
  }

  void _emit(WindowMode mode) {
    _mode = mode;
    if (!_modeController.isClosed) _modeController.add(mode);
  }

  void dispose() => _modeController.close();
}
