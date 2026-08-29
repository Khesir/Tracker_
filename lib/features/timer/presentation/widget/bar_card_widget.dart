import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../core/media/media_info.dart';
import '../../../../core/models/note_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../state/timer_ui_state.dart';
import 'marquee_text_widget.dart';
import 'mini_title_field_widget.dart';
import 'note_link_prompt_widget.dart';
import 'project_picker_widget.dart';

// Design tokens — mirrors the vinyl card's recipe (lib/features/timer/
// presentation/screen/timer_screen.dart) so both card styles share the same
// "white card over desktop" look.
const _kAccent = Color(0xFF16C172);
const _kInk = Color(0xFF16181D);
const _kMuted = Color(0xFF9AA0AB);
const _kLine = Color(0xFFE9EAEE);
const _kCardBg = Color(0xFFFAFAFA);

const double _kBarCardWidth = 172;
const double _kBarLeft = 24;
const double _kBarTop = 14;
// The card's triple-layer BoxShadow (see below) extends well past its own
// box — dominant layer is offset(0,22) blurRadius:46 spreadRadius:-18,
// which reaches ~28px sideways and ~50px below the box. Right/bottom must
// reserve room for that or the OS window (which clips hard at its own
// bounds, unlike in-tree overflow) cuts the shadow off.
const double _kBarRight = 28;
const double _kBarBottom = 48;

/// The bar_ style's expanded "card" state — a leaner alternative to the
/// vinyl card: no disc, no transport controls, no progress bar. Shows a
/// passive music status line, the elapsed timer + a single note toggle,
/// and a project row that doubles as the project-switcher affordance.
class BarCard extends StatelessWidget {
  final String elapsed;
  final TimerUiData data;
  final MediaInfo media;
  final bool noteOpen;
  final NotePanelView noteView;
  final bool noteBusy;
  final List<NoteModel> unlinkedNotes;
  final bool pickerOpen;
  final List<ProjectModel> projects;
  final QuillController quillCtrl;
  final FocusNode noteFocus;
  final ScrollController noteScroll;
  final VoidCallback onToggleNote;
  final VoidCallback onCreateNote;
  final VoidCallback onLinkExisting;
  final ValueChanged<NoteModel> onSelectNote;
  final VoidCallback onBackToPrompt;
  final VoidCallback onTogglePicker;
  final ValueChanged<ProjectModel> onSelectProject;
  final VoidCallback onExpand;
  final ValueChanged<String> onUpdateTitle;

  const BarCard({
    super.key,
    required this.elapsed,
    required this.data,
    required this.media,
    required this.noteOpen,
    required this.noteView,
    required this.noteBusy,
    required this.unlinkedNotes,
    required this.pickerOpen,
    required this.projects,
    required this.quillCtrl,
    required this.noteFocus,
    required this.noteScroll,
    required this.onToggleNote,
    required this.onCreateNote,
    required this.onLinkExisting,
    required this.onSelectNote,
    required this.onBackToPrompt,
    required this.onTogglePicker,
    required this.onSelectProject,
    required this.onExpand,
    required this.onUpdateTitle,
  });

