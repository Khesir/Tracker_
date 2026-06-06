library;

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/di/app_composition.dart';
import 'core/di/service_locator.dart';
import 'core/hotkey/hotkey_service.dart';
import 'core/window/window_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeApp();

  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await locator.get<WindowService>().initialize();
    await locator.get<HotkeyService>().initialize();
  }

  runApp(const TrackrApp());
}
