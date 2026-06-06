import '../../../../core/state/stream_state.dart';
import '../../../../core/models/session_model.dart';

class SessionsUiState extends StreamState<AsyncState<List<SessionModel>>> {
  SessionsUiState() : super(const AsyncLoading());
}
