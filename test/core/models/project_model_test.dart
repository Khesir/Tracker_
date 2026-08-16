import 'package:flutter_test/flutter_test.dart';
import 'package:time_track/core/models/project_model.dart';

void main() {
  group('ProjectModel.noteId', () {
    test('defaults to null', () {
      final project = ProjectModel(
        id: 'p1',
        name: 'Project',
        colorHex: '#FFFFFF',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(project.noteId, isNull);
    });

    test('toJson/fromJson round-trips noteId', () {
      final project = ProjectModel(
        id: 'p1',
        name: 'Project',
        colorHex: '#FFFFFF',
        createdAt: DateTime(2026, 1, 1),
        noteId: 'n1',
      );

      final result = ProjectModel.fromJson(project.toJson());

      expect(result.noteId, 'n1');
    });

    test('fromJson falls back to null when noteId key is missing (legacy data)', () {
      final legacyJson = ProjectModel(
        id: 'p1',
        name: 'Project',
        colorHex: '#FFFFFF',
        createdAt: DateTime(2026, 1, 1),
      ).toJson()
        ..remove('noteId');

      final result = ProjectModel.fromJson(legacyJson);

      expect(result.noteId, isNull);
    });

    test('copyWith updates noteId and leaves other fields unchanged', () {
      final project = ProjectModel(
        id: 'p1',
        name: 'Project',
        colorHex: '#FFFFFF',
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = project.copyWith(noteId: 'n1');

      expect(updated.noteId, 'n1');
      expect(updated.id, project.id);
      expect(updated.name, project.name);
      expect(updated.colorHex, project.colorHex);
      expect(updated.targetMinutes, project.targetMinutes);
      expect(updated.createdAt, project.createdAt);
      expect(updated.deletedAt, project.deletedAt);
    });

    test('copyWith with no arguments preserves noteId', () {
      final project = ProjectModel(
        id: 'p1',
        name: 'Project',
        colorHex: '#FFFFFF',
        createdAt: DateTime(2026, 1, 1),
        noteId: 'n1',
      );

      final result = project.copyWith();

      expect(result.noteId, 'n1');
    });
  });
}
