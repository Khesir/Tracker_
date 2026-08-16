import 'package:uuid/uuid.dart';

import '../../../core/models/note_model.dart';
import '../../projects/domain/repository/projects_repository.dart';
import '../../sessions/domain/repository/sessions_repository.dart';
import '../domain/repository/notes_repository.dart';

/// One-time, idempotent migration that gives legacy projects a running
/// start under the new Note system.
///
/// For every project that does not yet have a `noteId` and has at least one
/// session with non-empty legacy `SessionModel.noteJson`, this creates a
/// new [NoteModel] seeded from that project's most recent session (by
/// `startedAt`, among sessions with non-empty `noteJson`) and links it to
/// the project.
///
/// Safe to call on every app startup: projects that already have a
/// `noteId` — whether from a prior run of this migration, or from the user
/// manually linking/creating a note before migration ever ran — are left
/// completely untouched. The legacy `SessionModel.noteJson` field is never
/// modified or cleared.
Future<void> runLegacyNoteMigration({
  required ProjectsRepository projects,
  required SessionsRepository sessions,
  required NotesRepository notes,
}) async {
  final allProjects = await projects.getAll();

  for (final project in allProjects) {
    if (project.noteId != null) continue;

    final projectSessions = await sessions.getByProject(project.id);
    final withNotes =
        projectSessions.where((s) => s.noteJson.isNotEmpty).toList();
    if (withNotes.isEmpty) continue;

    withNotes.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final mostRecent = withNotes.first;

    final now = DateTime.now();
    final note = NoteModel(
      id: const Uuid().v4(),
      noteJson: mostRecent.noteJson,
      createdAt: now,
      updatedAt: now,
    );

    await notes.save(note);
    await projects.save(project.copyWith(noteId: note.id));
  }
}
