import 'package:flutter_test/flutter_test.dart';
import 'package:time_track/core/models/note_model.dart';

void main() {
  group('NoteModel', () {
    test('toJson/fromJson round-trips all fields', () {
      final note = NoteModel(
        id: 'n1',
        noteJson: '{"ops":[{"insert":"hello\\n"}]}',
        createdAt: DateTime(2026, 1, 1, 10, 30),
        updatedAt: DateTime(2026, 1, 2, 11, 45),
      );

      final result = NoteModel.fromJson(note.toJson());

      expect(result.id, note.id);
      expect(result.noteJson, note.noteJson);
      expect(result.createdAt, note.createdAt);
      expect(result.updatedAt, note.updatedAt);
    });

    test('copyWith updates noteJson and updatedAt while leaving id and createdAt unchanged', () {
      final note = NoteModel(
        id: 'n1',
        noteJson: '{"ops":[{"insert":"hello\\n"}]}',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final updated = note.copyWith(
        noteJson: '{"ops":[{"insert":"updated\\n"}]}',
        updatedAt: DateTime(2026, 1, 3),
      );

      expect(updated.id, note.id);
      expect(updated.createdAt, note.createdAt);
      expect(updated.noteJson, '{"ops":[{"insert":"updated\\n"}]}');
      expect(updated.updatedAt, DateTime(2026, 1, 3));
    });

    test('copyWith with no arguments preserves all fields', () {
      final note = NoteModel(
        id: 'n1',
        noteJson: '{"ops":[]}',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final result = note.copyWith();

      expect(result.id, note.id);
      expect(result.noteJson, note.noteJson);
      expect(result.createdAt, note.createdAt);
      expect(result.updatedAt, note.updatedAt);
    });
  });
}
