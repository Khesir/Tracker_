import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/models/music_entry_model.dart';
import '../../../../core/models/session_model.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';
import '../widget/session_note_edit_dialog.dart';

class SessionDetailSheet extends StatelessWidget {
  final SessionModel session;
  final String projectName;
  final Future<void> Function(SessionModel updated) onSave;
  final Future<void> Function() onDelete;

  const SessionDetailSheet({
    super.key,
    required this.session,
    required this.projectName,
    required this.onSave,
    required this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required SessionModel session,
    required String projectName,
    required Future<void> Function(SessionModel updated) onSave,
    required Future<void> Function() onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SessionDetailSheet(
        session: session,
        projectName: projectName,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  String _formatDateTime(DateTime dt) {
    final weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final months = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
    ];
    final wd = weekdays[dt.weekday - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final mo = months[dt.month - 1];
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$wd, $d $mo — $h:$mi';
  }

  String _noteToText(String noteJson) {
    if (noteJson.isEmpty) return '';
    try {
      final delta = jsonDecode(noteJson) as List<dynamic>;
      return delta
          .where((op) => op is Map && op['insert'] is String)
          .map((op) => op['insert'] as String)
          .join()
          .trim();
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppStyling.bgDark : AppStyling.bgLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textPrimary =
        isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted =
        isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final accent =
        isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;

    final noteText = _noteToText(session.noteJson);
    final hasMusicLog = session.musicLog.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projectName,
                        style: spaceMono(
                          size: 13,
                          weight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatDateTime(session.startedAt),
                        style: dmSans(size: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppStyling.badgeRadius),
                  ),
                  child: Text(
                    _formatDuration(session.durationSeconds),
                    style: spaceMono(
                        size: 12, weight: FontWeight.w700, color: accent),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: border, height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // note section
                  Text('// note', style: spaceMono(size: 10, color: textMuted)),
                  const SizedBox(height: 10),
                  if (noteText.isEmpty)
                    Text(
                      'no_note',
                      style: dmSans(
                          size: AppStyling.bodySize,
                          color: textMuted.withValues(alpha: 0.5)),
                    )
                  else
                    Text(
                      noteText,
                      style: dmSans(size: AppStyling.bodySize, color: textPrimary),
                    ),

                  // music section
                  if (hasMusicLog) ...[
                    const SizedBox(height: 24),
                    Text(
                      '// music_log',
                      style: spaceMono(size: 10, color: textMuted),
                    ),
                    const SizedBox(height: 10),
                    ...session.musicLog.map(
                      (e) => _MusicLogRow(entry: e, textMuted: textMuted),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // actions
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'edit_note_',
                    isDark: isDark,
                    onTap: () async {
                      final updated =
                          await SessionNoteEditDialog.show(context, session);
                      if (updated != null) {
                        await onSave(updated);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'delete_',
                    isDark: isDark,
                    isDestructive: true,
                    onTap: () async {
                      final confirm = await _confirmDelete(context,
                          isDark: isDark, textMuted: textMuted);
                      if (confirm) {
                        await onDelete();
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context, {
    required bool isDark,
    required Color textMuted,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppStyling.bgDark : AppStyling.bgLight,
        title: Text(
          'delete_session_',
          style: spaceMono(
            size: 13,
            weight: FontWeight.w700,
            color: isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight,
          ),
        ),
        content: Text(
          'this action cannot be undone.',
          style: dmSans(size: AppStyling.bodySize, color: textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel', style: dmSans(size: 13, color: textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'delete',
              style: dmSans(size: 13, color: const Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _MusicLogRow extends StatelessWidget {
  final MusicEntryModel entry;
  final Color textMuted;

  const _MusicLogRow({required this.entry, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.music_note_rounded, size: 11, color: textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${entry.artist} — ${entry.title}',
              style: dmSans(size: AppStyling.labelSize, color: textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.isDark,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final border = widget.isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final accent = widget.isDark
        ? AppStyling.accentPrimaryDark
        : AppStyling.accentLight;
    final color =
        widget.isDestructive ? const Color(0xFFEF4444) : accent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: spaceMono(size: 11, color: color),
          ),
        ),
      ),
    );
  }
}
