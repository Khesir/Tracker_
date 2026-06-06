import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/media/media_info.dart';
import '../../../../core/media/media_service.dart';
import '../../../../core/state/stream_builder_widget.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/window/window_service.dart';
import '../../domain/controller/timer_controller.dart';
import '../state/timer_ui_state.dart';
import '../widget/record_disk_widget.dart';

// Design tokens — this widget is always light (white card over desktop)
const _kAccent = Color(0xFF16C172);
const _kInk = Color(0xFF16181D);
const _kMuted = Color(0xFF9AA0AB);
const _kLine = Color(0xFFE9EAEE);
const _kCardBg = Color(0xFFFAFAFA);

// Layout: vinyl overhangs 25px past the card's left edge.
// We give 30px of left window space so the vinyl (25px overhang) has a 5px gap.
const double _kCardLeft = 30;
const double _kCardWidth = 238;
const double _kVinylCard = 90.0;
const double _kVinylPill = 48.0;

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late final TimerController _controller;
  late final MediaService _media;
  late final StreamSubscription<MediaInfo> _mediaSub;

  MediaInfo _currentMedia = MediaInfo.none;
  bool _isPill = false;
  bool _noteOpen = false;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = locator.get<TimerController>();
    _media = locator.get<MediaService>();
    _mediaSub = _media.stream.listen((info) {
      if (mounted) setState(() => _currentMedia = info);
      _controller.onMediaChanged(info);
    });
  }

  @override
  void dispose() {
    _mediaSub.cancel();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _collapseToPill() async {
    setState(() {
      _isPill = true;
      _noteOpen = false;
    });
    await windowManager.setMinimumSize(Size.zero);
    await windowManager.setSize(AppStyling.miniPillSize);
  }

  Future<void> _expandToCard() async {
    setState(() => _isPill = false);
    await windowManager.setMinimumSize(Size.zero);
    await windowManager.setSize(AppStyling.miniCardSize);
  }

  Future<void> _toggleNote() async {
    final next = !_noteOpen;
    setState(() => _noteOpen = next);
    await windowManager.setMinimumSize(Size.zero);
    await windowManager.setSize(
      next ? AppStyling.miniCardNoteSize : AppStyling.miniCardSize,
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamStateBuilder<TimerUiData>(
        state: _controller.uiState,
        builder: (context, data) => _isPill ? _Pill(
          elapsed: _fmt(data.elapsed),
          media: _currentMedia,
          onExpand: _expandToCard,
        ) : _Card(
          elapsed: _fmt(data.elapsed),
          data: data,
          media: _currentMedia,
          noteOpen: _noteOpen,
          noteCtrl: _noteCtrl,
          onNoteChanged: _controller.updateNote,
          onToggleNote: _toggleNote,
          onCollapse: _collapseToPill,
          onExpand: () => locator.get<WindowService>().exitMiniMode(),
          onPlayPause: _media.playPause,
          onPrev: _media.skipPrevious,
          onNext: _media.skipNext,
        ),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String elapsed;
  final TimerUiData data;
  final MediaInfo media;
  final bool noteOpen;
  final TextEditingController noteCtrl;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onToggleNote;
  final VoidCallback onCollapse;
  final VoidCallback onExpand;
  final VoidCallback onPlayPause;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _Card({
    required this.elapsed,
    required this.data,
    required this.media,
    required this.noteOpen,
    required this.noteCtrl,
    required this.onNoteChanged,
    required this.onToggleNote,
    required this.onCollapse,
    required this.onExpand,
    required this.onPlayPause,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    // Vinyl: center is 45px from window top (2px card margin + 43px offset).
    // Vinyl spans y[0..90] in window coords. Left edge at x=5 (30-25=5).
    const vinylLeft = _kCardLeft - 25;
    const vinylTop = 0.0;

    final parts = elapsed.split(':');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // White card
        Positioned(
          left: _kCardLeft,
          top: 2,
          width: _kCardWidth,
          child: _CardBox(
            parts: parts,
            data: data,
            media: media,
            noteOpen: noteOpen,
            noteCtrl: noteCtrl,
            onNoteChanged: onNoteChanged,
            onToggleNote: onToggleNote,
            onCollapse: onCollapse,
            onExpand: onExpand,
            onPlayPause: onPlayPause,
            onPrev: onPrev,
            onNext: onNext,
          ),
        ),
        // Vinyl overhanging left edge
        Positioned(
          left: vinylLeft,
          top: vinylTop,
          child: RecordDiskWidget(
            isSpinning: media.isPlaying,
            albumArtUrl: media.albumArtUrl,
            size: _kVinylCard,
          ),
        ),
        // Anchor label below vinyl (hidden when note is open)
        if (!noteOpen)
          Positioned(
            left: vinylLeft,
            top: vinylTop + _kVinylCard + 4,
            width: _kVinylCard,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.anchor_rounded, size: 8, color: _kMuted),
                const SizedBox(width: 3),
                Text('anchor_', style: spaceMono(size: 8, color: _kMuted)),
              ],
            ),
          ),
      ],
    );
  }
}

