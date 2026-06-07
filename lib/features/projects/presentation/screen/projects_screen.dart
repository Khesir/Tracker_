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
import '../../../settings/domain/controller/settings_controller.dart';
import '../../../timer/domain/controller/timer_controller.dart';
import '../../domain/controller/projects_controller.dart';
import '../dialogs/project_form_dialog.dart';
import '../widget/project_card_widget.dart';
import '../widget/project_detail_drawer.dart';

class ProjectsScreen extends ScopedScreen {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ScopedScreenState<ProjectsScreen> {
  late final ProjectsController _controller;
  late final SessionsController _sessions;
  late final TimerController _timer;
  late final SettingsController _settings;

  @override
  void registerServices() {
    _controller = locator.get<ProjectsController>();
    _sessions = locator.get<SessionsController>();
    _timer = locator.get<TimerController>();
    _settings = locator.get<SettingsController>();
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

  int _todaySecondsForProject(String projectId, List<SessionModel> sessions) {
    final now = DateTime.now();
    return sessions
        .where((s) =>
            s.projectId == projectId &&
            s.startedAt.year == now.year &&
            s.startedAt.month == now.month &&
            s.startedAt.day == now.day)
        .fold(0, (acc, s) => acc + s.durationSeconds);
  }

  int _thisYearSeconds(List<SessionModel> sessions) {
    final year = DateTime.now().year;
    return sessions
        .where((s) => s.startedAt.year == year)
        .fold(0, (acc, s) => acc + s.durationSeconds);
  }

  String _topProject(
    List<SessionModel> sessions,
    List<ProjectModel> projects,
  ) {
    final map = <String, int>{};
    for (final s in sessions) {
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
          Expanded(
            child: StreamStateBuilder<AsyncState<List<SessionModel>>>(
              state: _sessions.uiState,
              builder: (context, sessionsState) {
                final sessions = sessionsState is AsyncData<List<SessionModel>>
                    ? sessionsState.data
                    : <SessionModel>[];
                final perProject = _perProjectSeconds(sessions);
                final todaySec = _todaySeconds(sessions);
                final yearSec = _thisYearSeconds(sessions);

                return AsyncStreamBuilder<List<ProjectModel>>(
                  state: _controller.uiState,
                  builder: (context, projects) {
                    final active = projects.where((p) => !p.isDeleted).toList();
                    final top = projects.isNotEmpty
                        ? _topProject(sessions, projects)
                        : '—';

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth < 80) {
                                  return const SizedBox.shrink();
                                }
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '// all projects',
                                      style: spaceMono(size: 10, color: textMuted),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _HeaderButton(
                                          isDark: isDark,
                                          accent: accent,
                                          label: 'import_',
                                          icon: Icons.upload_outlined,
                                          onTap: () {},
                                        ),
                                        const SizedBox(width: 6),
                                        _HeaderButton(
                                          isDark: isDark,
                                          accent: accent,
                                          label: 'new_',
                                          icon: Icons.add,
                                          onTap: _openCreateDialog,
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _StatCard(
                                    value: _fmtHours(todaySec),
                                    label: 'today',
                                    isDark: isDark,
                                    isHot: true,
                                  ),
                                ),
                                const SizedBox(width: AppStyling.cardGap),
                                Expanded(
                                  child: _StatCard(
                                    value: _fmtHours(yearSec),
                                    label: 'this year',
                                    isDark: isDark,
                                    isHot: false,
                                  ),
                                ),
                                const SizedBox(width: AppStyling.cardGap),
                                Expanded(
                                  child: _StatCard(
                                    value: '${active.length}',
                                    label: 'projects',
                                    isDark: isDark,
                                    isHot: false,
                                    hideUnit: true,
                                  ),
                                ),
                                const SizedBox(width: AppStyling.cardGap),
                                Expanded(
                                  child: _StatCard(
                                    value: top,
                                    label: 'top project',
                                    isDark: isDark,
                                    isHot: false,
                                    hideUnit: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: Text(
                              '// tracked',
                              style: spaceMono(size: 10, color: textMuted),
                            ),
                          ),
                        ),

                        if (active.isEmpty)
                          SliverToBoxAdapter(
                            child: _EmptyState(
                              isDark: isDark,
                              onCreateTap: _openCreateDialog,
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                                  todaySeconds:
                                      _todaySecondsForProject(project.id, sessions),
                                  isActive: isActive,
                                  onTap: () => ProjectDetailDrawer.show(
                                    context,
                                    project: project,
                                    sessionsController: _sessions,
                                    projectsController: _controller,
                                    timerController: _timer,
                                    isActive: isActive,
                                    drawerStyle:
                                        _settings.current?.projectDrawerStyle ?? 'side',
                                  ),
                                  onStart: () => _startSession(project),
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

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;
  final bool isHot;
  final bool hideUnit;

  const _StatCard({
    required this.value,
    required this.label,
    required this.isDark,
    required this.isHot,
    this.hideUnit = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppStyling.borderDark : AppStyling.borderLightStrong;
    final bg = isHot
        ? (isDark ? AppStyling.accentDimDark : AppStyling.accentDimLight)
        : Colors.transparent;
    final valueColor = isHot
        ? (isDark ? AppStyling.accentInkDark : AppStyling.accentInkLight)
        : (isDark ? AppStyling.textPrimaryDark : AppStyling.textPrimaryLight);
    final labelColor = isHot
        ? (isDark ? AppStyling.accentInkDark : AppStyling.accentInkLight).withValues(alpha: 0.8)
        : (isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight);

    String mainValue = value;
    String unit = '';
    if (!hideUnit && value.isNotEmpty) {
      if (value.endsWith('h')) {
        mainValue = value.substring(0, value.length - 1);
        unit = 'h';
      } else if (value.endsWith('m')) {
        mainValue = value.substring(0, value.length - 1);
        unit = 'm';
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: mainValue,
                  style: spaceMono(
                    size: 21,
                    weight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: spaceMono(
                      size: 13,
                      weight: FontWeight.w400,
                      color: valueColor.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: spaceMono(size: 10, color: labelColor),
          ),
        ],
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
