import 'package:flutter/material.dart';

class AppStyling {
  // ── Light (Arctic Green) ──────────────────────────────────────
  static const Color bgLight = Color(0xFFFCFCFD);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFEDEEF1);
  static const Color borderLightStrong = Color(0xFFE4E5EA);
  static const Color textPrimaryLight = Color(0xFF1A1C22);
  static const Color textMutedLight = Color(0xFF9AA0AB);
  static const Color textFaintLight = Color(0xFFB9BDC5);
  static const Color accentLight = Color(0xFF1FBF6B);
  static const Color accentInkLight = Color(0xFF0F8F4D);
  static const Color accentDimLight = Color(0xFFE4F8ED);
  static const Color accentTint2Light = Color(0xFFD2F3E0);
  static const Color accentDarkLight = Color(0xFF0F8F4D);

  // ── Dark (Ocean Deep) ─────────────────────────────────────────
  static const Color bgDark = Color(0xFF0A1628);
  static const Color surfaceDark = Color(0xFF0F1E34);
  static const Color surfaceRaisedDark = Color(0xFF0F2340);
  static const Color borderDark = Color(0xFF1A3A5C);
  static const Color textPrimaryDark = Color(0xFFE8F4FF);
  static const Color textMutedDark = Color(0xFF4A7A9A);
  static const Color textFaintDark = Color(0xFF2A5A7A);
  static const Color accentPrimaryDark = Color(0xFF1D9E75);
  static const Color accentInkDark = Color(0xFF15C488);
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
  static const double titleBarHeight = 46;

  // ── Window sizes ──────────────────────────────────────────────
  static const Size fullWindowSize = Size(980, 700);
  static const Size fullWindowMinSize = Size(800, 600);
  static const Size miniCardSize = Size(296, 146);
  static const Size miniCardNoteSize = Size(296, 314);
  static const Size miniCardPickerSize = Size(296, 286);
  static const Size miniPillSize = Size(214, 72);
  // Issue 011 — sub-states of the note toggle for a resolved project with
  // no note linked yet (NoteResolution.noNoteLinked). The prompt
  // (create-new/link-existing) is compact; the link-existing picker adds
  // the same inline-list height budget as miniCardPickerSize's project
  // list (140px, see ProjectPicker/NoteLinkPickerWidget).
  static const Size miniCardNotePromptSize = Size(296, 226);
  static const Size miniCardNoteLinkSize = Size(296, 296);

  // ── bar_ card window sizes ──────────────────────────────────────
  // Narrower than the vinyl card — no disc overhang means far less left
  // margin is needed; card content itself is ~172px wide per the mockup.
  // Sized to include ~28px right / ~48px bottom clearance for the card's
  // BoxShadow (see bar_card_widget.dart) — the window's background is
  // transparent, so any unused margin is simply invisible, not a visual
  // defect; erring generous here is free.
  static const Size miniBarCardSize = Size(252, 230);
  static const Size miniBarCardNoteSize = Size(252, 395);
  static const Size miniBarCardPickerSize = Size(252, 368);
  // Issue 011 — mirrors miniCardNotePromptSize/miniCardNoteLinkSize above,
  // just against the bar_ card's taller base size.
  static const Size miniBarCardNotePromptSize = Size(252, 310);
  static const Size miniBarCardNoteLinkSize = Size(252, 380);

  // ── bar_ pill window sizes ────────────────────────────────────────
  // Narrower than the bar_ card (150px content width per the mockup,
  // vs. the card's 172px) but similar height — unlike the vinyl pill,
  // the bar_ pill keeps the music line and project row, so it isn't
  // drastically shorter than its card, only narrower. Same shadow
  // clearance reasoning as the bar_ card sizes above.
  static const Size miniBarPillSize = Size(230, 228);
  // +picker: base height plus the inline project list's max height
  // (140px, see ProjectPicker) — same delta pattern as
  // miniBarCardPickerSize vs. miniBarCardSize. The bar_ pill has no
  // existing "pill + picker" precedent (vinyl's pill has no picker at
  // all today), so this is a new state introduced by this widget.
  static const Size miniBarPillPickerSize = Size(230, 368);

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

  static Color borderStrong(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppStyling.borderDark : AppStyling.borderLightStrong;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;

  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppStyling.textMutedDark : AppStyling.textMutedLight;

  static Color accent(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;

  static Color accentInk(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppStyling.accentInkDark : AppStyling.accentInkLight;

  static Color accentDim(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? AppStyling.accentDimDark : AppStyling.accentDimLight;
}
