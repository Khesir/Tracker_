import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/note_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/session_model.dart';
import '../../../../core/state/stream_builder_widget.dart';
import '../../../../core/state/stream_state.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../notes/domain/repository/notes_repository.dart';
import '../../../sessions/domain/controller/sessions_controller.dart';
import '../../../sessions/presentation/sheets/session_detail_sheet.dart';
import '../../../timer/domain/controller/timer_controller.dart';
import '../../../timer/presentation/state/timer_ui_state.dart';
import '../../../timer/presentation/widget/session_note_widget.dart';
import '../../domain/controller/projects_controller.dart';
import '../dialogs/project_form_dialog.dart';

const _kSidePanelWidth = 380.0;
const _kRecentSessionsLimit = 5;

class ProjectDetailDrawer extends StatelessWidget {
  final ProjectModel project;
  final SessionsController sessionsController;
  final ProjectsController projectsController;
  final TimerController timerController;
  final NotesRepository notesRepository;

  const ProjectDetailDrawer({
    super.key,
    required this.project,
    required this.sessionsController,
    required this.projectsController,
    required this.timerController,
    required this.notesRepository,
  });

  static Future<void> show(
    BuildContext context, {
    required ProjectModel project,
    required SessionsController sessionsController,
    required ProjectsController projectsController,
    required TimerController timerController,
    required NotesRepository notesRepository,
    required String drawerStyle,
  }) {
    final content = ProjectDetailDrawer(
      project: project,
      sessionsController: sessionsController,
      projectsController: projectsController,
      timerController: timerController,
      notesRepository: notesRepository,
    );

    if (drawerStyle == 'bottom') {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => content,
      );
    }

