import 'package:flutter/material.dart';

class AppStyling {
  // ── Light (Arctic Green) ──────────────────────────────────────
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF8FAF8);
  static const Color borderLight = Color(0xFFE2E8E2);
  static const Color textPrimaryLight = Color(0xFF111812);
  static const Color textMutedLight = Color(0xFF6B7C6E);
  static const Color accentLight = Color(0xFF22C55E);
  static const Color accentDimLight = Color(0xFFBBF7D0);
  static const Color accentDarkLight = Color(0xFF15803D);

  // ── Dark (Ocean Deep) ─────────────────────────────────────────
  static const Color bgDark = Color(0xFF0A1628);
  static const Color surfaceDark = Color(0xFF0F1E34);
  static const Color surfaceRaisedDark = Color(0xFF0F2340);
  static const Color borderDark = Color(0xFF1A3A5C);
  static const Color textPrimaryDark = Color(0xFFE8F4FF);
  static const Color textMutedDark = Color(0xFF4A7A9A);
  static const Color accentPrimaryDark = Color(0xFF1D9E75);
  static const Color accentSecondaryDark = Color(0xFF4AACCC);
  static const Color accentDimDark = Color(0xFF04342C);
  static const Color accentBadgeTextDark = Color(0xFF5DCAA5);

  // ── Spacing ───────────────────────────────────────────────────
  static const double cardRadius = 10;
  static const double badgeRadius = 20;
  static const double statBoxRadius = 8;
  static const double progressBarHeight = 3;
  static const double cardPaddingH = 14;
  static const double cardPaddingV = 12;
  static const double cardGap = 10;

  // ── Type scale ────────────────────────────────────────────────
  static const double displaySize = 30;
  static const double timerSize = 32;
  static const double statsSize = 24;
  static const double bodySize = 14;
  static const double labelSize = 11;
  static const double badgeSize = 9;

  // ── Title bar ─────────────────────────────────────────────────
  static const double titleBarHeight = 40;

  // ── Window sizes ──────────────────────────────────────────────
  static const Size fullWindowSize = Size(980, 700);
  static const Size fullWindowMinSize = Size(800, 600);
  static const Size miniCardSize = Size(296, 146);
  static const Size miniCardNoteSize = Size(296, 314);
  static const Size miniCardPickerSize = Size(296, 286);
  static const Size miniPillSize = Size(214, 72);

  // kept for compatibility
  static const Size miniWindowSize = miniCardSize;
}

class AppColors {
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppStyling.bgDark : AppStyling.bgLight;

  static Color surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppStyling.surfaceDark : AppStyling.surfaceLight;

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppStyling.borderDark : AppStyling.borderLight;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;

  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppStyling.textMutedDark : AppStyling.textMutedLight;

  static Color accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;

  static Color accentDim(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppStyling.accentDimDark : AppStyling.accentDimLight;
}
