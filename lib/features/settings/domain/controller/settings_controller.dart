import '../../../../core/state/stream_state.dart';
import '../../../../core/models/app_settings_model.dart';
import '../../domain/repository/settings_repository.dart';
import '../../presentation/state/settings_ui_state.dart';

class SettingsController {
  final SettingsRepository _repo;
  final SettingsUiState uiState;

  SettingsController(this._repo) : uiState = SettingsUiState();

  Future<void> load() => uiState.execute(() => _repo.get());

  AppSettingsModel? get current =>
      uiState.state is AsyncData<AppSettingsModel>
          ? (uiState.state as AsyncData<AppSettingsModel>).data
          : null;

  Future<void> update(AppSettingsModel settings) async {
    await _repo.save(settings);
    await load();
  }

  void dispose() => uiState.dispose();
}
