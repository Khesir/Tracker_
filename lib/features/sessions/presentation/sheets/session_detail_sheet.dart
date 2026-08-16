import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/music_entry_model.dart';
import '../../../../core/models/note_model.dart';
import '../../../../core/models/session_model.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../notes/domain/repository/notes_repository.dart';

class SessionDetailSheet extends StatelessWidget {
  final SessionModel session;
  final String projectName;
  final Future<void> Function(SessionModel updated) onSave;
  final Future<void> Function() onDelete;

  const SessionDetailSheet({
    super.key,
    required this.session,
    required this.projectName,
    required this.onSave,
    required this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required SessionModel session,
    required String projectName,
    required Future<void> Function(SessionModel updated) onSave,
    required Future<void> Function() onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SessionDetailSheet(
        session: session,
        projectName: projectName,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  String _formatDateTime(DateTime dt) {
    final weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final months = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
    ];
    final wd = weekdays[dt.weekday - 1];
    final d = dt.day.toString().padLeft(2, '0');
    final mo = months[dt.month - 1];
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$wd, $d $mo — $h:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppStyling.bgDark : AppStyling.bgLight;
    final border = isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final textPrimary =
        isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight;
    final textMuted =
        isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final accent =
        isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;

    final hasMusicLog = session.musicLog.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        projectName,
                        style: spaceMono(
                          size: 13,
                          weight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatDateTime(session.startedAt),
                        style: dmSans(size: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppStyling.badgeRadius),
                  ),
                  child: Text(
                    _formatDuration(session.durationSeconds),
                    style: spaceMono(
                        size: 12, weight: FontWeight.w700, color: accent),
                  ),
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
                  // linked note section
                  Text('// linked_note', style: spaceMono(size: 10, color: textMuted)),
                  const SizedBox(height: 10),
                  _LinkedNoteSection(
                    noteId: session.noteId,
                    isDark: isDark,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    accent: accent,
                  ),

                  const SizedBox(height: 24),

                  // post-note section
                  Text('// post_note', style: spaceMono(size: 10, color: textMuted)),
                  const SizedBox(height: 10),
                  _PostNoteField(
                    session: session,
                    onSave: onSave,
                    isDark: isDark,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),

                  // music section
                  if (hasMusicLog) ...[
                    const SizedBox(height: 24),
                    Text(
                      '// music_log',
                      style: spaceMono(size: 10, color: textMuted),
                    ),
                    const SizedBox(height: 10),
                    ...session.musicLog.map(
                      (e) => _MusicLogRow(entry: e, textMuted: textMuted),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // actions
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'delete_',
                    isDark: isDark,
                    isDestructive: true,
                    onTap: () async {
                      final confirm = await _confirmDelete(context,
                          isDark: isDark, textMuted: textMuted);
                      if (confirm) {
                        await onDelete();
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context, {
    required bool isDark,
    required Color textMuted,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppStyling.bgDark : AppStyling.bgLight,
        title: Text(
          'delete_session_',
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
    return result ?? false;
  }
}

class _MusicLogRow extends StatelessWidget {
  final MusicEntryModel entry;
  final Color textMuted;

  const _MusicLogRow({required this.entry, required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.music_note_rounded, size: 11, color: textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${entry.artist} — ${entry.title}',
              style: dmSans(size: AppStyling.labelSize, color: textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.isDark,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final border = widget.isDark ? AppStyling.borderDark : AppStyling.borderLight;
    final accent = widget.isDark
        ? AppStyling.accentPrimaryDark
        : AppStyling.accentLight;
    final color =
        widget.isDestructive ? const Color(0xFFEF4444) : accent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: spaceMono(size: 11, color: color),
          ),
        ),
      ),
    );
  }
}

/// Read-only reference to the note linked to this session at start time
/// (via [SessionModel.noteId]). Fetches the [NoteModel] live by id on
/// build/id-change rather than trusting any frozen copy, so if the note is
/// edited elsewhere (Notes screen, project drawer, mini widget) this
/// reflects that. Editing does not happen here by design (per PRD) — tapping
/// only surfaces a hint to go edit it in the Notes screen. There is no
/// screen-index-aware navigation plumbing reachable from this deep in the
/// sessions feature without a larger shell refactor (see `lib/app.dart`
/// `_FullAppShellState`, which keeps `_selectedIndex` as private local
/// state), so a `SnackBar` hint is used as the deliberately simple fallback.
class _LinkedNoteSection extends StatefulWidget {
  final String? noteId;
  final bool isDark;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;

  const _LinkedNoteSection({
    required this.noteId,
    required this.isDark,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
  });

  @override
  State<_LinkedNoteSection> createState() => _LinkedNoteSectionState();
}

class _LinkedNoteSectionState extends State<_LinkedNoteSection> {
  bool _loading = true;
  NoteModel? _note;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _LinkedNoteSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noteId != widget.noteId) _load();
  }

  Future<void> _load() async {
    final id = widget.noteId;
    if (id == null) {
      setState(() {
        _note = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final note = await locator.get<NotesRepository>().getById(id);
    if (!mounted) return;
    setState(() {
      _note = note;
      _loading = false;
    });
  }

  String _preview(NoteModel note) {
    if (note.noteJson.isEmpty) return '';
    try {
      final delta = jsonDecode(note.noteJson) as List;
      return Document.fromJson(delta).toPlainText().trim();
    } catch (_) {
      return '';
    }
  }

  void _hintOpenNotesScreen(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: widget.isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight,
        content: Text(
          'open the notes screen to view or edit this note',
          style: dmSans(size: 12, color: widget.textMuted),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          height: 14,
          width: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }

    if (widget.noteId == null || _note == null) {
      return Text(
        'no_linked_note',
        style: dmSans(
            size: AppStyling.bodySize,
            color: widget.textMuted.withValues(alpha: 0.5)),
      );
    }

    final preview = _preview(_note!);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _hintOpenNotesScreen(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: widget.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.sticky_note_2_outlined, size: 13, color: widget.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  preview.isEmpty ? '(empty note)' : preview,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: dmSans(size: AppStyling.bodySize, color: widget.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optional, plain-text, directly-editable field for `SessionModel.postNote`.
/// Unlike the linked note above, this is private to the session and has no
/// rich-text formatting — a deliberate contrast per the PRD. Saves are
/// debounced (matching the 500ms debounce the old per-session rich-text
/// editor used) and go through the same `onSave` callback the rest of this
/// sheet already uses, which routes to `SessionsController.update()` ->
/// `SessionsRepository.save()`. Leaving it blank is valid; no validation.
class _PostNoteField extends StatefulWidget {
  final SessionModel session;
  final Future<void> Function(SessionModel updated) onSave;
  final bool isDark;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  const _PostNoteField({
    required this.session,
    required this.onSave,
    required this.isDark,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  State<_PostNoteField> createState() => _PostNoteFieldState();
}

class _PostNoteFieldState extends State<_PostNoteField> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.session.postNote ?? '');
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSave(widget.session.copyWith(postNote: value));
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
      controller: _controller,
      onChanged: _onChanged,
      minLines: 2,
      maxLines: 4,
      style: dmSans(size: AppStyling.bodySize, color: widget.textPrimary),
      cursorColor: widget.textPrimary,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'optional note, added after the session...',
        hintStyle: dmSans(
            size: AppStyling.bodySize,
            color: widget.textMuted.withValues(alpha: 0.5)),
        contentPadding: const EdgeInsets.all(10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.textMuted),
        ),
      ),
    );
  }
}
