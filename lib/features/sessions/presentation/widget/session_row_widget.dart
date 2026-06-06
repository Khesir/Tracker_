import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/models/session_model.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';

class SessionRowWidget extends StatefulWidget {
  final SessionModel session;
  final String projectName;
  final String projectColorHex;
  final VoidCallback onTap;

  const SessionRowWidget({
    super.key,
    required this.session,
    required this.projectName,
    required this.projectColorHex,
    required this.onTap,
  });

  @override
  State<SessionRowWidget> createState() => _SessionRowWidgetState();
}

class _SessionRowWidgetState extends State<SessionRowWidget> {
  bool _hovered = false;

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _notePlainText(String noteJson) {
    if (noteJson.isEmpty) return '';
    try {
      final delta = jsonDecode(noteJson) as List<dynamic>;
      return delta
          .where((op) => op is Map && op['insert'] is String)
          .map((op) => op['insert'] as String)
          .join()
          .replaceAll('\n', ' ')
          .trim();
    } catch (_) {
      return '';
    }
  }

  Color _projectColor() {
    try {
      return Color(
          int.parse(widget.projectColorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppStyling.accentLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textPrimary =
        isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted =
        isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final accent =
        isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;

    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.black.withValues(alpha: 0.02);

    final noteText = _notePlainText(widget.session.noteJson);
    final color = _projectColor();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyling.cardPaddingH,
            vertical: AppStyling.cardPaddingV,
          ),
          decoration: BoxDecoration(
            color: _hovered ? hoverBg : surface,
            borderRadius: BorderRadius.circular(AppStyling.cardRadius),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              // // color strip
              Container(
                width: 3,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.projectName,
                          style: spaceMono(
                              size: AppStyling.labelSize,
                              weight: FontWeight.w700,
                              color: accent),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(widget.session.startedAt),
                          style: dmSans(
                              size: AppStyling.labelSize, color: textMuted),
                        ),
                      ],
                    ),
                    if (noteText.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        noteText,
                        style: dmSans(
                            size: AppStyling.labelSize, color: textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDuration(widget.session.durationSeconds),
                    style: spaceMono(
                        size: 12,
                        weight: FontWeight.w700,
                        color: textPrimary),
                  ),
                  if (widget.session.musicLog.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.music_note_rounded,
                              size: 10, color: textMuted),
                          const SizedBox(width: 2),
                          Text(
                            '${widget.session.musicLog.length}',
                            style: dmSans(
                                size: AppStyling.labelSize, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
