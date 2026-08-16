import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/media/media_info.dart';
import '../../../../core/media/media_service.dart';
import '../../../../core/models/app_settings_model.dart';
import '../../../../core/models/note_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/state/stream_builder_widget.dart';
import '../../../../core/state/stream_state.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/window/window_service.dart';
import '../../domain/controller/timer_controller.dart';
import '../state/timer_ui_state.dart';
import '../widget/marquee_text_widget.dart';
import '../widget/note_link_prompt_widget.dart';
import '../widget/project_picker_widget.dart';
import '../widget/record_disk_widget.dart';
import '../widget/bar_card_widget.dart';
import '../widget/bar_pill_widget.dart';
import '../../../notes/domain/repository/notes_repository.dart';
import '../../../projects/domain/controller/projects_controller.dart';
import '../../../projects/domain/repository/projects_repository.dart';
import '../../../settings/domain/controller/settings_controller.dart';

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
  late final SettingsController _settings;
  late final NotesRepository _notesRepo;
  late final ProjectsRepository _projectsRepo;
  late final StreamSubscription<MediaInfo> _mediaSub;
  late final StreamSubscription<dynamic> _projectsSub;
  late final StreamSubscription<dynamic> _settingsSub;

  MediaInfo _currentMedia = MediaInfo.none;
  List<ProjectModel> _projectList = [];
  AppSettingsModel _currentSettings = const AppSettingsModel();
  bool _isPill = false;
  bool _noteOpen = false;
  bool _pickerOpen = false;
  bool _hovered = false;
  QuillController _quillCtrl = QuillController.basic();
  final _noteFocus = FocusNode();
  final _noteScroll = ScrollController();

  // Issue 011 — the note toggle now resolves a three-way note state
  // (TimerController.resolveNoteState) rather than always opening the
  // editor: _noteView tracks which sub-panel is showing (editor / the
  // create-or-link prompt / the link-existing picker), _noteProjectId
  // pins the create/link actions to whichever project resolved, and
  // _unlinkedNotes/_noteBusy back the picker sub-view.
  NotePanelView _noteView = NotePanelView.editor;
  String? _noteProjectId;
  List<NoteModel> _unlinkedNotes = [];
  bool _noteBusy = false;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<TimerController>();
    _projects = locator.get<ProjectsController>();
    _media = locator.get<MediaService>();
    _settings = locator.get<SettingsController>();
    _notesRepo = locator.get<NotesRepository>();
    _projectsRepo = locator.get<ProjectsRepository>();
    _quillCtrl.addListener(_onNoteChanged);
    _loadInitialNote();
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
            state.data.where((p) => !p.isDeleted).toList());
      }
    });
    _settingsSub = _settings.uiState.stream.listen((state) {
      if (!mounted) return;
      if (state is AsyncData<AppSettingsModel>) {
        setState(() => _currentSettings = state.data);
        // WindowService.enterMiniMode() unconditionally sizes the window to
        // the vinyl card's AppStyling.miniWindowSize before settings are
        // known. Whenever widgetStyle becomes known/changes, re-correct the
        // live window size — for whichever base state (card or pill) is
        // currently active — so this never fights the resize calls already
        // triggered by note/picker toggles.
        _syncBaseWindowSize();
      }
    });
    _settings.load();
    _projects.load();
  }

  bool get _isBar => _currentSettings.widgetStyle == 'bar';

  // The right base *card* size for the current style — single source of
  // truth reused by every resize call that needs to land back on "the
  // card", so the size choice never gets re-derived inline.
  Size get _baseCardSize => _isBar ? AppStyling.miniBarCardSize : AppStyling.miniCardSize;

  // The right base *pill* size for the current style — mirrors
  // _baseCardSize. Vinyl's pill is unaffected by widgetStyle (it always
  // renders _Pill at AppStyling.miniPillSize); the bar_ pill gets its own
  // narrower size.
  Size get _basePillSize => _isBar ? AppStyling.miniBarPillSize : AppStyling.miniPillSize;

  Future<void> _syncBaseWindowSize() async {
    // Guard on "no note, no picker open" only — this now corrects both
    // the base card state and the base pill state, since either one can
    // be sitting at the wrong size if widgetStyle changes underneath it
    // (e.g. a pill-state user flips vinyl/bar externally via settings).
    if (_noteOpen || _pickerOpen) return;
    final target = _isPill ? _basePillSize : _baseCardSize;
    await windowManager.setMinimumSize(Size.zero);
    await windowManager.setSize(target);
  }

  QuillController _buildQuillController(String? noteJson) {
    if (noteJson == null || noteJson.isEmpty) return QuillController.basic();
    try {
      final delta = Delta.fromJson(jsonDecode(noteJson) as List);
      return QuillController(
        document: Document.fromDelta(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      return QuillController.basic();
    }
  }

  // Note read/write is now resolved asynchronously (it may need to look up
  // the current project and its linked NoteModel via repositories) rather
  // than synchronously off the active session. This loads whatever note is
  // currently resolved (running session's project, or last-tracked project
  // while idle) once at startup; issue 011 builds the full "no note
  // linked" / "no project" prompt UI on top of TimerController.resolveNoteState().
  Future<void> _loadInitialNote() async {
    final state = await _controller.resolveNoteState();
    if (!mounted || !state.hasNoteLinked) return;
    final loaded = _buildQuillController(state.noteJson);
    _quillCtrl.removeListener(_onNoteChanged);
    _quillCtrl.dispose();
    setState(() => _quillCtrl = loaded);
    _quillCtrl.addListener(_onNoteChanged);
  }

  void _onNoteChanged() {
    final json = jsonEncode(_quillCtrl.document.toDelta().toJson());
    _controller.updateNote(json);
  }

  @override
  void dispose() {
    _quillCtrl.removeListener(_onNoteChanged);
    _quillCtrl.dispose();
    _noteFocus.dispose();
    _noteScroll.dispose();
    _mediaSub.cancel();
    _projectsSub.cancel();
    _settingsSub.cancel();
    super.dispose();
  }

  Future<void> _collapseToPill() async {
    setState(() {
      _isPill = true;
      _noteOpen = false;
      _pickerOpen = false;
    });
    await windowManager.setMinimumSize(Size.zero);
    await windowManager.setSize(_basePillSize);
  }

  Future<void> _expandToCard() async {
    setState(() => _isPill = false);
    await windowManager.setMinimumSize(Size.zero);
    await windowManager.setSize(_baseCardSize);
  }

  Future<void> _toggleNote() async {
    if (_noteOpen) {
      setState(() => _noteOpen = false);
      await windowManager.setMinimumSize(Size.zero);
      await windowManager.setSize(_baseCardSize);
      return;
    }

    final state = await _controller.resolveNoteState();
    if (!mounted) return;

    // noProject: the rare "never tracked a single session" case — nothing
    // sensible to create/link against, so the toggle is a deliberate no-op
    // per issue 011 rather than opening a broken prompt.
    if (!state.hasProject) return;

    setState(() {
      _pickerOpen = false;
      _noteProjectId = state.projectId;
    });

    if (state.hasNoteLinked) {
      await _openNoteEditor(state.noteJson);
      return;
    }

    setState(() {
      _noteOpen = true;
      _noteView = NotePanelView.prompt;
    });
    await windowManager.setMinimumSize(Size.zero);
    final promptSize =
        _isBar ? AppStyling.miniBarCardNotePromptSize : AppStyling.miniCardNotePromptSize;
    await windowManager.setSize(promptSize);
  }

  // Swaps in a freshly-loaded QuillController bound to [noteJson] and
  // resizes to the editor state — shared by the direct hasNote path, and
  // by the create/link actions below once they've resolved a note to edit.
  Future<void> _openNoteEditor(String? noteJson) async {
    final loaded = _buildQuillController(noteJson);
    _quillCtrl.removeListener(_onNoteChanged);
    _quillCtrl.dispose();
    setState(() {
      _quillCtrl = loaded;
      _noteOpen = true;
      _noteView = NotePanelView.editor;
    });
    _quillCtrl.addListener(_onNoteChanged);
    await windowManager.setMinimumSize(Size.zero);
    final noteSize = _isBar ? AppStyling.miniBarCardNoteSize : AppStyling.miniCardNoteSize;
    await windowManager.setSize(noteSize);
    _noteFocus.requestFocus();
  }

  // "create new" from the note-link prompt — builds a NoteModel directly
  // (mirrors project_detail_drawer.dart's _NoteSection._createAndLink),
  // links it to the resolved project, then opens it ready to type.
  Future<void> _createNote() async {
    final projectId = _noteProjectId;
    if (projectId == null || _noteBusy) return;
    setState(() => _noteBusy = true);
    final now = DateTime.now();
    final note = NoteModel(id: const Uuid().v4(), noteJson: '', createdAt: now, updatedAt: now);
    await _notesRepo.save(note);
    final project = await _projectsRepo.getById(projectId);
    if (project != null) {
      await _projectsRepo.save(project.copyWith(noteId: note.id));
    }
    if (!mounted) return;
    setState(() => _noteBusy = false);
    await _openNoteEditor(note.noteJson);
  }

  // "link existing" from the note-link prompt — switches to the picker
  // sub-view and loads notes that no live project currently points at,
  // mirroring project_detail_drawer.dart's _LinkExistingNoteDialog._load.
  Future<void> _openLinkPicker() async {
    setState(() {
      _noteView = NotePanelView.linkPicker;
      _noteBusy = true;
    });
    await windowManager.setMinimumSize(Size.zero);
    final linkSize =
        _isBar ? AppStyling.miniBarCardNoteLinkSize : AppStyling.miniCardNoteLinkSize;
    await windowManager.setSize(linkSize);

    final allNotes = await _notesRepo.getAll();
    final allProjects = await _projectsRepo.getAll();
    final linkedIds = allProjects.map((p) => p.noteId).whereType<String>().toSet();
    final unlinked = allNotes.where((n) => !linkedIds.contains(n.id)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (!mounted) return;
    setState(() {
      _unlinkedNotes = unlinked;
      _noteBusy = false;
    });
  }

  Future<void> _backToNotePrompt() async {
    setState(() {
      _noteView = NotePanelView.prompt;
      _unlinkedNotes = [];
    });
    await windowManager.setMinimumSize(Size.zero);
    final promptSize =
        _isBar ? AppStyling.miniBarCardNotePromptSize : AppStyling.miniCardNotePromptSize;
    await windowManager.setSize(promptSize);
  }

  // Selecting a note from the link-existing picker — links it to the
  // resolved project, then opens it.
  Future<void> _linkExistingNote(NoteModel note) async {
    final projectId = _noteProjectId;
    if (projectId == null || _noteBusy) return;
    setState(() => _noteBusy = true);
    final project = await _projectsRepo.getById(projectId);
    if (project != null) {
      await _projectsRepo.save(project.copyWith(noteId: note.id));
    }
    if (!mounted) return;
    setState(() => _noteBusy = false);
    await _openNoteEditor(note.noteJson);
  }

  Future<void> _togglePicker() async {
    final next = !_pickerOpen;
    setState(() {
      _pickerOpen = next;
      _noteOpen = false;
    });
    await windowManager.setMinimumSize(Size.zero);
    if (_isPill) {
      // Only the bar_ pill wires up a picker today — the vinyl pill has
      // no project-row affordance at all — but branch on the current
      // pill's own base size regardless, so this stays correct if that
      // ever changes.
      await windowManager.setSize(next ? AppStyling.miniBarPillPickerSize : _basePillSize);
      return;
    }
    final pickerSize = _isBar ? AppStyling.miniBarCardPickerSize : AppStyling.miniCardPickerSize;
    await windowManager.setSize(next ? pickerSize : _baseCardSize);
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
    // Land back on whichever base is actually active — bar pill, bar
    // card, or vinyl card — not just "the card" unconditionally, since
    // the picker is now reachable from the bar_ pill too.
    await windowManager.setSize(_isPill ? _basePillSize : _baseCardSize);
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final fadeEnabled = _currentSettings.miniOpacityEnabled;
    final idleOpacity = _currentSettings.miniIdleOpacity;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: fadeEnabled && !_hovered ? idleOpacity : 1.0,
          child: StreamStateBuilder<TimerUiData>(
            state: _controller.uiState,
            builder: (context, data) => _isPill ? (_isBar ? BarPill(
              elapsed: _fmt(data.elapsed),
              media: _currentMedia,
              projectName: data.projectName,
              activeProjectId: data.projectId,
              pickerOpen: _pickerOpen,
              projects: _projectList,
              onExpand: _expandToCard,
              onTogglePicker: _togglePicker,
              onSelectProject: _selectProject,
            ) : _Pill(
              elapsed: _fmt(data.elapsed),
              media: _currentMedia,
              onExpand: _expandToCard,
            )) : _isBar ? BarCard(
              elapsed: _fmt(data.elapsed),
              data: data,
              media: _currentMedia,
              noteOpen: _noteOpen,
              noteView: _noteView,
              noteBusy: _noteBusy,
              unlinkedNotes: _unlinkedNotes,
              pickerOpen: _pickerOpen,
              projects: _projectList,
              quillCtrl: _quillCtrl,
              noteFocus: _noteFocus,
              noteScroll: _noteScroll,
              onToggleNote: _toggleNote,
              onCreateNote: _createNote,
              onLinkExisting: _openLinkPicker,
              onSelectNote: _linkExistingNote,
              onBackToPrompt: _backToNotePrompt,
              onTogglePicker: _togglePicker,
              onSelectProject: _selectProject,
              onExpand: () => locator.get<WindowService>().exitMiniMode(),
            ) : _Card(
              elapsed: _fmt(data.elapsed),
              data: data,
              media: _currentMedia,
              noteOpen: _noteOpen,
              noteView: _noteView,
              noteBusy: _noteBusy,
              unlinkedNotes: _unlinkedNotes,
              pickerOpen: _pickerOpen,
              projects: _projectList,
              quillCtrl: _quillCtrl,
              noteFocus: _noteFocus,
              noteScroll: _noteScroll,
              onToggleNote: _toggleNote,
              onCreateNote: _createNote,
              onLinkExisting: _openLinkPicker,
              onSelectNote: _linkExistingNote,
              onBackToPrompt: _backToNotePrompt,
              onTogglePicker: _togglePicker,
              onSelectProject: _selectProject,
              onCollapse: _collapseToPill,
              onExpand: () => locator.get<WindowService>().exitMiniMode(),
              onPlayPause: _media.playPause,
              onPrev: _media.skipPrevious,
              onNext: _media.skipNext,
            ),
          ),
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
            noteView: noteView,
            noteBusy: noteBusy,
            unlinkedNotes: unlinkedNotes,
            pickerOpen: pickerOpen,
            projects: projects,
            quillCtrl: quillCtrl,
            noteFocus: noteFocus,
            noteScroll: noteScroll,
            onToggleNote: onToggleNote,
            onCreateNote: onCreateNote,
            onLinkExisting: onLinkExisting,
            onSelectNote: onSelectNote,
            onBackToPrompt: onBackToPrompt,
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
              _DragArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(70, 10, 36, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project title
                      Text(
                        data.projectName ?? 'no session',
                        style: spaceMono(size: 10, color: _kMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Timer
                      RichText(
                        text: TextSpan(
                          style: spaceMono(size: 21, weight: FontWeight.w800),
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
                        MarqueeText(
                          text: 'now playing · ${media.title}',
                          style: spaceMono(size: 10, color: _kAccent),
                        )
                      else
                        Text(
                          'not playing',
                          style: spaceMono(size: 10, color: _kMuted),
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
          // Project picker panel
          if (pickerOpen) ProjectPicker(
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
          child: _DragArea(
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

// ── Drag area (no double-tap maximize) ───────────────────────────────────────

class _DragArea extends StatelessWidget {
  final Widget child;
  const _DragArea({required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => windowManager.startDragging(),
      child: child,
    );
  }
}

