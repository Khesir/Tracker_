import 'package:flutter_test/flutter_test.dart';
import 'package:time_track/core/models/project_model.dart';
import 'package:time_track/features/projects/domain/controller/projects_controller.dart';
import 'package:time_track/features/projects/domain/repository/projects_repository.dart';
import 'package:time_track/features/timer/domain/controller/timer_controller.dart';
import 'package:time_track/features/timer/presentation/state/timer_ui_state.dart';

class FakeProjectsRepository implements ProjectsRepository {
  final List<String> calls;
  final List<ProjectModel> projects = [];
  final List<ProjectModel> deleted = [];

  FakeProjectsRepository([List<String>? sharedCalls]) : calls = sharedCalls ?? [];

  @override
  Future<List<ProjectModel>> getAll() async => projects;

  @override
  Future<ProjectModel?> getById(String id) async =>
      projects.where((p) => p.id == id).firstOrNull;

  @override
  Future<void> save(ProjectModel project) async {
    calls.add('save:${project.id}');
  }

  @override
  Future<void> delete(String id) async {
    calls.add('delete:$id');
  }

  @override
  Future<void> softDelete(String id) async {
    calls.add('softDelete:$id');
  }

  @override
  Future<void> restore(String id) async {
    calls.add('restore:$id');
  }

  @override
  Future<void> purge(String id) async {
    calls.add('purge:$id');
  }

  @override
  Future<List<ProjectModel>> getDeleted() async => deleted;
}

class FakeTimerController implements TimerController {
  final List<String> calls;
  final TimerUiData _state;

  FakeTimerController(this._state, [List<String>? sharedCalls]) : calls = sharedCalls ?? [];

  @override
  TimerUiState get uiState => _FakeTimerUiState(_state);

  @override
  Future<void> stop() async {
    calls.add('timer.stop');
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTimerUiState implements TimerUiState {
  final TimerUiData _data;
  _FakeTimerUiState(this._data);

  @override
  TimerUiData get state => _data;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProjectModel _project({required String id, DateTime? deletedAt}) {
  return ProjectModel(
    id: id,
    name: 'Project $id',
    colorHex: '#FFFFFF',
    createdAt: DateTime(2026, 1, 1),
    deletedAt: deletedAt,
  );
}

void main() {
  late List<String> calls;
  late FakeProjectsRepository repo;

  setUp(() {
    calls = [];
    repo = FakeProjectsRepository(calls);
    repo.projects.addAll([_project(id: 'p1'), _project(id: 'p2')]);
  });

  group('softDelete', () {
    test('stops the active session first, then soft-deletes, when the session belongs to this project',
        () async {
      final timer = FakeTimerController(
        const TimerUiData(status: TimerStatus.running, projectId: 'p1'),
        calls,
      );
      final controller = ProjectsController(repo, timer);

      await controller.softDelete('p1');

      expect(calls, ['timer.stop', 'softDelete:p1']);
    });

    test('skips the stop step when there is no active session', () async {
      final timer = FakeTimerController(
        const TimerUiData(status: TimerStatus.idle),
        calls,
      );
      final controller = ProjectsController(repo, timer);

      await controller.softDelete('p1');

      expect(calls, ['softDelete:p1']);
    });

    test('skips the stop step when the active session belongs to a different project',
        () async {
      final timer = FakeTimerController(
        const TimerUiData(status: TimerStatus.running, projectId: 'p2'),
        calls,
      );
      final controller = ProjectsController(repo, timer);

      await controller.softDelete('p1');

      expect(calls, ['softDelete:p1']);
    });
  });

  group('restore', () {
    test('delegates to ProjectsRepository.restore', () async {
      final timer = FakeTimerController(const TimerUiData(status: TimerStatus.idle), calls);
      final controller = ProjectsController(repo, timer);

      await controller.restore('p1');

      expect(calls, ['restore:p1']);
    });
  });

  group('purge', () {
    test('delegates to ProjectsRepository.purge', () async {
      final timer = FakeTimerController(const TimerUiData(status: TimerStatus.idle), calls);
      final controller = ProjectsController(repo, timer);

      await controller.purge('p1');

      expect(calls, ['purge:p1']);
    });
  });

  group('getDeleted', () {
    test('exposes the list of soft-deleted projects', () async {
      final timer = FakeTimerController(const TimerUiData(status: TimerStatus.idle), calls);
      final controller = ProjectsController(repo, timer);
      repo.deleted.add(_project(id: 'p1', deletedAt: DateTime(2026, 1, 2)));

      final result = await controller.getDeleted();

      expect(result.map((p) => p.id), ['p1']);
    });
  });
}