    return showGeneralDialog(
      context: context,
      barrierLabel: 'project_detail_',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => content,
      transitionBuilder: (_, animation, __, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: offset,
          child: Align(alignment: Alignment.centerRight, child: child),
        );
      },
    );
  }

  Color get _projectColor =>
      Color(int.parse(project.colorHex.replaceFirst('#', '0xFF')));

  List<SessionModel> _projectSessions() {
    final sessionsState = sessionsController.uiState.state;
    final sessions = sessionsState is AsyncData<List<SessionModel>>
        ? sessionsState.data
        : <SessionModel>[];
    return sessions.where((s) => s.projectId == project.id).toList();
  }

  int _totalSeconds(List<SessionModel> sessions) =>
      sessions.fold(0, (acc, s) => acc + s.durationSeconds);

  int _todaySeconds(List<SessionModel> sessions) {
    final now = DateTime.now();
    return sessions
        .where((s) =>
            s.startedAt.year == now.year &&
            s.startedAt.month == now.month &&
            s.startedAt.day == now.day)
        .fold(0, (acc, s) => acc + s.durationSeconds);
  }

  String _fmtDuration(int seconds) {
    if (seconds == 0) return '0m';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  Future<void> _startSession(BuildContext context) async {
    await timerController.start(projectId: project.id, projectName: project.name);
    projectsController.load();
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _stopSession(BuildContext context) async {
    await timerController.stop();
    projectsController.load();
    if (context.mounted) Navigator.pop(context);
  }

  // Pause/resume neither change persisted totals nor end the session, so
  // unlike start/stop they don't reload ProjectsController or close the
  // drawer — the drawer just re-renders with the new TimerStatus.
  Future<void> _pauseSession() async {
    await timerController.pause();
  }

  Future<void> _resumeSession() async {
    await timerController.unpause();
  }

  Future<void> _editProject(BuildContext context) async {
    final result = await showDialog<({String name, String colorHex, int? targetMinutes})>(
      context: context,
      builder: (_) => ProjectFormDialog(existing: project),
    );
    if (result == null) return;
    await projectsController.update(project.copyWith(
      name: result.name,
      colorHex: result.colorHex,
      targetMinutes: result.targetMinutes,
    ));
  }

  Future<void> _deleteProject(BuildContext context, {required bool isDark, required Color textMuted}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppStyling.bgDark : AppStyling.bgLight,
        title: Text(
          'delete_project_',
          style: spaceMono(
            size: 13,
            weight: FontWeight.w700,
            color: isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight,
          ),
        ),
        content: Text(
          'this action cannot be undone.',
          style: dmSans(size: AppStyling.bodySize, color: textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel', style: dmSans(size: 13, color: textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'delete',
              style: dmSans(size: 13, color: const Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await projectsController.softDelete(project.id);
    if (context.mounted) Navigator.pop(context);
  }

  void _openSession(BuildContext context, SessionModel session) {
    SessionDetailSheet.show(
      context,
      session: session,
      projectName: project.name,
      onSave: (updated) => sessionsController.update(updated),
      onDelete: () => sessionsController.delete(session.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppStyling.bgDark : AppStyling.bgLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textPrimary = isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;

    final sessions = _projectSessions();
    final totalSeconds = _totalSeconds(sessions);
    final todaySeconds = _todaySeconds(sessions);
    final recent = [...sessions]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final recentSessions = recent.take(_kRecentSessionsLimit).toList();

    final body = _DrawerBody(
      project: project,
      projectColor: _projectColor,
      timerController: timerController,
      totalSeconds: totalSeconds,
      todaySeconds: todaySeconds,
      recentSessions: recentSessions,
      isDark: isDark,
      bg: bg,
      border: border,
      textPrimary: textPrimary,
      textMuted: textMuted,
      fmtDuration: _fmtDuration,
      onSessionTap: (session) => _openSession(context, session),
      onStart: () => _startSession(context),
      onStop: () => _stopSession(context),
      onPause: () => _pauseSession(),
      onResume: () => _resumeSession(),
      onEdit: () => _editProject(context),
      onDelete: () => _deleteProject(context, isDark: isDark, textMuted: textMuted),
      notesRepository: notesRepository,
      projectsController: projectsController,
    );

    return SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: _kSidePanelWidth,
            height: double.infinity,
            decoration: BoxDecoration(
              color: bg,
              border: Border(left: BorderSide(color: border)),
            ),
            child: body,
          ),
        ),
      ),
    );
  }
}

class _DrawerBody extends StatelessWidget {
  final ProjectModel project;
  final Color projectColor;
  final TimerController timerController;
  final int totalSeconds;
  final int todaySeconds;
  final List<SessionModel> recentSessions;
  final bool isDark;
  final Color bg;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final String Function(int) fmtDuration;
  final ValueChanged<SessionModel> onSessionTap;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final NotesRepository notesRepository;
  final ProjectsController projectsController;

  const _DrawerBody({
    required this.project,
    required this.projectColor,
    required this.timerController,
    required this.totalSeconds,
    required this.todaySeconds,
    required this.recentSessions,
    required this.isDark,
    required this.bg,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.fmtDuration,
    required this.onSessionTap,
    required this.onStart,
    required this.onStop,
    required this.onPause,
    required this.onResume,
    required this.onEdit,
    required this.onDelete,
    required this.notesRepository,
    required this.projectsController,
  });

  @override
  Widget build(BuildContext context) {
    final targetSecs = (project.targetMinutes ?? 0) * 60;
    final hasTarget = targetSecs > 0;
    final progress = hasTarget ? (todaySeconds / targetSecs).clamp(0.0, 1.0) : 0.0;
    final progressBg = isDark ? AppStyling.borderDark : const Color(0xFFEEF0F2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: projectColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  project.name,
                  style: spaceMono(size: 16, weight: FontWeight.w700, color: textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _DrawerOverflowMenu(
                isDark: isDark,
                bg: bg,
                border: border,
                textMuted: textMuted,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, size: 18, color: textMuted),
              ),
            ],
          ),
        ),
        Divider(color: border, height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('// total logged', style: spaceMono(size: 10, color: textMuted)),
                const SizedBox(height: 8),
                Text(
                  fmtDuration(totalSeconds),
                  style: spaceMono(size: 22, weight: FontWeight.w800, color: textPrimary),
                ),
                if (hasTarget) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('// today vs. daily target', style: spaceMono(size: 10, color: textMuted)),
                      Text(
                        '${fmtDuration(todaySeconds)} / ${fmtDuration(targetSecs)}',
                        style: spaceMono(size: 10, color: textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: progressBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              colors: [
                                Color.lerp(projectColor, Colors.white, 0.4)!,
                                projectColor,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Text('// recent sessions', style: spaceMono(size: 10, color: textMuted)),
                const SizedBox(height: 12),
                if (recentSessions.isEmpty)
                  Text(
                    'no_sessions_yet',
                    style: dmSans(size: AppStyling.bodySize, color: textMuted.withValues(alpha: 0.5)),
                  )
                else
                  ...recentSessions.map(
                    (session) => _RecentSessionRow(
                      session: session,
                      isDark: isDark,
                      border: border,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      fmtDuration: fmtDuration,
                      onTap: () => onSessionTap(session),
                    ),
                  ),
                const SizedBox(height: 28),
                Text('// linked note', style: spaceMono(size: 10, color: textMuted)),
                const SizedBox(height: 12),
                _NoteSection(
                  key: ValueKey('note-section-${project.id}'),
                  project: project,
                  notesRepository: notesRepository,
                  projectsController: projectsController,
                  isDark: isDark,
                  border: border,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: border))),
          // Reactive on TimerController.uiState so pause/resume/stop (which
          // don't pop the drawer or reload ProjectsController) still flip
          // this row's button set live, with no stale label.
          child: StreamStateBuilder<TimerUiData>(
            state: timerController.uiState,
            builder: (context, data) {
              final isRunningHere = data.isRunning && data.projectId == project.id;
              final isPausedHere = data.isPaused && data.projectId == project.id;

              if (isPausedHere) {
                return Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'stop_session_',
                        isDark: isDark,
                        onTap: onStop,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: 'resume_session_',
                        isDark: isDark,
                        onTap: onResume,
                      ),
                    ),
                  ],
                );
              }

              if (isRunningHere) {
                return Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'stop_session_',
                        isDark: isDark,
                        onTap: onStop,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: 'pause_session_',
                        isDark: isDark,
                        onTap: onPause,
                      ),
                    ),
                  ],
                );
              }

              return SizedBox(
                width: double.infinity,
                child: _ActionButton(
                  label: 'start_session_',
                  isDark: isDark,
                  onTap: onStart,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Triple-dot overflow menu in the drawer header, replacing the old
/// full-width edit_/delete_ rows that used to live in the bottom action
/// area. Reuses the drawer's existing onEdit/onDelete callbacks unchanged.
class _DrawerOverflowMenu extends StatelessWidget {
  final bool isDark;
  final Color bg;
  final Color border;
  final Color textMuted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DrawerOverflowMenu({
    required this.isDark,
    required this.bg,
    required this.border,
    required this.textMuted,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;

    return PopupMenuButton<String>(
      tooltip: '',
      color: bg,
      elevation: 4,
      padding: EdgeInsets.zero,
      splashRadius: 16,
      offset: const Offset(0, 22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: border),
      ),
      icon: Icon(Icons.more_vert, size: 18, color: textMuted),
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'edit',
          height: 36,
          child: Text('edit_', style: spaceMono(size: 12, color: accent)),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          height: 36,
          child: Text('delete_', style: spaceMono(size: 12, color: const Color(0xFFEF4444))),
        ),
      ],
    );
  }
}

