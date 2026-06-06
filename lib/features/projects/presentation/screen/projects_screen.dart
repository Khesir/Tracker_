import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/session_model.dart';
import '../../../../core/state/stream_builder_widget.dart';
import '../../../../core/state/stream_state.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/scoped_screen.dart';
import '../../../sessions/domain/controller/sessions_controller.dart';
import '../../../timer/domain/controller/timer_controller.dart';
import '../../domain/controller/projects_controller.dart';
import '../dialogs/project_form_dialog.dart';
import '../widget/active_session_header_widget.dart';
import '../widget/project_card_widget.dart';
import '../widget/stat_card_widget.dart';

class ProjectsScreen extends ScopedScreen {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ScopedScreenState<ProjectsScreen> {
  late final ProjectsController _controller;
  late final SessionsController _sessions;
  late final TimerController _timer;

  @override
  void registerServices() {
    _controller = locator.get<ProjectsController>();
    _sessions = locator.get<SessionsController>();
    _timer = locator.get<TimerController>();
  }

  @override
  void onReady() {
    _controller.load();
    _sessions.load();
  }

  Future<void> _openCreateDialog() async {
    final result = await showDialog<({String name, String colorHex, int? targetMinutes})>(
      context: context,
      builder: (_) => const ProjectFormDialog(),
    );
    if (result == null) return;
    await _controller.create(
      name: result.name,
      colorHex: result.colorHex,
      targetMinutes: result.targetMinutes,
    );
  }

  Future<void> _startSession(ProjectModel project) async {
    await _timer.start(projectId: project.id, projectName: project.name);
    _controller.load();
  }

  // ── metric helpers ────────────────────────────────────────────────────────

  Map<String, int> _perProjectSeconds(List<SessionModel> sessions) {
    final map = <String, int>{};
    for (final s in sessions) {
      map[s.projectId] = (map[s.projectId] ?? 0) + s.durationSeconds;
    }
    return map;
  }

  int _todaySeconds(List<SessionModel> sessions) {
    final now = DateTime.now();
    return sessions
        .where((s) =>
            s.startedAt.year == now.year &&
            s.startedAt.month == now.month &&
            s.startedAt.day == now.day)
        .fold(0, (acc, s) => acc + s.durationSeconds);
  }

  int _weeklySeconds(List<SessionModel> sessions) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final cutoff = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return sessions
        .where((s) => s.startedAt.isAfter(cutoff))
        .fold(0, (acc, s) => acc + s.durationSeconds);
  }

  int _streak(List<SessionModel> sessions) {
    if (sessions.isEmpty) return 0;
    final days = sessions
        .map((s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day))
        .toSet();
    final now = DateTime.now();
    var check = DateTime(now.year, now.month, now.day);
    var count = 0;
    while (days.contains(check)) {
      count++;
      check = check.subtract(const Duration(days: 1));
    }
    return count;
  }

