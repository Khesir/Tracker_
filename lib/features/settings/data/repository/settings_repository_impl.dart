import '../../../../core/models/app_settings_model.dart';
import '../../domain/repository/settings_repository.dart';
import '../datasource/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDatasource _datasource;
  SettingsRepositoryImpl(this._datasource);

  @override
  Future<AppSettingsModel> get() => _datasource.get();

  @override
  Future<void> save(AppSettingsModel settings) => _datasource.save(settings);
}
