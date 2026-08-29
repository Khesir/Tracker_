import 'dart:async';
import 'package:flutter/material.dart';

/// Shared, directly-editable title field for all four desktop mini-widget
/// states (vinyl card, vinyl pill, bar_ card, bar_ pill) — issue 021.
///
/// Displays [title] (bound to `TimerUiData.title`) with [placeholder]
/// (the running session's project name) shown as a hint when blank. Saves
/// are debounced 500ms — matching the existing post-note field's debounce
/// interval (see `session_note_widget.dart`) — and go through [onChanged],
/// which callers wire to `TimerController.updateTitle()`.
///
/// Deliberately has no chrome of its own (no border/background) so it can
/// drop into each state's existing "project name" slot without disturbing
/// surrounding layout; callers control the text style so it matches each
/// state's typography. Like this codebase's other debounced text fields
/// (`_TitleField`/`_PostNoteField` in `session_detail_sheet.dart`), it does
/// not re-sync from a changed [title] after first build — acceptable here
/// since only one of the four states is mounted at a time, so there is no
/// live external editor to race against.
class MiniTitleField extends StatefulWidget {
  final String? title;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final TextStyle style;
  final TextStyle placeholderStyle;

  const MiniTitleField({
    super.key,
    required this.title,
    required this.placeholder,
    required this.onChanged,
    required this.style,
    required this.placeholderStyle,
  });

  @override
  State<MiniTitleField> createState() => _MiniTitleFieldState();
}

class _MiniTitleFieldState extends State<MiniTitleField> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.title ?? '');
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onChanged(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('session_title_'),
      controller: _controller,
      onChanged: _onChanged,
      maxLength: 80,
      maxLines: 1,
      style: widget.style,
      cursorColor: widget.style.color,
      cursorHeight: (widget.style.fontSize ?? 12) + 2,
      decoration: InputDecoration(
        isDense: true,
        isCollapsed: true,
        counterText: '',
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintText: widget.placeholder,
        hintStyle: widget.placeholderStyle,
        hintMaxLines: 1,
      ),
    );
  }
}
