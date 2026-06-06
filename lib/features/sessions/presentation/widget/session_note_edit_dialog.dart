import 'package:flutter/material.dart';
import '../../../../core/models/session_model.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../timer/presentation/widget/session_note_widget.dart';

class SessionNoteEditDialog extends StatefulWidget {
  final SessionModel session;

  const SessionNoteEditDialog({super.key, required this.session});

  static Future<SessionModel?> show(
    BuildContext context,
    SessionModel session,
  ) {
    return showDialog<SessionModel>(
      context: context,
      builder: (_) => SessionNoteEditDialog(session: session),
    );
  }

  @override
  State<SessionNoteEditDialog> createState() => _SessionNoteEditDialogState();
}

class _SessionNoteEditDialogState extends State<SessionNoteEditDialog> {
  String _noteJson = '';

  @override
  void initState() {
    super.initState();
    _noteJson = widget.session.noteJson;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppStyling.bgDark : AppStyling.bgLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final accent = isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border),
      ),
      child: SizedBox(
        width: 480,
        height: 360,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Text(
                    'edit_note_',
                    style: spaceMono(
                      size: 12,
                      weight: FontWeight.w700,
                      color: textMuted,
                    ),
                  ),
                  const Spacer(),
                  _CloseButton(isDark: isDark, onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            Divider(color: border, height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SessionNoteWidget(
                  initialNoteJson: _noteJson,
                  onChanged: (json) => _noteJson = json,
                ),
              ),
            ),
            Divider(color: border, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _TextButton(
                    label: 'cancel',
                    color: textMuted,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  _TextButton(
                    label: 'save_',
                    color: accent,
                    onTap: () => Navigator.pop(
                      context,
                      widget.session.copyWith(noteJson: _noteJson),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _CloseButton({required this.isDark, required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.close, size: 14, color: color),
        ),
      ),
    );
  }
}

class _TextButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _TextButton({required this.label, required this.color, required this.onTap});

  @override
  State<_TextButton> createState() => _TextButtonState();
}

class _TextButtonState extends State<_TextButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: spaceMono(size: 11, color: widget.color),
          ),
        ),
      ),
    );
  }
}
