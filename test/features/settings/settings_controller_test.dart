import 'package:flutter_test/flutter_test.dart';
import 'package:time_track/core/models/app_settings_model.dart';
import 'package:time_track/features/settings/domain/controller/settings_controller.dart';
import 'package:time_track/features/settings/domain/repository/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  final List<String> calls;
  AppSettingsModel settings;

  FakeSettingsRepository(this.settings, [List<String>? sharedCalls])
      : calls = sharedCalls ?? [];

  @override
  Future<AppSettingsModel> get() async {
    calls.add('get');
    return settings;
  }

  @override
  Future<void> save(AppSettingsModel settings) async {
    calls.add('save');
    this.settings = settings;
  }
}

void main() {
  late List<String> calls;
  late FakeSettingsRepository repo;

  setUp(() {
    calls = [];
    repo = FakeSettingsRepository(const AppSettingsModel(), calls);
  });

  group('update', () {
    test('persists a widgetStyle change through the repository and reflects it after load',
        () async {
      final controller = SettingsController(repo);
      await controller.load();
      final current = controller.current!;
      expect(current.widgetStyle, 'vinyl');

      await controller.update(current.copyWith(widgetStyle: 'bar'));

      expect(calls, ['get', 'save', 'get']);
      expect(controller.current!.widgetStyle, 'bar');
    });
  });
}
