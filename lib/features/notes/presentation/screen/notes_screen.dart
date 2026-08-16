import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' show Document;
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/note_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/state/stream_builder_widget.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/scoped_screen.dart';
import '../../../projects/domain/repository/projects_repository.dart';
import '../../domain/controller/notes_controller.dart';
import '../dialogs/note_editor_dialog.dart';
import '../dialogs/project_picker_dialog.dart';

class NotesScreen extends ScopedScreen {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ScopedScreenState<NotesScreen> {
  late final NotesController _controller;
  late final ProjectsRepository _projectsRepo;
  List<ProjectModel> _projects = [];

  @override
  void registerServices() {
    _controller = locator.get<NotesController>();
    _projectsRepo = locator.get<ProjectsRepository>();
  }

  @override
  void onReady() {
    _controller.load();
    _refreshProjects();
  }

  Future<void> _refreshProjects() async {
    final projects = await _projectsRepo.getAll();
    if (!mounted) return;
    setState(() => _projects = projects);
  }

  List<ProjectModel> _linkedProjects(String noteId) =>
      _projects.where((p) => p.noteId == noteId).toList();

  Future<void> _createNote() async {
    final note = await _controller.create();
    await _refreshProjects();
    if (!mounted) return;
    await _openEditor(note);
  }

  Future<void> _openEditor(NoteModel note) async {
    final json = await showDialog<String>(
      context: context,
      builder: (_) => NoteEditorDialog(note: note),
    );
    if (json == null) return;
    await _controller.update(note.copyWith(noteJson: json, updatedAt: DateTime.now()));
  }

  Future<void> _deleteNote(NoteModel note) async {
    final confirmed = await _confirmDelete();
    if (!confirmed) return;
    await _controller.delete(note.id);
    await _refreshProjects();
  }

  Future<bool> _confirmDelete() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppStyling.bgDark : AppStyling.bgLight,
        title: Text(
          'delete_note_',
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
            child: Text('delete', style: dmSans(size: 13, color: const Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _openLinkPicker(NoteModel note) async {
    final linkedIds = _linkedProjects(note.id).map((p) => p.id).toSet();
    final candidates = _projects.where((p) => !linkedIds.contains(p.id)).toList();
    final selected = await showDialog<ProjectModel>(
      context: context,
      builder: (_) => ProjectPickerDialog(candidates: candidates),
    );
    if (selected == null) return;
    await _projectsRepo.save(selected.copyWith(noteId: note.id));
    await _refreshProjects();
  }

  Future<void> _unlink(ProjectModel project) async {
    await _projectsRepo.unlinkNote(project.id);
    await _refreshProjects();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppStyling.bgDark : AppStyling.bgLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final accent = isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;

    return Scaffold(
      backgroundColor: bg,
      body: AsyncStreamBuilder<List<NoteModel>>(
        state: _controller.uiState,
        builder: (context, notes) {
          final sorted = [...notes]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '// all notes',
                        style: spaceMono(size: 10, color: textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                      _HeaderButton(
                        isDark: isDark,
                        accent: accent,
                        label: 'new_',
                        icon: Icons.add,
                        onTap: _createNote,
                      ),
                    ],
                  ),
                ),
              ),
              if (sorted.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyState(isDark: isDark, onCreateTap: _createNote),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppStyling.cardGap),
                    itemBuilder: (context, i) {
                      final note = sorted[i];
                      return _NoteCard(
                        note: note,
                        linkedProjects: _linkedProjects(note.id),
                        isDark: isDark,
                        onTap: () => _openEditor(note),
                        onDelete: () => _deleteNote(note),
                        onLink: () => _openLinkPicker(note),
                        onUnlink: (p) => _unlink(p),
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loadingBuilder: (context) => const Center(
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
        errorBuilder: (context, msg) => Center(
          child: Text('error: $msg', style: spaceMono(size: 11, color: textMuted)),
        ),
      ),
    );
  }
}

class _NoteCard extends StatefulWidget {
  final NoteModel note;
  final List<ProjectModel> linkedProjects;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onLink;
  final ValueChanged<ProjectModel> onUnlink;

  const _NoteCard({
    required this.note,
    required this.linkedProjects,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
    required this.onLink,
    required this.onUnlink,
  });

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _hovered = false;

  String _preview() {
    if (widget.note.noteJson.isEmpty) return 'empty note_';
    try {
      final doc = Document.fromJson(jsonDecode(widget.note.noteJson) as List);
      final text = doc.toPlainText().trim();
      return text.isEmpty ? 'empty note_' : text;
    } catch (_) {
      return 'empty note_';
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = widget.isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight;
    final borderColor = widget.isDark ? AppStyling.borderDark : AppStyling.borderLightStrong;
    final textPrimary = widget.isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted = widget.isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final accent = widget.isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;

    final preview = _preview();
    final snippet = preview.length > 140 ? '${preview.substring(0, 140)}…' : preview;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onTap,
                    behavior: HitTestBehavior.opaque,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Text(
                        snippet,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: dmSans(size: 13, color: textPrimary),
                      ),
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: _hovered ? 1.0 : 0.6,
                  duration: const Duration(milliseconds: 120),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _IconAction(
                        icon: Icons.link,
                        tooltip: 'link to project',
                        isDark: widget.isDark,
                        onTap: widget.onLink,
                      ),
                      _IconAction(
                        icon: Icons.delete_outline,
                        tooltip: 'delete',
                        isDark: widget.isDark,
                        color: const Color(0xFFEF4444),
                        onTap: widget.onDelete,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (widget.linkedProjects.isEmpty)
              Text(
                'unlinked_',
                style: spaceMono(size: 10, color: textMuted),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.linkedProjects
                    .map((p) => _ProjectChip(
                          project: p,
                          isDark: widget.isDark,
                          accent: accent,
                          onUnlink: () => widget.onUnlink(p),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectChip extends StatelessWidget {
  final ProjectModel project;
  final bool isDark;
  final Color accent;
  final VoidCallback onUnlink;

  const _ProjectChip({
    required this.project,
    required this.isDark,
    required this.accent,
    required this.onUnlink,
  });

  Color get _projectColor =>
      Color(int.parse(project.colorHex.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      decoration: BoxDecoration(
        color: _projectColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _projectColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _projectColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            project.name,
            style: spaceMono(size: 10, weight: FontWeight.w700, color: _projectColor),
          ),
          const SizedBox(width: 2),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onUnlink,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(Icons.close, size: 11, color: _projectColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final Color? color;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
    this.color,
  });

  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.color ??
        (widget.isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight);
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: _hovered ? base.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 14, color: base),
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatefulWidget {
  final bool isDark;
  final Color accent;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.isDark,
    required this.accent,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered ? widget.accent.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.isDark ? AppStyling.borderDark : AppStyling.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 13, color: widget.accent),
              const SizedBox(width: 5),
              Text(widget.label, style: spaceMono(size: 10, color: widget.accent)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onCreateTap;

  const _EmptyState({required this.isDark, required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
      child: Column(
        children: [
          Text('no_notes_found', style: spaceMono(size: 12, color: textMuted)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onCreateTap,
            child: Text(
              '+ create your first note',
              style: dmSans(
                size: 13,
                color: isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
