import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../cache/local_cache.dart';
import '../cache/hive_local_cache.dart';
import '../di/service_locator.dart';
import '../di/di_logger.dart';
import '../hotkey/hotkey_service.dart';
import '../media/media_service.dart';
import '../media/windows_media_service.dart';
import '../window/window_service.dart';
import '../../features/sessions/api.dart';
import '../../features/projects/api.dart';
import '../../features/timer/api.dart';
import '../../features/analytics/api.dart';
import '../../features/settings/api.dart';

Future<void> initializeApp() async {
  if (kDebugMode) DILogger.enable();

  final cache = HiveLocalCache();
  await cache.init();

  locator.registerSingleton<LocalCache>(cache);
  locator.registerSingleton<WindowService>(WindowService());

  final MediaService mediaService =
      (!kIsWeb && Platform.isWindows) ? WindowsMediaService() : NullMediaService();
  await mediaService.initialize();
  locator.registerSingleton<MediaService>(mediaService);

  setupSessionsDependencies();
  setupProjectsDependencies();
  setupTimerDependencies();
  setupAnalyticsDependencies();
  setupSettingsDependencies();

  locator.registerSingleton<HotkeyService>(HotkeyService());
}
