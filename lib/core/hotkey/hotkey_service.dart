import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../di/service_locator.dart';
import '../../features/settings/domain/controller/settings_controller.dart';
import '../../features/timer/domain/controller/timer_controller.dart';

class HotkeyService {
  HotKey? _registered;

  Future<void> initialize() async {
    await hotKeyManager.unregisterAll();
    final settings = locator.get<SettingsController>();
    final keyStr = settings.current?.hotkeyKey ?? 'ctrl+shift+t';
    final hotKey = _parse(keyStr);
    if (hotKey == null) return;
    await _register(hotKey);
  }

  Future<void> updateHotkey(String keyStr) async {
    if (_registered != null) {
      await hotKeyManager.unregister(_registered!);
      _registered = null;
    }
    final hotKey = _parse(keyStr);
    if (hotKey == null) return;
    await _register(hotKey);
  }

  Future<void> _register(HotKey hotKey) async {
    _registered = hotKey;
    await hotKeyManager.register(
      hotKey,
      keyDownHandler: (_) async {
        final timer = locator.get<TimerController>();
        if (timer.uiState.state.isRunning) {
          await timer.stop();
        } else {
          await windowManager.show();
          await windowManager.focus();
        }
      },
    );
  }

  Future<void> dispose() async {
    await hotKeyManager.unregisterAll();
    _registered = null;
  }

  // Parses "ctrl+shift+t" into a HotKey.
  static HotKey? _parse(String keyStr) {
    final parts = keyStr.toLowerCase().split('+');
    if (parts.isEmpty) return null;

    final keyLabel = parts.last.trim();
    final modifierLabels = parts.take(parts.length - 1).toSet();

    final physicalKey = _keyFromLabel(keyLabel);
    if (physicalKey == null) return null;

    final modifiers = <HotKeyModifier>[];
    if (modifierLabels.contains('ctrl') ||
        modifierLabels.contains('control')) {
      modifiers.add(HotKeyModifier.control);
    }
    if (modifierLabels.contains('shift')) modifiers.add(HotKeyModifier.shift);
    if (modifierLabels.contains('alt')) modifiers.add(HotKeyModifier.alt);
    if (modifierLabels.contains('meta') || modifierLabels.contains('win')) {
      modifiers.add(HotKeyModifier.meta);
    }

    return HotKey(
      key: physicalKey,
      modifiers: modifiers,
      scope: HotKeyScope.system,
    );
  }

  static PhysicalKeyboardKey? _keyFromLabel(String label) {
    const map = {
      'a': PhysicalKeyboardKey.keyA, 'b': PhysicalKeyboardKey.keyB,
      'c': PhysicalKeyboardKey.keyC, 'd': PhysicalKeyboardKey.keyD,
      'e': PhysicalKeyboardKey.keyE, 'f': PhysicalKeyboardKey.keyF,
      'g': PhysicalKeyboardKey.keyG, 'h': PhysicalKeyboardKey.keyH,
      'i': PhysicalKeyboardKey.keyI, 'j': PhysicalKeyboardKey.keyJ,
      'k': PhysicalKeyboardKey.keyK, 'l': PhysicalKeyboardKey.keyL,
      'm': PhysicalKeyboardKey.keyM, 'n': PhysicalKeyboardKey.keyN,
      'o': PhysicalKeyboardKey.keyO, 'p': PhysicalKeyboardKey.keyP,
      'q': PhysicalKeyboardKey.keyQ, 'r': PhysicalKeyboardKey.keyR,
      's': PhysicalKeyboardKey.keyS, 't': PhysicalKeyboardKey.keyT,
      'u': PhysicalKeyboardKey.keyU, 'v': PhysicalKeyboardKey.keyV,
      'w': PhysicalKeyboardKey.keyW, 'x': PhysicalKeyboardKey.keyX,
      'y': PhysicalKeyboardKey.keyY, 'z': PhysicalKeyboardKey.keyZ,
      'f1': PhysicalKeyboardKey.f1,  'f2': PhysicalKeyboardKey.f2,
      'f3': PhysicalKeyboardKey.f3,  'f4': PhysicalKeyboardKey.f4,
      'f5': PhysicalKeyboardKey.f5,  'f6': PhysicalKeyboardKey.f6,
      'f7': PhysicalKeyboardKey.f7,  'f8': PhysicalKeyboardKey.f8,
      'f9': PhysicalKeyboardKey.f9,  'f10': PhysicalKeyboardKey.f10,
      'f11': PhysicalKeyboardKey.f11,'f12': PhysicalKeyboardKey.f12,
      'space': PhysicalKeyboardKey.space,
    };
    return map[label];
  }
}
