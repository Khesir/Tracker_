import 'package:flutter_test/flutter_test.dart';
import 'package:time_track/core/models/project_model.dart';
import 'package:time_track/core/models/session_model.dart';
import 'package:time_track/features/projects/domain/project_list_view.dart';

ProjectModel _project({required String id, DateTime? deletedAt}) {
  return ProjectModel(
    id: id,
    name: 'Project $id',
    colorHex: '#FFFFFF',
    createdAt: DateTime(2026, 1, 1),
    deletedAt: deletedAt,
  );
}

SessionModel _session({
  required String projectId,
  required DateTime startedAt,
  required int durationSeconds,
}) {
  return SessionModel(
    id: 's-$projectId-${startedAt.toIso8601String()}-$durationSeconds',
    projectId: projectId,
    startedAt: startedAt,
    durationSeconds: durationSeconds,
    noteJson: '',
    musicLog: const [],
  );
}

void main() {
  final now = DateTime(2026, 8, 20, 15, 0);
  final yesterday = DateTime(2026, 8, 19, 15, 0);

  group('buildProjectListView', () {
    test('sorts two projects by total seconds descending', () {
      final projects = [_project(id: 'p1'), _project(id: 'p2')];
      final sessions = [
        _session(projectId: 'p1', startedAt: yesterday, durationSeconds: 100),
        _session(projectId: 'p2', startedAt: yesterday, durationSeconds: 500),
      ];

      final result = buildProjectListView(projects, sessions, now: now);

      expect(result.map((e) => e.project.id), ['p2', 'p1']);
    });

    test('computes correct total and today seconds per project', () {
      final projects = [_project(id: 'p1')];
      final sessions = [
        _session(projectId: 'p1', startedAt: yesterday, durationSeconds: 200),
        _session(projectId: 'p1', startedAt: now, durationSeconds: 50),
      ];

      final result = buildProjectListView(projects, sessions, now: now);

      expect(result.single.totalSeconds, 250);
      expect(result.single.todaySeconds, 50);
    });

    test('ties in total seconds are broken by today seconds descending', () {
      final projects = [_project(id: 'p1'), _project(id: 'p2')];
      final sessions = [
        // Both projects have 300 total seconds.
        _session(projectId: 'p1', startedAt: yesterday, durationSeconds: 300),
        _session(projectId: 'p2', startedAt: yesterday, durationSeconds: 200),
        _session(projectId: 'p2', startedAt: now, durationSeconds: 100),
      ];

      final result = buildProjectListView(projects, sessions, now: now);

      expect(result.map((e) => e.project.id), ['p2', 'p1']);
    });

    test('excludes soft-deleted projects', () {
      final projects = [
        _project(id: 'p1'),
        _project(id: 'p2', deletedAt: DateTime(2026, 2, 1)),
      ];
      final sessions = [
        _session(projectId: 'p1', startedAt: yesterday, durationSeconds: 100),
        _session(projectId: 'p2', startedAt: yesterday, durationSeconds: 900),
      ];

      final result = buildProjectListView(projects, sessions, now: now);

      expect(result.map((e) => e.project.id), ['p1']);
    });

    test('projects with no sessions get zero total and today seconds', () {
      final projects = [_project(id: 'p1')];

      final result = buildProjectListView(projects, [], now: now);

      expect(result.single.totalSeconds, 0);
      expect(result.single.todaySeconds, 0);
    });
  });
}
