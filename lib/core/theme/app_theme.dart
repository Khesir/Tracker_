import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_styling.dart';

class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppStyling.bgDark : AppStyling.bgLight;
    final surface = isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight;
    final accent = isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;
    final textPrimary = isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: isDark ? AppStyling.bgDark : Colors.white,
        secondary: isDark ? AppStyling.accentSecondaryDark : AppStyling.accentDarkLight,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
      ),
      dividerColor: border,
      cardColor: surface,
      textTheme: GoogleFonts.dmSansTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: textPrimary),
          bodyLarge: TextStyle(color: textPrimary, fontSize: AppStyling.bodySize),
          bodyMedium: TextStyle(color: textPrimary, fontSize: AppStyling.bodySize),
          bodySmall: TextStyle(color: textMuted, fontSize: AppStyling.labelSize),
        ),
      ),
      useMaterial3: true,
    );
  }
}

TextStyle spaceMono({
  double size = AppStyling.labelSize,
  FontWeight weight = FontWeight.w400,
  Color? color,
}) {
  return GoogleFonts.spaceMono(fontSize: size, fontWeight: weight, color: color);
}

TextStyle dmSans({
  double size = AppStyling.bodySize,
  FontWeight weight = FontWeight.w400,
  Color? color,
}) {
  return GoogleFonts.dmSans(fontSize: size, fontWeight: weight, color: color);
}
