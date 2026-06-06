import 'package:flutter/material.dart';
import 'routes.dart';
import '../../features/sessions/presentation/screen/sessions_screen.dart';
import '../../features/analytics/presentation/screen/analytics_screen.dart';
import '../../features/settings/presentation/screen/settings_screen.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => switch (settings.name) {
        Routes.sessions => const SessionsScreen(),
        Routes.analytics => const AnalyticsScreen(),
        Routes.settings => const SettingsScreen(),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
