import 'package:flutter/material.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';

class StatCardWidget extends StatelessWidget {
  final String value;
  final String label;
  final bool highlighted;

  const StatCardWidget({
    super.key,
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final accent = isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;
    final textPrimary = isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;

    final bg = highlighted
        ? (isDark
            ? AppStyling.accentDimDark
            : AppStyling.accentDimLight)
        : surface;
    final borderColor = highlighted ? accent.withValues(alpha: 0.3) : border;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppStyling.statBoxRadius),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: spaceMono(
              size: AppStyling.statsSize,
              weight: FontWeight.w700,
              color: highlighted ? accent : textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: dmSans(size: 11, color: textMuted)),
        ],
      ),
    );
  }
}
