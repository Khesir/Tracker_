import '../../../../core/state/stream_state.dart';
import '../../../../core/models/app_settings_model.dart';

class SettingsUiState extends StreamState<AsyncState<AppSettingsModel>> {
  SettingsUiState() : super(const AsyncLoading());
}
