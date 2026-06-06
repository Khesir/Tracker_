import 'package:flutter/material.dart';
import '../di/service_locator.dart';
import '../di/disposable.dart';

abstract class ScopedScreen extends StatefulWidget {
  const ScopedScreen({super.key});
  String? get scopeName => null;
}

abstract class ScopedScreenState<W extends ScopedScreen> extends State<W>
    implements Disposable {
  late final ScopedServiceLocator scope;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final name = widget.scopeName ?? widget.runtimeType.toString();
    scope = locator.createScope(name: name);
    registerServices();
    _isInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) onReady();
    });
  }

  @override
  void dispose() {
    if (_isInitialized) onDispose();
    scope.dispose();
    super.dispose();
  }

  void registerServices() {}
  void onReady() {}
  void onDispose() {}

  T getService<T>({bool useGlobalFallback = true}) =>
      scope.get<T>(useGlobalFallback: useGlobalFallback);

  void registerSingleton<T>(T instance) => scope.registerSingleton<T>(instance);
  void registerLazySingleton<T>(T Function() factory) => scope.registerLazySingleton<T>(factory);
  void registerFactory<T>(T Function() factory) => scope.registerFactory<T>(factory);
}