class _RecentSessionRow extends StatefulWidget {
  final SessionModel session;
  final bool isDark;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final String Function(int) fmtDuration;
  final VoidCallback onTap;

  const _RecentSessionRow({
    required this.session,
    required this.isDark,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.fmtDuration,
    required this.onTap,
  });

  @override
  State<_RecentSessionRow> createState() => _RecentSessionRowState();
}

class _RecentSessionRowState extends State<_RecentSessionRow> {
  bool _hovered = false;

  String _fmtDate(DateTime dt) {
    final months = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
    ];
    final d = dt.day.toString().padLeft(2, '0');
    final mo = months[dt.month - 1];
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d $mo — $h:$mi';
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
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? widget.border.withValues(alpha: 0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _fmtDate(widget.session.startedAt),
                  style: dmSans(size: AppStyling.labelSize, color: widget.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                widget.fmtDuration(widget.session.durationSeconds),
                style: spaceMono(size: 11, weight: FontWeight.w700, color: widget.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final border = widget.isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final accent = widget.isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;
    final disabled = widget.onTap == null;

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: !disabled && _hovered ? accent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: spaceMono(size: 11, color: disabled ? accent.withValues(alpha: 0.4) : accent),
          ),
        ),
      ),
    );
  }
}

/// The drawer's "linked note" block. Keeps its own local view of the
/// project's `noteId` (seeded from [ProjectModel.noteId]) so link/unlink/
/// create actions reflect immediately via `setState`, without waiting on
/// the drawer being closed/reopened or on [ProjectsController]'s async
/// stream to settle.
class _NoteSection extends StatefulWidget {
  final ProjectModel project;
  final NotesRepository notesRepository;
  final ProjectsController projectsController;
  final bool isDark;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  const _NoteSection({
    super.key,
    required this.project,
    required this.notesRepository,
    required this.projectsController,
    required this.isDark,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  State<_NoteSection> createState() => _NoteSectionState();
}

class _NoteSectionState extends State<_NoteSection> {
  String? _noteId;
  NoteModel? _note;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _noteId = widget.project.noteId;
    _loadNote();
  }

  Future<void> _loadNote() async {
    if (_noteId == null) {
      setState(() {
        _note = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final note = await widget.notesRepository.getById(_noteId!);
    if (!mounted) return;
    setState(() {
      _note = note;
      _loading = false;
    });
  }

  Future<void> _unlink() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.projectsController.unlinkNote(widget.project.id);
    if (!mounted) return;
    setState(() {
      _noteId = null;
      _note = null;
      _busy = false;
    });
  }

  Future<void> _createAndLink() async {
    if (_busy) return;
    setState(() => _busy = true);
    final now = DateTime.now();
    final note = NoteModel(
      id: const Uuid().v4(),
      noteJson: '',
      createdAt: now,
      updatedAt: now,
    );
    await widget.notesRepository.save(note);
    await widget.projectsController.update(widget.project.copyWith(noteId: note.id));
    if (!mounted) return;
    setState(() {
      _noteId = note.id;
      _note = note;
      _loading = false;
      _busy = false;
    });
  }

  Future<void> _linkExisting() async {
    if (_busy) return;
    final selected = await showDialog<NoteModel>(
      context: context,
      builder: (_) => _LinkExistingNoteDialog(
        notesRepository: widget.notesRepository,
        projectsController: widget.projectsController,
        isDark: widget.isDark,
      ),
    );
    if (selected == null) return;
    setState(() => _busy = true);
    await widget.projectsController.update(widget.project.copyWith(noteId: selected.id));
    if (!mounted) return;
    setState(() {
      _noteId = selected.id;
      _note = selected;
      _loading = false;
      _busy = false;
    });
  }

  Future<void> _saveNoteJson(String json) async {
    final current = _note;
    if (current == null) return;
    final updated = current.copyWith(noteJson: json, updatedAt: DateTime.now());
    _note = updated;
    await widget.notesRepository.save(updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }

    if (_noteId == null || _note == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'no_note_linked',
            style: dmSans(size: AppStyling.bodySize, color: widget.textMuted.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _NoteChipButton(
                label: 'create_new_',
                isDark: widget.isDark,
                onTap: _busy ? null : _createAndLink,
              ),
              const SizedBox(width: 8),
              _NoteChipButton(
                label: 'link_existing_',
                isDark: widget.isDark,
                onTap: _busy ? null : _linkExisting,
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: widget.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            height: 220,
            child: SessionNoteWidget(
              key: ValueKey('note-editor-${_note!.id}'),
              initialNoteJson: _note!.noteJson,
              onChanged: _saveNoteJson,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: _NoteChipButton(
            label: 'unlink_',
            isDark: widget.isDark,
            isDestructive: true,
            onTap: _busy ? null : _unlink,
          ),
        ),
      ],
    );
  }
}

class _NoteChipButton extends StatefulWidget {
  final String label;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _NoteChipButton({
    required this.label,
    required this.isDark,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_NoteChipButton> createState() => _NoteChipButtonState();
}

class _NoteChipButtonState extends State<_NoteChipButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final border = widget.isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final accent = widget.isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;
    final color = widget.isDestructive ? const Color(0xFFEF4444) : accent;
    final disabled = widget.onTap == null;

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: !disabled && _hovered ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border),
          ),
          child: Text(
            widget.label,
            style: spaceMono(size: 10, color: disabled ? color.withValues(alpha: 0.4) : color),
          ),
        ),
      ),
    );
  }
}

