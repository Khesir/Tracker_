import 'di_container.dart';
import 'di_logger.dart';

class ServiceLocator {
  ServiceLocator._();

  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get instance => _instance;

  final DiContainer _container = DiContainer();

  void registerSingleton<T>(T instance) => _container.registerSingleton<T>(instance);
  void registerLazySingleton<T>(T Function() factory) => _container.registerLazySingleton<T>(factory);
  void registerFactory<T>(T Function() factory) => _container.registerFactory<T>(factory);
  T get<T>() => _container.get<T>();
  bool isRegistered<T>() => _container.isRegistered<T>();
  void unregister<T>() => _container.unregister<T>();
  void reset() => _container.reset();
  Map<Type, String> getRegistrationInfo() => _container.getRegistrationInfo();

  ScopedServiceLocator createScope({String? name}) {
    DILogger.createScope(name);
    return ScopedServiceLocator(name: name);
  }
}

class ScopedServiceLocator {
  final DiContainer _container = DiContainer();
  final String? name;
  bool _isDisposed = false;

  ScopedServiceLocator({this.name});

  void registerSingleton<T>(T instance) {
    _throwIfDisposed();
    _container.registerSingleton<T>(instance);
  }

  void registerLazySingleton<T>(T Function() factory) {
    _throwIfDisposed();
    _container.registerLazySingleton<T>(factory);
  }

  void registerFactory<T>(T Function() factory) {
    _throwIfDisposed();
    _container.registerFactory<T>(factory);
  }

  T get<T>({bool useGlobalFallback = true}) {
    _throwIfDisposed();
    if (_container.isRegistered<T>()) return _container.get<T>();
    if (useGlobalFallback) return ServiceLocator.instance.get<T>();
    throw Exception('Service $T not found in scope ${name ?? "anon"}');
  }

  bool isRegistered<T>() {
    _throwIfDisposed();
    return _container.isRegistered<T>();
  }

  void dispose() {
    if (_isDisposed) return;
    DILogger.disposeScope(name);
    _container.reset();
    _isDisposed = true;
  }

  void _throwIfDisposed() {
    if (_isDisposed) throw Exception('Scope ${name ?? "anon"} is disposed');
  }
}

final locator = ServiceLocator.instance;
