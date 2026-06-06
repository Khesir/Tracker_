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

  Color _projectColor() {
    try {
      return Color(int.parse(widget.projectColorHex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppStyling.accentLight;
    }
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

  ({String value, String unit}) _splitDuration(int seconds) {
    if (seconds < 60) return (value: '$seconds', unit: 's');
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h == 0) return (value: '$m', unit: 'm');
    return (value: '${h}h $m', unit: 'm');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight;
    final borderColor = isDark ? AppStyling.borderDark : AppStyling.borderLightStrong;
    final hoverBorderColor = isDark ? const Color(0xFF2A5A7A) : const Color(0xFFDADCE1);
    final textPrimary = isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final textFaint = isDark ? AppStyling.textFaintDark : AppStyling.textFaintLight;

    final projectColor = _projectColor();
    final noteText = _notePlainText(widget.session.noteJson);
    final timeRange = widget.session.endedAt != null
        ? '${_formatTime(widget.session.startedAt)} → ${_formatTime(widget.session.endedAt!)}'
        : '${_formatTime(widget.session.startedAt)} → …';
    final dur = _splitDuration(widget.session.durationSeconds);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: _hovered ? hoverBorderColor : borderColor),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .2),
                      offset: const Offset(0, 4),
                      blurRadius: 14,
                      spreadRadius: -8,
                    )
                  ]
                : null,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: projectColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(11),
                      bottomLeft: Radius.circular(11),
                    ),
                  ),
                ),
                SizedBox(
                  width: 128,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 0, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.projectName,
                          style: spaceMono(size: 13, weight: FontWeight.w700, color: projectColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          timeRange,
                          style: spaceMono(size: 10.5, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 12, color: textFaint),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            noteText.isEmpty ? 'no note' : noteText,
                            style: spaceMono(
                              size: 11,
                              color: noteText.isEmpty ? textFaint : textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 13, 17, 13),
                  child: RichText(
                    text: TextSpan(
                      style: spaceMono(size: 14, weight: FontWeight.w800, color: textPrimary),
                      children: [
                        TextSpan(text: dur.value),
                        TextSpan(
                          text: dur.unit,
                          style: spaceMono(size: 10, weight: FontWeight.w500, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
