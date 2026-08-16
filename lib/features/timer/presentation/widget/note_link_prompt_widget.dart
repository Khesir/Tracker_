import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../../core/models/note_model.dart';
import '../../../../core/theme/app_theme.dart';
import 'note_panel_widget.dart';

// Design tokens — mirrors the mini widget's other inline panels
// (note_panel_widget.dart, project_picker_widget.dart).
const _kAccent = Color(0xFF16C172);
const _kInk = Color(0xFF16181D);
const _kMuted = Color(0xFF9AA0AB);
const _kLine = Color(0xFFE9EAEE);

/// Which sub-view the mini widget's note area is currently showing —
/// resolved once per note-toggle press (via `TimerController.resolveNoteState`)
/// and only re-decided on the next press, a project switch, or a
/// create/link action completing.
enum NotePanelView { editor, prompt, linkPicker }

/// Swaps between [NotePanelWidget] (the Quill editor, `hasNote`),
/// [NoteLinkPromptWidget] (`noNoteLinked`, before an action is chosen) and
/// [NoteLinkPickerWidget] (`noNoteLinked`, after "link existing" is
/// pressed) based on [view] — the single "note area" both the vinyl card
/// (`_CardBox` in timer_screen.dart) and the bar_ card (`BarCard` in
/// bar_card_widget.dart) render when their note toggle is open.
class NotePanelArea extends StatelessWidget {
  final NotePanelView view;
  final bool busy;
  final List<NoteModel> unlinkedNotes;
  final QuillController quillCtrl;
  final FocusNode noteFocus;
  final ScrollController noteScroll;
  final VoidCallback onCreateNote;
  final VoidCallback onLinkExisting;
  final ValueChanged<NoteModel> onSelectNote;
  final VoidCallback onBackToPrompt;

  const NotePanelArea({
    super.key,
    required this.view,
    required this.busy,
    required this.unlinkedNotes,
    required this.quillCtrl,
    required this.noteFocus,
    required this.noteScroll,
    required this.onCreateNote,
    required this.onLinkExisting,
    required this.onSelectNote,
    required this.onBackToPrompt,
  });

  @override
  Widget build(BuildContext context) {
    switch (view) {
      case NotePanelView.prompt:
        return NoteLinkPromptWidget(
          busy: busy,
          onCreateNew: onCreateNote,
          onLinkExisting: onLinkExisting,
        );
      case NotePanelView.linkPicker:
        return NoteLinkPickerWidget(
          notes: unlinkedNotes,
          busy: busy,
          onSelect: onSelectNote,
          onBack: onBackToPrompt,
        );
      case NotePanelView.editor:
        return NotePanelWidget(
          controller: quillCtrl,
          focusNode: noteFocus,
          scrollController: noteScroll,
        );
    }
  }
}

/// Shown in place of [NotePanelWidget] when the resolved project has no
/// note linked (`NoteResolution.noNoteLinked`) — offers "create new" and
/// "link existing" instead of opening a blank/broken editor.
class NoteLinkPromptWidget extends StatelessWidget {
  final bool busy;
  final VoidCallback onCreateNew;
  final VoidCallback onLinkExisting;

  const NoteLinkPromptWidget({
    super.key,
    required this.busy,
    required this.onCreateNew,
    required this.onLinkExisting,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: _kLine),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: spaceMono(size: 9.5, color: _kMuted),
                  children: const [
                    TextSpan(text: 'no note linked'),
                    TextSpan(
                      text: '_',
                      style: TextStyle(color: _kInk, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _NotePromptButton(
                      label: 'create new',
                      onTap: busy ? null : onCreateNew,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _NotePromptButton(
                      label: 'link existing',
                      onTap: busy ? null : onLinkExisting,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotePromptButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  const _NotePromptButton({required this.label, required this.onTap});

  @override
  State<_NotePromptButton> createState() => _NotePromptButtonState();
}

class _NotePromptButtonState extends State<_NotePromptButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: !disabled && _hovered ? _kAccent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _kLine),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: spaceMono(
              size: 9,
              color: disabled ? _kAccent.withValues(alpha: 0.4) : _kAccent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Picker over notes that no live project currently points at — shown
/// after "link existing" is pressed from [NoteLinkPromptWidget]. Mirrors
/// the "derive unlinked" logic in project_detail_drawer.dart's
/// `_LinkExistingNoteDialog`, but laid out inline (resize-based) rather
/// than as an overlay dialog, since the mini widget is a real fixed-size
/// OS window.
class NoteLinkPickerWidget extends StatelessWidget {
  final List<NoteModel> notes;
  final bool busy;
  final ValueChanged<NoteModel> onSelect;
  final VoidCallback onBack;

  const NoteLinkPickerWidget({
    super.key,
    required this.notes,
    required this.busy,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: _kLine),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 3),
          child: Row(
            children: [
              _BackButton(onTap: onBack),
              const SizedBox(width: 2),
              RichText(
                text: TextSpan(
                  style: spaceMono(size: 9.5, color: _kMuted),
                  children: const [
                    TextSpan(text: 'link existing'),
                    TextSpan(
                      text: '_',
                      style: TextStyle(color: _kInk, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: _kAccent),
              ),
            ),
          )
        else if (notes.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Text(
              'no unlinked notes',
              style: spaceMono(size: 9, color: _kMuted),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 140),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 5),
              shrinkWrap: true,
              itemCount: notes.length,
              itemBuilder: (_, i) => _NoteLinkRow(
                note: notes[i],
                onTap: () => onSelect(notes[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
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
            color: _hovered ? Colors.black.withValues(alpha: 0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.arrow_back_rounded,
            size: 12,
            color: _hovered ? _kInk : _kMuted,
          ),
        ),
      ),
    );
  }
}

class _NoteLinkRow extends StatefulWidget {
  final NoteModel note;
  final VoidCallback onTap;

  const _NoteLinkRow({required this.note, required this.onTap});

  @override
  State<_NoteLinkRow> createState() => _NoteLinkRowState();
}

class _NoteLinkRowState extends State<_NoteLinkRow> {
  bool _hovered = false;

  String _preview() {
    if (widget.note.noteJson.isEmpty) return '(empty note)';
    try {
      final delta = jsonDecode(widget.note.noteJson) as List;
      final text = Document.fromJson(delta).toPlainText().trim();
      return text.isEmpty ? '(empty note)' : text;
    } catch (_) {
      return '(empty note)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: _hovered ? Colors.black.withValues(alpha: 0.04) : Colors.transparent,
          child: Text(
            _preview(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: spaceMono(size: 9, color: _hovered ? _kInk : _kMuted),
          ),
        ),
      ),
    );
  }
}
