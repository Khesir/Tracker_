import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_track/core/models/session_model.dart';
import 'package:time_track/features/sessions/domain/controller/sessions_controller.dart';
import 'package:time_track/features/sessions/domain/repository/sessions_repository.dart';

class FakeSessionsRepository implements SessionsRepository {
  final List<SessionModel> sessions;

  FakeSessionsRepository([List<SessionModel>? sessions]) : sessions = sessions ?? [];

  @override
  Future<List<SessionModel>> getAll() async => sessions;

  @override
  Future<List<SessionModel>> getByProject(String projectId) async =>
      sessions.where((s) => s.projectId == projectId).toList();

  @override
  Future<List<SessionModel>> getByDateRange(DateTime from, DateTime to) async =>
      sessions.where((s) => !s.startedAt.isBefore(from) && !s.startedAt.isAfter(to)).toList();

  @override
  Future<SessionModel?> getById(String id) async =>
      sessions.where((s) => s.id == id).firstOrNull;

  @override
  Future<void> save(SessionModel session) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> softDeleteByProject(String projectId) async {}

  @override
  Future<void> restoreByProject(String projectId) async {}

  @override
  Future<void> purgeByProject(String projectId) async {}
}

SessionModel _session({
  required String id,
  required String projectId,
  DateTime? startedAt,
  DateTime? endedAt,
  int durationSeconds = 3600,
  String? title,
}) {
  return SessionModel(
    id: id,
    projectId: projectId,
    startedAt: startedAt ?? DateTime(2026, 1, 1, 9),
    endedAt: endedAt ?? DateTime(2026, 1, 1, 10),
    durationSeconds: durationSeconds,
    noteJson: '',
    musicLog: const [],
    title: title,
  );
}

void main() {
  late FakeSessionsRepository repo;
  late SessionsController controller;
  File? exportedFile;

  Future<List<String>> exportAndReadLines() async {
    final path = await controller.exportCsv({'p1': 'Focus Time'});
    expect(path, isNotNull);
    exportedFile = File(path!);
    final content = await exportedFile!.readAsString();
    return content.split('\n');
  }

  setUp(() {
    repo = FakeSessionsRepository();
    controller = SessionsController(repo);
    exportedFile = null;
  });

  tearDown(() async {
    controller.dispose();
    final file = exportedFile;
    if (file != null && file.existsSync()) {
      await file.delete();
    }
  });

  group('exportCsv title column', () {
    test('header includes title directly after project', () async {
      repo.sessions.add(_session(id: 's1', projectId: 'p1', title: 'Deep Work'));
      await controller.load();

      final lines = await exportAndReadLines();

      expect(lines.first, 'date,project,title,duration_seconds,note,music');
    });

    test('a session with a title exports it in the title column', () async {
      repo.sessions.add(_session(id: 's1', projectId: 'p1', title: 'Deep Work'));
      await controller.load();

      final lines = await exportAndReadLines();

      expect(lines[1], contains('"Focus Time","Deep Work"'));
    });

    test('a session with no title exports an empty field without breaking row shape', () async {
      repo.sessions.add(_session(id: 's1', projectId: 'p1', title: null));
      await controller.load();

      final lines = await exportAndReadLines();
      final row = lines[1];

      expect(row, contains('"Focus Time","","3600"'));
      // 6 quoted fields joined by "," between them -> splitting on the separator yields 6 parts.
      expect(row.split('","').length, 6);
    });

    test('a title with a comma and embedded quote is escaped the same way note/music are', () async {
      repo.sessions.add(_session(id: 's1', projectId: 'p1', title: 'Design, "v2"'));
      await controller.load();

      final lines = await exportAndReadLines();

      expect(lines[1], contains('"Design, ""v2"""'));
    });

    test('note and music columns remain untouched by the title change', () async {
      repo.sessions.add(_session(id: 's1', projectId: 'p1', title: 'Deep Work'));
      await controller.load();

      final lines = await exportAndReadLines();
      final row = lines[1];

      expect(row, endsWith('"3600","",""'));
    });
  });
}
