library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/di/app_composition.dart';
import 'core/di/service_locator.dart';
import 'core/hotkey/hotkey_service.dart';
import 'core/window/single_instance_service.dart';
import 'core/window/window_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool isDesktop =
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  final singleInstance = SingleInstanceService();
  if (isDesktop && !await singleInstance.acquire()) {
    // Another instance already owns the cache lock; ping it to focus its
    // window instead of opening a second instance that would crash on
    // PathAccessException when opening the Hive boxes.
    return;
  }

  await initializeApp();

  if (isDesktop) {
    final windowService = locator.get<WindowService>();
    await windowService.initialize();
    singleInstance.onSecondInstanceLaunched = windowService.focusExisting;
    await locator.get<HotkeyService>().initialize();
  }

  runApp(const TrackrApp());
}
