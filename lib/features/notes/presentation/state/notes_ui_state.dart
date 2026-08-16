import '../../../../core/state/stream_state.dart';
import '../../../../core/models/note_model.dart';

class NotesUiState extends StreamState<AsyncState<List<NoteModel>>> {
  NotesUiState() : super(const AsyncLoading());
}
