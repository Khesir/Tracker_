import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/models/project_model.dart';
import '../../../../core/models/session_model.dart';
import '../../../../core/state/stream_builder_widget.dart';
import '../../../../core/state/stream_state.dart';
import '../../../../core/theme/app_styling.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/scoped_screen.dart';
import '../../../projects/domain/controller/projects_controller.dart';
import '../../domain/controller/sessions_controller.dart';
import '../sheets/session_detail_sheet.dart';
import '../widget/session_row_widget.dart';

class SessionsScreen extends ScopedScreen {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ScopedScreenState<SessionsScreen> {
  late final SessionsController _sessionsCtrl;
  late final ProjectsController _projectsCtrl;

  @override
  void registerServices() {
    _sessionsCtrl = locator.get<SessionsController>();
    _projectsCtrl = locator.get<ProjectsController>();
  }

  @override
  void onReady() {
    _sessionsCtrl.load();
    _projectsCtrl.load();
  }

  Map<String, String> _buildColorMap(List<ProjectModel> projects) =>
      {for (final p in projects) p.id: p.colorHex};

  Map<String, String> _buildNameMap(List<ProjectModel> projects) =>
      {for (final p in projects) p.id: p.name};

  Map<DateTime, List<SessionModel>> _groupByDay(List<SessionModel> sessions) {
    final map = <DateTime, List<SessionModel>>{};
    for (final s in sessions) {
      final day =
          DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      map.putIfAbsent(day, () => []).add(s);
    }
    return map;
  }

  String _formatDay(DateTime day) {
    const weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    const months = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
    ];
    final wd = weekdays[day.weekday - 1];
    final d = day.day.toString().padLeft(2, '0');
    final mo = months[day.month - 1];
    return '// $wd, $d $mo';
  }

  String _formatTotalDuration(List<SessionModel> sessions) {
    final total = sessions.fold(0, (acc, s) => acc + s.durationSeconds);
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  Future<void> _openDetail(
    BuildContext context,
    SessionModel session,
    Map<String, String> nameMap,
    Map<String, String> colorMap,
  ) async {
    await SessionDetailSheet.show(
      context,
      session: session,
      projectName: nameMap[session.projectId] ?? 'unknown',
      onSave: (updated) => _sessionsCtrl.update(updated),
      onDelete: () => _sessionsCtrl.delete(session.id),
    );
  }

  Future<void> _exportCsv(
    BuildContext context,
    Map<String, String> nameMap,
    bool isDark,
    Color textMuted,
  ) async {
    final path = await _sessionsCtrl.exportCsv(nameMap);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isDark ? AppStyling.surfaceDark : AppStyling.surfaceLight,
        content: Text(
          path != null ? 'saved to $path' : 'nothing to export',
          style: dmSans(size: 12, color: textMuted),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppStyling.bgDark : AppStyling.bgLight;
    final textMuted =
        isDark ? AppStyling.textMutedDark : AppStyling.textMutedLight;
    final accent =
        isDark ? AppStyling.accentPrimaryDark : AppStyling.accentLight;

    return Scaffold(
      backgroundColor: bg,
      body: StreamStateBuilder<AsyncState<List<ProjectModel>>>(
        state: _projectsCtrl.uiState,
        builder: (context, projectsState) {
          final projects = projectsState is AsyncData<List<ProjectModel>>
              ? projectsState.data
              : <ProjectModel>[];
          final nameMap = _buildNameMap(projects);
          final colorMap = _buildColorMap(projects);

          return AsyncStreamBuilder<List<SessionModel>>(
            state: _sessionsCtrl.uiState,
            builder: (context, sessions) {
              final groups = _groupByDay(sessions);
              final days = groups.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              return CustomScrollView(
                slivers: [
                  // header row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          Text(
                            '// sessions',
                            style: spaceMono(size: 10, color: textMuted),
                          ),
                          const Spacer(),
                          if (sessions.isNotEmpty)
                            _ExportButton(
                              isDark: isDark,
                              textMuted: textMuted,
                              onTap: () => _exportCsv(
                                  context, nameMap, isDark, textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (sessions.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                        child: Center(
                          child: Text(
                            'no_sessions_yet',
                            style: spaceMono(size: 12, color: textMuted),
                          ),
                        ),
                      ),
                    )
                  else
                    for (final day in days) ...[
                      // day header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Row(
                            children: [
                              Text(
                                _formatDay(day),
                                style: spaceMono(size: 10, color: textMuted),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _formatTotalDuration(groups[day]!),
                                style: spaceMono(
                                    size: 10,
                                    color: accent.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // session rows
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList.separated(
                          itemCount: groups[day]!.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppStyling.cardGap),
                          itemBuilder: (context, i) {
                            final session = groups[day]![i];
                            return SessionRowWidget(
                              session: session,
                              projectName:
                                  nameMap[session.projectId] ?? 'unknown',
                              projectColorHex:
                                  colorMap[session.projectId] ?? '#22C55E',
                              onTap: () => _openDetail(
                                  context, session, nameMap, colorMap),
                            );
                          },
                        ),
                      ),
                    ],

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            },
            loadingBuilder: (context) => const Center(
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
            errorBuilder: (context, msg) => Center(
              child:
                  Text('error: $msg', style: spaceMono(size: 11, color: textMuted)),
            ),
          );
        },
      ),
    );
  }
}

class _ExportButton extends StatefulWidget {
  final bool isDark;
  final Color textMuted;
  final VoidCallback onTap;

  const _ExportButton({
    required this.isDark,
    required this.textMuted,
    required this.onTap,
  });

  @override
  State<_ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<_ExportButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final border =
        widget.isDark ? AppStyling.borderDark : AppStyling.borderLight;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.textMuted.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download_rounded, size: 12, color: widget.textMuted),
              const SizedBox(width: 5),
              Text(
                'export_csv_',
                style: spaceMono(size: 10, color: widget.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
