import '../../../../core/models/note_model.dart';

abstract class NotesRepository {
  Future<List<NoteModel>> getAll();
  Future<NoteModel?> getById(String id);
  Future<void> save(NoteModel note);
  Future<void> delete(String id);

  /// Cascade hook invoked by [ProjectsRepository] when a project is
  /// permanently purged. `noteId` links live on `ProjectModel`, not on
  /// `NoteModel` (a note stores no project reference and may be linked to
  /// several projects at once), so there is nothing for this repository to
  /// mutate today — clearing the purged project's own `noteId` is handled
  /// project-side. This hook exists purely so the cascade shape mirrors the
  /// existing `SessionsRepository` orchestration in `ProjectsRepositoryImpl`
  /// and to leave a seam for future note-side bookkeeping.
  Future<void> unlinkFromProject(String projectId);
}
