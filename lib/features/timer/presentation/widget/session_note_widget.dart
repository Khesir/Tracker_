import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';

class SessionNoteWidget extends StatefulWidget {
  final String initialNoteJson;
  final ValueChanged<String> onChanged;

  const SessionNoteWidget({
    super.key,
    required this.initialNoteJson,
    required this.onChanged,
  });

  @override
  State<SessionNoteWidget> createState() => _SessionNoteWidgetState();
}

class _SessionNoteWidgetState extends State<SessionNoteWidget> {
  late final QuillController _quill;
  late final FocusNode _focusNode;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    Document doc;
    if (widget.initialNoteJson.isEmpty) {
      doc = Document();
    } else {
      try {
        doc = Document.fromJson(jsonDecode(widget.initialNoteJson) as List);
      } catch (_) {
        doc = Document();
      }
    }

    _quill = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _quill.addListener(_onDocChanged);
  }

  void _onDocChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final json = jsonEncode(_quill.document.toDelta().toJson());
      widget.onChanged(json);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _quill.removeListener(_onDocChanged);
    _quill.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final surface = isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: Row(
            children: [
              Text('note_', style: spaceMono(size: 9, color: textMuted)),
              const Spacer(),
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
                icon: Icons.format_list_bulleted,
                tooltip: 'bullets',
                isDark: isDark,
                onTap: () => _quill.formatSelection(Attribute.ul),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            padding: const EdgeInsets.all(10),
            child: QuillEditor.basic(
              controller: _quill,
              focusNode: _focusNode,
              config: QuillEditorConfig(
                placeholder: 'what are you working on...',
                customStyles: DefaultStyles(
                  paragraph: DefaultTextBlockStyle(
                    dmSans(size: 12, color: textPrimary),
                    const HorizontalSpacing(0, 0),
                    const VerticalSpacing(2, 2),
                    const VerticalSpacing(0, 0),
                    null,
                  ),
                  placeHolder: DefaultTextBlockStyle(
                    dmSans(size: 12, color: textMuted),
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
      ],
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
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _hovered
                  ? color.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 13, color: color),
          ),
        ),
      ),
    );
  }
}