  String _topProject(
    List<SessionModel> sessions,
    List<ProjectModel> projects,
  ) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final cutoff = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final weekly = sessions.where((s) => s.startedAt.isAfter(cutoff));
    final map = <String, int>{};
    for (final s in weekly) {
      map[s.projectId] = (map[s.projectId] ?? 0) + s.durationSeconds;
    }
    if (map.isEmpty) return '—';
    final topId = map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return projects.firstWhere((p) => p.id == topId, orElse: () => projects.first).name;
  }

  String _fmtHours(int seconds) {
    if (seconds == 0) return '0h';
    final h = seconds / 3600;
    if (h >= 1) return '${h.toStringAsFixed(1)}h';
    final m = seconds ~/ 60;
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppStyling.bgDark : AppStyling.bgLight;
    final textMuted = isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final accent = isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          const ActiveSessionHeaderWidget(),
          Expanded(
            child: StreamStateBuilder<AsyncState<List<SessionModel>>>(
              state: _sessions.uiState,
              builder: (context, sessionsState) {
                final sessions = sessionsState is AsyncData<List<SessionModel>>
                    ? sessionsState.data
                    : <SessionModel>[];
                final perProject = _perProjectSeconds(sessions);
                final todaySec = _todaySeconds(sessions);
                final weeklySec = _weeklySeconds(sessions);
                final streakDays = _streak(sessions);

                return AsyncStreamBuilder<List<ProjectModel>>(
                  state: _controller.uiState,
                  builder: (context, projects) {
                    final active = projects.where((p) => !p.isArchived).toList();
                    final top = projects.isNotEmpty
                        ? _topProject(sessions, projects)
                        : '—';

                    return CustomScrollView(
                      slivers: [
                        // // projects header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '// projects',
                                    style: spaceMono(size: 10, color: textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Spacer(),
                                _NewProjectButton(
                                  isDark: isDark,
                                  accent: accent,
                                  onTap: _openCreateDialog,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // project cards or empty state
                        if (active.isEmpty)
                          SliverToBoxAdapter(
                            child: _EmptyState(
                              isDark: isDark,
                              onCreateTap: _openCreateDialog,
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverList.separated(
                              itemCount: active.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppStyling.cardGap),
                              itemBuilder: (context, i) {
                                final project = active[i];
                                final isActive =
                                    _timer.uiState.state.isRunning &&
                                    _timer.uiState.state.projectId == project.id;
                                return ProjectCardWidget(
                                  project: project,
                                  loggedSeconds: perProject[project.id] ?? 0,
                                  isActive: isActive,
                                  onTap: () {},
                                  onStart: () => _startSession(project),
                                );
                              },
                            ),
                          ),

                        // // metrics header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                            child: Text(
                              '// metrics',
                              style: spaceMono(size: 10, color: textMuted),
                            ),
                          ),
                        ),

                        // 2x2 stat grid
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: StatCardWidget(
                                        value: _fmtHours(todaySec),
                                        label: 'today',
                                        highlighted: todaySec > 0,
                                      ),
                                    ),
                                    const SizedBox(width: AppStyling.cardGap),
                                    Expanded(
                                      child: StatCardWidget(
                                        value: _fmtHours(weeklySec),
                                        label: 'this week',
                                        highlighted: weeklySec > 0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppStyling.cardGap),
                                Row(
                                  children: [
                                    Expanded(
                                      child: StatCardWidget(
                                        value: streakDays > 0
                                            ? '${streakDays}d'
                                            : '—',
                                        label: 'streak',
                                        highlighted: streakDays > 1,
                                      ),
                                    ),
                                    const SizedBox(width: AppStyling.cardGap),
                                    Expanded(
                                      child: StatCardWidget(
                                        value: top,
                                        label: 'top project',
                                        highlighted: top != '—',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loadingBuilder: (context) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                  errorBuilder: (context, msg) => Center(
                    child: Text(
                      'error: $msg',
                      style: spaceMono(size: 11, color: textMuted),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NewProjectButton extends StatefulWidget {
  final bool isDark;
  final Color accent;
  final VoidCallback onTap;

  const _NewProjectButton({
    required this.isDark,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_NewProjectButton> createState() => _NewProjectButtonState();
}

class _NewProjectButtonState extends State<_NewProjectButton> {
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
            color: _hovered
                ? widget.accent.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.isDark
                  ? AppStyling.borderDark
                  : AppStyling.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 13, color: widget.accent),
              const SizedBox(width: 5),
              Text('new_', style: spaceMono(size: 10, color: widget.accent)),
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
    final textMuted =
        isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
      child: Column(
        children: [
          Text('no_projects_found',
              style: spaceMono(size: 12, color: textMuted)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onCreateTap,
            child: Text(
              '+ create your first project',
              style: dmSans(
                size: 13,
                color: isDark
                    ? AppStyling.accentPrimaryDark
                    : AppStyling.accentLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
