import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/media/media_info.dart';
import '../../../../core/media/media_service.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/state/stream_builder_widget.dart';
import '../../../../core/state/stream_state.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/window/window_service.dart';
import '../../domain/controller/timer_controller.dart';
import '../state/timer_ui_state.dart';
import '../widget/record_disk_widget.dart';
import '../../../projects/domain/controller/projects_controller.dart';

// Design tokens — this widget is always light (white card over desktop)
const _kAccent = Color(0xFF16C172);
const _kInk = Color(0xFF16181D);
const _kMuted = Color(0xFF9AA0AB);
const _kLine = Color(0xFFE9EAEE);
const _kCardBg = Color(0xFFFAFAFA);

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
  late final ProjectsController _projects;
  late final MediaService _media;
  late final StreamSubscription<MediaInfo> _mediaSub;
  late final StreamSubscription<dynamic> _projectsSub;

  MediaInfo _currentMedia = MediaInfo.none;
  List<ProjectModel> _projectList = [];
  bool _isPill = false;
  bool _noteOpen = false;
  bool _pickerOpen = false;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = locator.get<TimerController>();
    _projects = locator.get<ProjectsController>();
    _media = locator.get<MediaService>();
    _currentMedia = _media.current;
    _mediaSub = _media.stream.listen((info) {
      debugPrint('[TimerScreen] stream event: title=${info.title} playing=${info.isPlaying}');
      if (mounted) setState(() => _currentMedia = info);
      _controller.onMediaChanged(info);
    });
    // Request a snapshot immediately — C++ fetches SMTC state on a background
    // thread and pushes the result through the event channel.
    _media.requestSnapshot();
    _projectsSub = _projects.uiState.stream.listen((state) {
      if (!mounted) return;
      if (state is AsyncData<List<ProjectModel>>) {
        setState(() => _projectList =
            state.data.where((p) => !p.isArchived).toList());
      }
    });
    _projects.load();
  }

  @override
  void dispose() {
    _mediaSub.cancel();
    _projectsSub.cancel();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _collapseToPill() async {
    setState(() {
      _isPill = true;
      _noteOpen = false;
      _pickerOpen = false;
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
    setState(() {
      _noteOpen = next;
      _pickerOpen = false;
    });
    await windowManager.setMinimumSize(Size.zero);
    await windowManager.setSize(
      next ? AppStyling.miniCardNoteSize : AppStyling.miniCardSize,
    );
  }

  Future<void> _togglePicker() async {
    final next = !_pickerOpen;
    setState(() {
      _pickerOpen = next;
      _noteOpen = false;
    });
    await windowManager.setMinimumSize(Size.zero);
    await windowManager.setSize(
      next ? AppStyling.miniCardPickerSize : AppStyling.miniCardSize,
    );
  }

  Future<void> _selectProject(ProjectModel project) async {
    if (_controller.uiState.state.isRunning) {
      await _controller.stop();
    }
    await _controller.start(
      projectId: project.id,
      projectName: project.name,
    );
    setState(() => _pickerOpen = false);
    await windowManager.setMinimumSize(Size.zero);
    await windowManager.setSize(AppStyling.miniCardSize);
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
          pickerOpen: _pickerOpen,
          projects: _projectList,
          noteCtrl: _noteCtrl,
          onNoteChanged: _controller.updateNote,
          onToggleNote: _toggleNote,
          onTogglePicker: _togglePicker,
          onSelectProject: _selectProject,
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
  final bool pickerOpen;
  final List<ProjectModel> projects;
  final TextEditingController noteCtrl;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onToggleNote;
  final VoidCallback onTogglePicker;
  final ValueChanged<ProjectModel> onSelectProject;
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
    required this.pickerOpen,
    required this.projects,
    required this.noteCtrl,
    required this.onNoteChanged,
    required this.onToggleNote,
    required this.onTogglePicker,
    required this.onSelectProject,
    required this.onCollapse,
    required this.onExpand,
    required this.onPlayPause,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
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
            pickerOpen: pickerOpen,
            projects: projects,
            noteCtrl: noteCtrl,
            onNoteChanged: onNoteChanged,
            onToggleNote: onToggleNote,
            onTogglePicker: onTogglePicker,
            onSelectProject: onSelectProject,
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
            albumArtBytes: media.albumArtBytes,
            size: _kVinylCard,
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
  final bool pickerOpen;
  final List<ProjectModel> projects;
  final TextEditingController noteCtrl;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onToggleNote;
  final VoidCallback onTogglePicker;
  final ValueChanged<ProjectModel> onSelectProject;
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
    required this.pickerOpen,
    required this.projects,
    required this.noteCtrl,
    required this.onNoteChanged,
    required this.onToggleNote,
    required this.onTogglePicker,
    required this.onSelectProject,
    required this.onCollapse,
    required this.onExpand,
    required this.onPlayPause,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
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
                      // Project title
                      Text(
                        data.projectName ?? 'no session',
                        style: spaceMono(size: 8, color: _kMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
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
                      const SizedBox(height: 3),
                      // Now playing
                      if (media.hasTrack)
                        _MarqueeText(
                          text: 'now playing · ${media.title}',
                          style: spaceMono(size: 8.5, color: _kAccent),
                        )
                      else
                        Text(
                          'not playing',
                          style: spaceMono(size: 8.5, color: _kMuted),
                        ),
                      const SizedBox(height: 6),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _WinBtn(
                      icon: Icons.folder_open_rounded,
                      tooltip: 'switch project',
                      onTap: onTogglePicker,
                      isActive: pickerOpen,
                    ),
                    const SizedBox(width: 2),
                    _WinBtn(icon: Icons.open_in_full_rounded, tooltip: 'expand', onTap: onExpand),
                  ],
                ),
              ),
            ],
          ),
          // Note panel
          if (noteOpen) _NotePanel(controller: noteCtrl, onChanged: onNoteChanged),
          // Project picker panel
          if (pickerOpen) _ProjectPicker(
            projects: projects,
            activeProjectId: data.projectId,
            onSelect: onSelectProject,
          ),
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
            albumArtBytes: media.albumArtBytes,
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

// ── Project picker panel ──────────────────────────────────────────────────────

class _ProjectPicker extends StatelessWidget {
  final List<ProjectModel> projects;
  final String? activeProjectId;
  final ValueChanged<ProjectModel> onSelect;

  const _ProjectPicker({
    required this.projects,
    required this.activeProjectId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: _kLine),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 140),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 5),
            shrinkWrap: true,
            itemCount: projects.length,
            itemBuilder: (_, i) {
              final p = projects[i];
              final isActive = p.id == activeProjectId;
              return _ProjectRow(
                project: p,
                isActive: isActive,
                onTap: () => onSelect(p),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProjectRow extends StatefulWidget {
  final ProjectModel project;
  final bool isActive;
  final VoidCallback onTap;

  const _ProjectRow({
    required this.project,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_ProjectRow> createState() => _ProjectRowState();
}

class _ProjectRowState extends State<_ProjectRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse('FF${widget.project.colorHex.replaceFirst('#', '')}', radix: 16),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: _hovered
              ? Colors.black.withValues(alpha: 0.04)
              : Colors.transparent,
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  widget.project.name,
                  style: spaceMono(
                    size: 9,
                    color: widget.isActive ? _kInk : _kMuted,
                    weight: widget.isActive ? FontWeight.w700 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isActive)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kAccent,
                  ),
                ),
            ],
          ),
        ),
      ),
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
  final bool isActive;

  const _WinBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
  });

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
              color: widget.isActive
                  ? _kAccent.withValues(alpha: 0.12)
                  : _hovered
                      ? Colors.black.withValues(alpha: 0.06)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              size: 12,
              color: widget.isActive
                  ? _kAccent
                  : _hovered
                      ? _kInk
                      : const Color(0xFFB0B5BD),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Marquee ───────────────────────────────────────────────────────────────────

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _textWidth = 0;
  double _lineHeight = 12;

  static const double _gap = 36.0;
  static const double _speed = 38.0; // px per second

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void didUpdateWidget(_MarqueeText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _ctrl.stop();
      _ctrl.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
  }

  void _start() {
    if (!mounted) return;
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: TextDirection.ltr,
    )..layout();
    _textWidth = tp.width;
    _lineHeight = tp.height;
    if (_textWidth <= 0) return;
    _ctrl.duration = Duration(
      milliseconds: ((_textWidth + _gap) / _speed * 1000).round(),
    );
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_textWidth == 0) {
      return Text(widget.text, style: widget.style, maxLines: 1);
    }
    return SizedBox(
      height: _lineHeight,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final offset = _ctrl.value * (_textWidth + _gap);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: -offset,
                  child: Text(widget.text, style: widget.style),
                ),
                Positioned(
                  top: 0,
                  left: _textWidth + _gap - offset,
                  child: Text(widget.text, style: widget.style),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
