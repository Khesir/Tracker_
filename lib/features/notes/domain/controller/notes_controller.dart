import 'package:uuid/uuid.dart';
import '../../../../core/state/stream_state.dart';
import '../../../../core/models/note_model.dart';
import '../../../../core/models/project_model.dart';
import '../../../projects/domain/repository/projects_repository.dart';
import '../../domain/repository/notes_repository.dart';
import '../../presentation/state/notes_ui_state.dart';

class NotesController {
  final NotesRepository _repo;
  final ProjectsRepository _projects;
  final NotesUiState uiState;

  NotesController(this._repo, this._projects) : uiState = NotesUiState();

  Future<void> load() => uiState.execute(() => _repo.getAll());

  Future<NoteModel> create() async {
    final now = DateTime.now();
    final note = NoteModel(
      id: const Uuid().v4(),
      noteJson: '',
      createdAt: now,
      updatedAt: now,
    );
    await _repo.save(note);
    await load();
    return note;
  }

  Future<void> update(NoteModel note) async {
    await _repo.save(note);
    await load();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await load();
  }

  /// All non-deleted projects — used by the screen to derive which
  /// project(s) currently link to each note (via `ProjectModel.noteId`).
  /// That relationship lives on the project side, not on the note, so
  /// deriving it requires scanning projects rather than reading the note.
  Future<List<ProjectModel>> allProjects() => _projects.getAll();

  void dispose() => uiState.dispose();
}
