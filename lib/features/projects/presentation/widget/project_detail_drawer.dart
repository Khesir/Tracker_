import 'package:flutter/material.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/session_model.dart';
import '../../../../core/state/stream_state.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../sessions/domain/controller/sessions_controller.dart';
import '../../../sessions/presentation/sheets/session_detail_sheet.dart';
import '../../../timer/domain/controller/timer_controller.dart';
import '../../domain/controller/projects_controller.dart';
import '../dialogs/project_form_dialog.dart';

const _kSidePanelWidth = 380.0;
const _kRecentSessionsLimit = 5;

class ProjectDetailDrawer extends StatelessWidget {
  final ProjectModel project;
  final SessionsController sessionsController;
  final ProjectsController projectsController;
  final TimerController timerController;
  final bool isActive;

  const ProjectDetailDrawer({
    super.key,
    required this.project,
    required this.sessionsController,
    required this.projectsController,
    required this.timerController,
    required this.isActive,
  });

  static Future<void> show(
    BuildContext context, {
    required ProjectModel project,
    required SessionsController sessionsController,
    required ProjectsController projectsController,
    required TimerController timerController,
    required bool isActive,
    required String drawerStyle,
  }) {
    final content = ProjectDetailDrawer(
      project: project,
      sessionsController: sessionsController,
      projectsController: projectsController,
      timerController: timerController,
      isActive: isActive,
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
      isActive: isActive,
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
      onEdit: () => _editProject(context),
      onDelete: () => _deleteProject(context, isDark: isDark, textMuted: textMuted),
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
  final bool isActive;
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DrawerBody({
    required this.project,
    required this.projectColor,
    required this.isActive,
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
    required this.onEdit,
    required this.onDelete,
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
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: border))),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: isActive ? 'session_active_' : 'start_session_',
                      isDark: isDark,
                      onTap: isActive ? null : onStart,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      label: 'edit_',
                      isDark: isDark,
                      onTap: onEdit,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: _ActionButton(
                  label: 'delete_',
                  isDark: isDark,
                  isDestructive: true,
                  onTap: onDelete,
                ),
              ),
            ],
          ),
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
  final bool isDestructive;
  final VoidCallback? onTap;

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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: !disabled && _hovered ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: spaceMono(size: 11, color: disabled ? color.withValues(alpha: 0.4) : color),
          ),
        ),
      ),
    );
  }
}