/// Picker over notes that no live project currently points at — freshly
/// re-derived on open from [ProjectsController] + [NotesRepository] rather
/// than stored on [NoteModel], since a note carries no project reference of
/// its own.
class _LinkExistingNoteDialog extends StatefulWidget {
  final NotesRepository notesRepository;
  final ProjectsController projectsController;
  final bool isDark;

  const _LinkExistingNoteDialog({
    required this.notesRepository,
    required this.projectsController,
    required this.isDark,
  });

  @override
  State<_LinkExistingNoteDialog> createState() => _LinkExistingNoteDialogState();
}

class _LinkExistingNoteDialogState extends State<_LinkExistingNoteDialog> {
  bool _loading = true;
  List<NoteModel> _unlinked = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.projectsController.load();
    final allNotes = await widget.notesRepository.getAll();
    final allProjects = widget.projectsController.uiState.data ?? const <ProjectModel>[];
    final linkedIds = allProjects.map((p) => p.noteId).whereType<String>().toSet();
    final unlinked = allNotes.where((n) => !linkedIds.contains(n.id)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (!mounted) return;
    setState(() {
      _unlinked = unlinked;
      _loading = false;
    });
  }

  String _preview(NoteModel note) {
    if (note.noteJson.isEmpty) return '(empty note)';
    try {
      final delta = jsonDecode(note.noteJson) as List;
      final text = Document.fromJson(delta).toPlainText().trim();
      return text.isEmpty ? '(empty note)' : text;
    } catch (_) {
      return '(empty note)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppStyling.bgDark : AppStyling.bgLight;
    final border = widget.isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textPrimary = widget.isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted = widget.isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;

    return AlertDialog(
      backgroundColor: bg,
      title: Text(
        'link_existing_note_',
        style: spaceMono(size: 13, weight: FontWeight.w700, color: textPrimary),
      ),
      content: SizedBox(
        width: 320,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
              )
            : _unlinked.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'no_unlinked_notes',
                      style: dmSans(size: AppStyling.bodySize, color: textMuted),
                    ),
                  )
                : SizedBox(
                    height: 260,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _unlinked.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: border),
                      itemBuilder: (context, i) {
                        final note = _unlinked[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _preview(note),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: dmSans(size: AppStyling.bodySize, color: textPrimary),
                          ),
                          onTap: () => Navigator.pop(context, note),
                        );
                      },
                    ),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel', style: dmSans(size: 13, color: textMuted)),
        ),
      ],
    );
  }
}
