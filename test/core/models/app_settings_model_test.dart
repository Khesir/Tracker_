import 'package:flutter_test/flutter_test.dart';
import 'package:time_track/core/models/app_settings_model.dart';

void main() {
  group('AppSettingsModel.widgetStyle', () {
    test('defaults to vinyl', () {
      const settings = AppSettingsModel();

      expect(settings.widgetStyle, 'vinyl');
    });

    test('copyWith updates widgetStyle and leaves other fields unchanged', () {
      const settings = AppSettingsModel();

      final updated = settings.copyWith(widgetStyle: 'bar');

      expect(updated.widgetStyle, 'bar');
      expect(updated.themeKey, settings.themeKey);
      expect(updated.inactivityTimeoutSeconds, settings.inactivityTimeoutSeconds);
      expect(updated.inactivityBehavior, settings.inactivityBehavior);
      expect(updated.projectDrawerStyle, settings.projectDrawerStyle);
      expect(updated.floatLocked, settings.floatLocked);
      expect(updated.floatOffsetX, settings.floatOffsetX);
      expect(updated.floatOffsetY, settings.floatOffsetY);
      expect(updated.hotkeyKey, settings.hotkeyKey);
      expect(updated.alwaysOnTop, settings.alwaysOnTop);
      expect(updated.roundToNearest, settings.roundToNearest);
      expect(updated.anchorVinyl, settings.anchorVinyl);
      expect(updated.miniOpacityEnabled, settings.miniOpacityEnabled);
      expect(updated.miniIdleOpacity, settings.miniIdleOpacity);
    });

    test('fromJson(toJson()) round-trips widgetStyle', () {
      const settings = AppSettingsModel(widgetStyle: 'bar');

      final result = AppSettingsModel.fromJson(settings.toJson());

      expect(result.widgetStyle, 'bar');
    });

    test('fromJson falls back to vinyl when widgetStyle key is missing (legacy data)', () {
      final legacyJson = const AppSettingsModel().toJson()..remove('widgetStyle');

      final result = AppSettingsModel.fromJson(legacyJson);

      expect(result.widgetStyle, 'vinyl');
    });

    test('fromJson({}) falls back to vinyl', () {
      final result = AppSettingsModel.fromJson({});

      expect(result.widgetStyle, 'vinyl');
    });
  });
}
