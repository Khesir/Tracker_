import '../../../../core/models/session_model.dart';
import '../../domain/repository/timer_repository.dart';
import '../datasource/timer_local_datasource.dart';

class TimerRepositoryImpl implements TimerRepository {
  final TimerLocalDatasource _datasource;
  TimerRepositoryImpl(this._datasource);

  @override
  Future<void> saveSession(SessionModel session) =>
      _datasource.saveActiveSession(session);

  @override
  Future<SessionModel?> getActiveSession() =>
      _datasource.getActiveSession();

  @override
  Future<void> clearActiveSession() =>
      _datasource.clearActiveSession();
}
