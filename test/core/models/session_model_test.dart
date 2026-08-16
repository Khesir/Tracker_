import 'package:flutter_test/flutter_test.dart';
import 'package:time_track/core/models/session_model.dart';

void main() {
  group('SessionModel noteId/postNote', () {
    test('toJson/fromJson round-trips noteId and postNote when set', () {
      final session = SessionModel(
        id: 's1',
        projectId: 'p1',
        startedAt: DateTime(2026, 1, 1, 9),
        endedAt: DateTime(2026, 1, 1, 10),
        durationSeconds: 3600,
        noteJson: '',
        musicLog: const [],
        noteId: 'n1',
        postNote: 'wrapped up the thing',
      );

      final result = SessionModel.fromJson(session.toJson());

      expect(result.noteId, 'n1');
      expect(result.postNote, 'wrapped up the thing');
      // legacy field untouched by the new fields
      expect(result.noteJson, '');
    });

    test('toJson/fromJson round-trips null noteId and postNote', () {
      final session = SessionModel(
        id: 's1',
        projectId: 'p1',
        startedAt: DateTime(2026, 1, 1, 9),
        durationSeconds: 0,
        noteJson: '',
        musicLog: const [],
      );

      final result = SessionModel.fromJson(session.toJson());

      expect(result.noteId, isNull);
      expect(result.postNote, isNull);
    });

    test('fromJson defaults noteId/postNote to null when absent (old rows)', () {
      final legacyJson = <String, dynamic>{
        'id': 's1',
        'projectId': 'p1',
        'startedAt': DateTime(2026, 1, 1).toIso8601String(),
        'endedAt': null,
        'durationSeconds': 0,
        'noteJson': 'legacy content',
        'musicLog': <dynamic>[],
        'deletedAt': null,
        // no noteId / postNote keys at all
      };

      final result = SessionModel.fromJson(legacyJson);

      expect(result.noteId, isNull);
      expect(result.postNote, isNull);
      expect(result.noteJson, 'legacy content');
    });

    test('copyWith updates noteId and postNote independently', () {
      final session = SessionModel(
        id: 's1',
        projectId: 'p1',
        startedAt: DateTime(2026, 1, 1),
        durationSeconds: 0,
        noteJson: '',
        musicLog: const [],
      );

      final withNote = session.copyWith(noteId: 'n1');
      expect(withNote.noteId, 'n1');
      expect(withNote.postNote, isNull);

      final withPostNote = withNote.copyWith(postNote: 'done for today');
      expect(withPostNote.noteId, 'n1');
      expect(withPostNote.postNote, 'done for today');
    });

    test('copyWith with no arguments preserves noteId and postNote', () {
      final session = SessionModel(
        id: 's1',
        projectId: 'p1',
        startedAt: DateTime(2026, 1, 1),
        durationSeconds: 0,
        noteJson: '',
        musicLog: const [],
        noteId: 'n1',
        postNote: 'preserved',
      );

      final result = session.copyWith();

      expect(result.noteId, 'n1');
      expect(result.postNote, 'preserved');
    });
  });
}
