import '../../../core/models/project_model.dart';
import '../../../core/models/session_model.dart';

/// A single row for the project list: a project paired with its resolved
/// total (all-time) and today's tracked seconds.
///
/// Pure data holder — no Flutter dependency.
class ProjectListEntry {
  final ProjectModel project;
  final int totalSeconds;
  final int todaySeconds;

  const ProjectListEntry({
    required this.project,
    required this.totalSeconds,
    required this.todaySeconds,
  });
}

/// Builds the sorted list of active (non-deleted) projects for the
/// projects screen, with each project's total and today's tracked seconds
/// resolved from [sessions].
///
/// Sort order: total seconds descending, tie-broken by today's seconds
/// descending. Soft-deleted projects are excluded.
///
/// "Today" means calendar-day-local, matching [now] (defaults to
/// `DateTime.now()`).
List<ProjectListEntry> buildProjectListView(
  List<ProjectModel> projects,
  List<SessionModel> sessions, {
  DateTime? now,
}) {
  final today = now ?? DateTime.now();

  final totalByProject = <String, int>{};
  final todayByProject = <String, int>{};
  for (final s in sessions) {
    totalByProject[s.projectId] =
        (totalByProject[s.projectId] ?? 0) + s.durationSeconds;
    if (s.startedAt.year == today.year &&
        s.startedAt.month == today.month &&
        s.startedAt.day == today.day) {
      todayByProject[s.projectId] =
          (todayByProject[s.projectId] ?? 0) + s.durationSeconds;
    }
  }

  final entries = projects
      .where((p) => !p.isDeleted)
      .map((p) => ProjectListEntry(
            project: p,
            totalSeconds: totalByProject[p.id] ?? 0,
            todaySeconds: todayByProject[p.id] ?? 0,
          ))
      .toList();

  entries.sort((a, b) {
    final totalCmp = b.totalSeconds.compareTo(a.totalSeconds);
    if (totalCmp != 0) return totalCmp;
    return b.todaySeconds.compareTo(a.todaySeconds);
  });

  return entries;
}
