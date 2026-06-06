import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../../core/theme/app_theme.dart';

const _kLine = Color(0xFFE9EAEE);
const _kMuted = Color(0xFF9AA0AB);
const _kInk = Color(0xFF16181D);
const _kAccent = Color(0xFF16C172);

class NotePanelWidget extends StatefulWidget {
  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;

  const NotePanelWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
  });

  @override
  State<NotePanelWidget> createState() => _NotePanelWidgetState();
}

class _NotePanelWidgetState extends State<NotePanelWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  bool _isActive(Attribute attr) {
    final attrs = widget.controller.getSelectionStyle().attributes;
    if (!attrs.containsKey(attr.key)) return false;
    if (attr.value == null) return true;
    return attrs[attr.key]?.value == attr.value;
  }

  void _toggle(Attribute attr) {
    final isOn = _isActive(attr);
    widget.controller.formatSelection(isOn ? Attribute.clone(attr, null) : attr);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: _kLine),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 8, 3),
          child: Row(
            children: [
              RichText(
                text: TextSpan(
                  style: spaceMono(size: 9.5, color: _kMuted),
                  children: const [
                    TextSpan(text: 'note'),
                    TextSpan(
                      text: '_',
                      style: TextStyle(color: _kInk, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _FmtTextBtn(
                text: 'B',
                bold: true,
                active: _isActive(Attribute.bold),
                onTap: () => _toggle(Attribute.bold),
              ),
              _FmtTextBtn(
                text: 'I',
                italic: true,
                active: _isActive(Attribute.italic),
                onTap: () => _toggle(Attribute.italic),
              ),
              _FmtTextBtn(
                text: 'U',
                underline: true,
                active: _isActive(Attribute.underline),
                onTap: () => _toggle(Attribute.underline),
              ),
              _FmtTextBtn(
                text: 'S',
                strikethrough: true,
                active: _isActive(Attribute.strikeThrough),
                onTap: () => _toggle(Attribute.strikeThrough),
              ),
              _FmtIconBtn(
                icon: Icons.format_list_bulleted_rounded,
                active: _isActive(Attribute.ul),
                onTap: () => _toggle(Attribute.ul),
              ),
              _FmtIconBtn(
                icon: Icons.format_list_numbered_rounded,
                active: _isActive(Attribute.ol),
                onTap: () => _toggle(Attribute.ol),
              ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60, maxHeight: 150),
          child: QuillEditor(
            controller: widget.controller,
            focusNode: widget.focusNode,
            scrollController: widget.scrollController,
            config: QuillEditorConfig(
              scrollable: true,
              expands: false,
              placeholder: 'what are you working on...',
              padding: const EdgeInsets.fromLTRB(12, 1, 12, 11),
              customStyles: DefaultStyles(
                paragraph: DefaultTextBlockStyle(
                  dmSans(size: 11, color: const Color(0xFF24272D)),
                  HorizontalSpacing.zero,
                  VerticalSpacing.zero,
                  VerticalSpacing.zero,
                  null,
                ),
                placeHolder: DefaultTextBlockStyle(
                  dmSans(size: 11, color: const Color(0xFFBCC0C8)),
                  HorizontalSpacing.zero,
                  VerticalSpacing.zero,
                  VerticalSpacing.zero,
                  null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FmtTextBtn extends StatefulWidget {
  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final bool active;
  final VoidCallback onTap;

  const _FmtTextBtn({
    required this.text,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    required this.active,
    required this.onTap,
  });

  @override
  State<_FmtTextBtn> createState() => _FmtTextBtnState();
}

class _FmtTextBtnState extends State<_FmtTextBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? _kAccent : (_hovered ? _kInk : _kMuted);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: widget.active
                ? _kAccent.withValues(alpha: 0.1)
                : (_hovered ? Colors.black.withValues(alpha: 0.05) : Colors.transparent),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.text,
            style: spaceMono(size: 9).copyWith(
              color: color,
              fontWeight: widget.bold ? FontWeight.w800 : FontWeight.w400,
              fontStyle: widget.italic ? FontStyle.italic : FontStyle.normal,
              decoration: widget.underline
                  ? TextDecoration.underline
                  : widget.strikethrough
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
              decorationColor: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _FmtIconBtn extends StatefulWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _FmtIconBtn({required this.icon, required this.active, required this.onTap});

  @override
  State<_FmtIconBtn> createState() => _FmtIconBtnState();
}

class _FmtIconBtnState extends State<_FmtIconBtn> {
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
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: widget.active
                ? _kAccent.withValues(alpha: 0.1)
                : (_hovered ? Colors.black.withValues(alpha: 0.05) : Colors.transparent),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            size: 11,
            color: widget.active ? _kAccent : (_hovered ? _kInk : _kMuted),
          ),
        ),
      ),
    );
  }
}
