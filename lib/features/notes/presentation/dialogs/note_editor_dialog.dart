import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../../core/models/note_model.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';

/// Full rich-text editor for a single [NoteModel], reusing the same
/// flutter_quill wiring pattern as `SessionNoteWidget` /
/// `NotePanelWidget` (see lib/features/timer/presentation/widget/). Pops
/// the encoded Quill delta JSON string on save, or null on cancel.
class NoteEditorDialog extends StatefulWidget {
  final NoteModel note;

  const NoteEditorDialog({super.key, required this.note});

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  late final QuillController _quill;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    Document doc;
    if (widget.note.noteJson.isEmpty) {
      doc = Document();
    } else {
      try {
        doc = Document.fromJson(jsonDecode(widget.note.noteJson) as List);
      } catch (_) {
        doc = Document();
      }
    }

    _quill = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  void dispose() {
    _quill.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _save() {
    final json = jsonEncode(_quill.document.toDelta().toJson());
    Navigator.of(context).pop(json);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppStyling.surfaceDark : AppStyling.bgLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textPrimary = isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final accent = isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;
    final surface = isDark ? AppStyling.bgDark : AppStyling.surfaceLight;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyling.cardRadius),
        side: BorderSide(color: border),
      ),
      child: SizedBox(
        width: 560,
        height: 480,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'edit_note',
                style: spaceMono(size: 13, weight: FontWeight.w700, color: textPrimary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ToolbarButton(
                    icon: Icons.format_bold,
                    tooltip: 'bold',
                    isDark: isDark,
                    onTap: () => _quill.formatSelection(Attribute.bold),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_italic,
                    tooltip: 'italic',
                    isDark: isDark,
                    onTap: () => _quill.formatSelection(Attribute.italic),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_underline,
                    tooltip: 'underline',
                    isDark: isDark,
                    onTap: () => _quill.formatSelection(Attribute.underline),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_list_bulleted,
                    tooltip: 'bullets',
                    isDark: isDark,
                    onTap: () => _quill.formatSelection(Attribute.ul),
                  ),
                  _ToolbarButton(
                    icon: Icons.format_list_numbered,
                    tooltip: 'numbered',
                    isDark: isDark,
                    onTap: () => _quill.formatSelection(Attribute.ol),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: border),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: QuillEditor.basic(
                    controller: _quill,
                    focusNode: _focusNode,
                    config: QuillEditorConfig(
                      placeholder: 'write something...',
                      customStyles: DefaultStyles(
                        paragraph: DefaultTextBlockStyle(
                          dmSans(size: 13, color: textPrimary),
                          const HorizontalSpacing(0, 0),
                          const VerticalSpacing(2, 2),
                          const VerticalSpacing(0, 0),
                          null,
                        ),
                        placeHolder: DefaultTextBlockStyle(
                          dmSans(size: 13, color: textMuted),
                          const HorizontalSpacing(0, 0),
                          const VerticalSpacing(2, 2),
                          const VerticalSpacing(0, 0),
                          null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _DialogButton(
                    label: 'cancel_',
                    isDark: isDark,
                    onTap: () => Navigator.of(context).pop(),
                    color: textMuted,
                  ),
                  const SizedBox(width: 8),
                  _DialogButton(
                    label: 'save_',
                    isDark: isDark,
                    onTap: _save,
                    color: accent,
                    filled: true,
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

class _ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<_ToolbarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: _hovered ? color.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 15, color: color),
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatefulWidget {
  final String label;
  final bool isDark;
  final VoidCallback? onTap;
  final Color color;
  final bool filled;

  const _DialogButton({
    required this.label,
    required this.isDark,
    required this.onTap,
    required this.color,
    this.filled = false,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.filled
        ? (widget.onTap == null
            ? widget.color.withValues(alpha: 0.4)
            : (_hovered ? widget.color.withValues(alpha: 0.85) : widget.color))
        : (_hovered ? widget.color.withValues(alpha: 0.08) : Colors.transparent);

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: spaceMono(
              size: 11,
              color: widget.filled ? Colors.white : widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
