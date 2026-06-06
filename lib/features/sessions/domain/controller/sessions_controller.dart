import 'dart:convert';
import 'dart:io';
import '../../../../core/models/session_model.dart';
import '../../../../core/state/stream_state.dart';
import '../../domain/repository/sessions_repository.dart';
import '../../presentation/state/sessions_ui_state.dart';

class SessionsController {
  final SessionsRepository _repo;
  final SessionsUiState uiState;

  SessionsController(this._repo) : uiState = SessionsUiState();

  Future<void> load() => uiState.execute(() async {
        final all = await _repo.getAll();
        all.sort((a, b) => b.startedAt.compareTo(a.startedAt));
        return all.where((s) => !s.isActive).toList();
      });

  Future<void> loadByProject(String projectId) =>
      uiState.execute(() => _repo.getByProject(projectId));

  Future<void> update(SessionModel session) async {
    await _repo.save(session);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }

  Future<String?> exportCsv(Map<String, String> projectNames) async {
    final current = uiState.state;
    if (current is! AsyncData<List<SessionModel>>) return null;
    final sessions = current.data;

    final rows = [
      'date,project,duration_seconds,note,music',
      ...sessions.map((s) {
        final project = projectNames[s.projectId] ?? s.projectId;
        final note = _noteToText(s.noteJson).replaceAll('"', '""');
        final music = s.musicLog
            .map((m) => '${m.artist} — ${m.title}')
            .join(' | ')
            .replaceAll('"', '""');
        return '"${s.startedAt.toIso8601String()}","$project","${s.durationSeconds}","$note","$music"';
      }),
    ];

    final csv = rows.join('\n');
    final homePath = Platform.environment['USERPROFILE'] ?? '.';
    final file = File('$homePath\\Downloads\\trackr_sessions.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  static String _noteToText(String noteJson) {
    if (noteJson.isEmpty) return '';
    try {
      final delta = jsonDecode(noteJson) as List<dynamic>;
      return delta
          .where((op) => op is Map && op['insert'] is String)
          .map((op) => op['insert'] as String)
          .join()
          .trim();
    } catch (_) {
      return '';
    }
  }

  void dispose() => uiState.dispose();
}