  @override
  Widget build(BuildContext context) {
    final parts = elapsed.split(':');

    return Padding(
      padding: const EdgeInsets.fromLTRB(_kBarLeft, _kBarTop, _kBarRight, _kBarBottom),
      child: Container(
        width: _kBarCardWidth,
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 1),
              blurRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.50),
              offset: const Offset(0, 22),
              blurRadius: 46,
              spreadRadius: -18,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0, 8),
              blurRadius: 18,
              spreadRadius: -10,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Body + window controls overlay
            Stack(
              children: [
                BarDragArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 30, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Passive music status line
                        if (media.hasTrack)
                          MarqueeText(
                            text: 'listening_ ${media.title}',
                            style: spaceMono(size: 9.5, color: _kMuted),
                          )
                        else
                          Text(
                            'not playing',
                            style: spaceMono(size: 9.5, color: _kMuted),
                          ),
                        const SizedBox(height: 6),
                        // Timer + note toggle
                        Row(
                          children: [
                            RichText(
                              text: TextSpan(
                                style: spaceMono(size: 19, weight: FontWeight.w800),
                                children: [
                                  TextSpan(text: parts[0], style: const TextStyle(color: _kInk)),
                                  const TextSpan(text: ':', style: TextStyle(color: _kMuted, fontWeight: FontWeight.w500)),
                                  TextSpan(text: parts[1], style: const TextStyle(color: _kInk)),
                                  const TextSpan(text: ':', style: TextStyle(color: _kMuted, fontWeight: FontWeight.w500)),
                                  TextSpan(text: parts[2], style: const TextStyle(color: _kAccent)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            _BarActionBtn(
                              icon: Icons.edit_note_rounded,
                              onTap: onToggleNote,
                              isActive: noteOpen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Window controls (top-right corner)
                Positioned(
                  top: 6,
                  right: 7,
                  child: BarWinBtn(
                    icon: Icons.open_in_full_rounded,
                    tooltip: 'expand',
                    onTap: onExpand,
                  ),
                ),
              ],
            ),
            // Project row — docked at the bottom. Issue 021 split this: the
            // dedicated chevron icon is now the only picker-toggle tap
            // target, while the rest of the row is an editable title field.
            BarProjectRow(
              title: data.title,
              placeholder: data.projectName ?? 'no session',
              isOpen: pickerOpen,
              onTogglePicker: onTogglePicker,
              onTitleChanged: onUpdateTitle,
            ),
            if (noteOpen) NotePanelArea(
              view: noteView,
              busy: noteBusy,
              unlinkedNotes: unlinkedNotes,
              quillCtrl: quillCtrl,
              noteFocus: noteFocus,
              noteScroll: noteScroll,
              onCreateNote: onCreateNote,
              onLinkExisting: onLinkExisting,
              onSelectNote: onSelectNote,
              onBackToPrompt: onBackToPrompt,
            ),
            if (pickerOpen) ProjectPicker(
              projects: projects,
              activeProjectId: data.projectId,
              onSelect: onSelectProject,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Project row (docked, title field + dedicated switcher icon) ───────────────
//
// Public — shared with BarPill (lib/features/timer/presentation/widget/
// bar_pill_widget.dart), which docks the same row at the bottom of the
// bar_ pill.
//
// Issue 021 split what used to be one big tap target (the whole row opened
// the picker) into two independent controls: the chevron icon is now the
// sole picker-toggle tap target, while the diamond bullet + name become an
// editable MiniTitleField (bound to TimerUiData.title, placeholder = the
// project name). Typing here never reaches onTogglePicker, and tapping the
// chevron never touches the text field.

class BarProjectRow extends StatelessWidget {
  final String? title;
  final String placeholder;
  final bool isOpen;
  final VoidCallback onTogglePicker;
  final ValueChanged<String> onTitleChanged;

  const BarProjectRow({
    super.key,
    required this.title,
    required this.placeholder,
    required this.isOpen,
    required this.onTogglePicker,
    required this.onTitleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kLine)),
      ),
      child: Row(
        children: [
          Text(
            '◆ ',
            style: spaceMono(size: 9.5, weight: FontWeight.w700, color: _kAccent),
          ),
          Expanded(
            child: MiniTitleField(
              title: title,
              placeholder: placeholder,
              onChanged: onTitleChanged,
              style: spaceMono(size: 9.5, weight: FontWeight.w700, color: _kAccent),
              placeholderStyle: spaceMono(
                size: 9.5,
                weight: FontWeight.w700,
                color: _kAccent.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _ProjectSwitchBtn(
            key: const Key('switch_project_'),
            isOpen: isOpen,
            onTap: onTogglePicker,
          ),
        ],
      ),
    );
  }
}

// Deliberately smaller than _BarActionBtn below (18x18 vs 25x23) — this
// docked row used to be a single flush-height text row with a bare 14px
// chevron Icon as its only affordance; keeping this button compact keeps
// the row's height close to what it was before the split, so it still
// fits the bar_ card/pill's existing fixed window sizes without pushing
// the note panel/picker below it out of frame.
class _ProjectSwitchBtn extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onTap;

  const _ProjectSwitchBtn({
    super.key,
    required this.isOpen,
    required this.onTap,
  });

  @override
  State<_ProjectSwitchBtn> createState() => _ProjectSwitchBtnState();
}

class _ProjectSwitchBtnState extends State<_ProjectSwitchBtn> {
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
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: (_hovered || widget.isOpen)
                ? _kAccent.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          alignment: Alignment.center,
          child: Icon(
            widget.isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
            size: 14,
            color: _kAccent,
          ),
        ),
      ),
    );
  }
}

// ── Small reusable buttons (mirrors _TransportBtn / _WinBtn's look) ───────────

class _BarActionBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _BarActionBtn({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<_BarActionBtn> createState() => _BarActionBtnState();
}

class _BarActionBtnState extends State<_BarActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color baseColor = widget.isActive ? _kAccent : const Color(0xFF5D636D);
    final Color hoverBg = widget.isActive
        ? _kAccent.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 25,
          height: 23,
          decoration: BoxDecoration(
            color: _hovered ? hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Icon(widget.icon, size: 13, color: _hovered ? _kInk : baseColor),
        ),
      ),
    );
  }
}

// Public — shared with BarPill, which uses the same "expand" affordance
// inline on its timer row.
class BarWinBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const BarWinBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<BarWinBtn> createState() => _BarWinBtnState();
}

class _BarWinBtnState extends State<BarWinBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // No Tooltip wrapper: its hover-triggered OverlayEntry, combined with
    // this window's native resizing (windowManager.setSize() on picker
    // toggle), was corrupting the Windows accessibility bridge's semantics
    // tree (repeated "Failed to update ui::AXTree" engine errors). Console
    // noise only — no functional break — but avoidable by not using
    // Tooltip's overlay mechanism here at all.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 22,
          height: 20,
          decoration: BoxDecoration(
            color: _hovered ? Colors.black.withValues(alpha: 0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            size: 12,
            color: _hovered ? _kInk : const Color(0xFFB0B5BD),
          ),
        ),
      ),
    );
  }
}

// ── Drag area (no double-tap maximize) ───────────────────────────────────────
//
// Public — shared with BarPill so both bar_ states drag the window the
// same way.

class BarDragArea extends StatelessWidget {
  final Widget child;
  const BarDragArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => windowManager.startDragging(),
      child: child,
    );
  }
}