class _CardBox extends StatelessWidget {
  final List<String> parts;
  final TimerUiData data;
  final MediaInfo media;
  final bool noteOpen;
  final TextEditingController noteCtrl;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onToggleNote;
  final VoidCallback onCollapse;
  final VoidCallback onExpand;
  final VoidCallback onPlayPause;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _CardBox({
    required this.parts,
    required this.data,
    required this.media,
    required this.noteOpen,
    required this.noteCtrl,
    required this.onNoteChanged,
    required this.onToggleNote,
    required this.onCollapse,
    required this.onExpand,
    required this.onPlayPause,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = data.isRunning
        ? 'tracking ${data.projectName ?? 'session'}'
        : (data.projectName != null ? 'paused · ${data.projectName}' : 'no_session');

    return Container(
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
              DragToMoveArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(70, 10, 36, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timer
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
                      const SizedBox(height: 5),
                      // Status
                      Text(
                        statusText,
                        style: spaceMono(size: 9.5, color: _kMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Transport row
                      Row(
                        children: [
                          _TransportBtn(icon: Icons.skip_previous_rounded, onTap: onPrev),
                          const SizedBox(width: 2),
                          _TransportBtn(
                            icon: media.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            onTap: onPlayPause,
                            isPrimary: true,
                          ),
                          const SizedBox(width: 2),
                          _TransportBtn(icon: Icons.skip_next_rounded, onTap: onNext),
                          Container(
                            width: 1, height: 15,
                            color: _kLine,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                          ),
                          const Spacer(),
                          _TransportBtn(
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
                child: Row(
                  children: [
                    _WinBtn(icon: Icons.open_in_full_rounded, tooltip: 'expand', onTap: onExpand),
                    const SizedBox(width: 1),
                    _WinBtn(icon: Icons.remove_rounded, tooltip: 'minimize', onTap: onCollapse),
                  ],
                ),
              ),
            ],
          ),
          // Note panel
          if (noteOpen) _NotePanel(controller: noteCtrl, onChanged: onNoteChanged),
        ],
      ),
    );
  }
}

// ── Pill ──────────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String elapsed;
  final MediaInfo media;
  final VoidCallback onExpand;

  const _Pill({required this.elapsed, required this.media, required this.onExpand});

  @override
  Widget build(BuildContext context) {
    final parts = elapsed.split(':');

    // Pill box starts at x=18; vinyl at x=4 (18-14=4).
    // Pill height=38, vinyl=48 → vinyl overhangs 5px above & below pill.
    // We offset pill to top=8 so vinyl sits at top=3 (8 - 5 = 3).
    const pillLeft = 18.0;
    const pillTop = 8.0;
    const vinylLeft = pillLeft - 14.0;
    const vinylTop = pillTop - 5.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: pillLeft,
          top: pillTop,
          child: DragToMoveArea(
            child: Container(
              height: 38,
              padding: const EdgeInsets.fromLTRB(36, 8, 10, 8),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.50),
                    offset: const Offset(0, 16),
                    blurRadius: 34,
                    spreadRadius: -16,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      style: spaceMono(size: 15, weight: FontWeight.w800),
                      children: [
                        TextSpan(text: parts[0], style: const TextStyle(color: _kInk)),
                        const TextSpan(text: ':', style: TextStyle(color: _kMuted, fontWeight: FontWeight.w500)),
                        TextSpan(text: parts[1], style: const TextStyle(color: _kInk)),
                        const TextSpan(text: ':', style: TextStyle(color: _kMuted, fontWeight: FontWeight.w500)),
                        TextSpan(text: parts[2], style: const TextStyle(color: _kAccent)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _WinBtn(icon: Icons.close_fullscreen_rounded, tooltip: 'expand', onTap: onExpand),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: vinylLeft,
          top: vinylTop,
          child: RecordDiskWidget(
            isSpinning: media.isPlaying,
            albumArtUrl: media.albumArtUrl,
            size: _kVinylPill,
          ),
        ),
      ],
    );
  }
}

// ── Note panel ───────────────────────────────────────────────────────────────

class _NotePanel extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _NotePanel({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: _kLine),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 5, 8, 3),
          child: Row(
            children: [
              RichText(
                text: TextSpan(
                  style: spaceMono(size: 9.5, color: _kMuted),
                  children: const [
                    TextSpan(text: 'note'),
                    TextSpan(text: '_', style: TextStyle(color: _kInk, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60, maxHeight: 150),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 1, 12, 11),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              maxLines: null,
              style: dmSans(size: 11, color: const Color(0xFF24272D)),
              decoration: InputDecoration.collapsed(
                hintText: 'what are you working on...',
                hintStyle: dmSans(size: 11, color: const Color(0xFFBCC0C8)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Small reusable buttons ────────────────────────────────────────────────────

class _TransportBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isActive;

  const _TransportBtn({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.isActive = false,
  });

  @override
  State<_TransportBtn> createState() => _TransportBtnState();
}

class _TransportBtnState extends State<_TransportBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color baseColor = widget.isPrimary
        ? _kInk
        : widget.isActive
            ? _kAccent
            : const Color(0xFF5D636D);

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

class _WinBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _WinBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_WinBtn> createState() => _WinBtnState();
}

class _WinBtnState extends State<_WinBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 22,
            height: 20,
            decoration: BoxDecoration(
              color: _hovered
                  ? Colors.black.withValues(alpha: 0.06)
                  : Colors.transparent,
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
      ),
    );
  }
}
