import '../../../../core/models/note_model.dart';
import '../../domain/repository/notes_repository.dart';
import '../datasource/notes_local_datasource.dart';

class NotesRepositoryImpl implements NotesRepository {
  final NotesLocalDatasource _datasource;
  NotesRepositoryImpl(this._datasource);

  @override
  Future<List<NoteModel>> getAll() => _datasource.getAll();

  @override
  Future<NoteModel?> getById(String id) => _datasource.getById(id);

  @override
  Future<void> save(NoteModel note) => _datasource.save(note);

  @override
  Future<void> delete(String id) => _datasource.delete(id);

  @override
  Future<void> unlinkFromProject(String projectId) async {
    // No-op: noteId links are stored on ProjectModel, not NoteModel. See the
    // interface doc comment for why this hook exists regardless.
  }
}
