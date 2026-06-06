import '../../../../core/state/stream_state.dart';
import '../../../../core/models/project_model.dart';

class ProjectsUiState extends StreamState<AsyncState<List<ProjectModel>>> {
  ProjectsUiState() : super(const AsyncLoading());
}
