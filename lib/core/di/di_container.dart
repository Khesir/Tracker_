import 'disposable.dart';
import 'di_logger.dart';

class DiContainer {
  final _services = <Type, dynamic>{};
  final _factories = <Type, Function>{};
  final _registrationTypes = <Type, _RegType>{};

  void registerSingleton<T>(T instance) {
    _services[T] = instance;
    _registrationTypes[T] = _RegType.singleton;
    DILogger.registerSingleton(T);
  }

  void registerLazySingleton<T>(T Function() factory) {
    _factories[T] = () {
      DILogger.resolve(T);
      final instance = factory();
      _services[T] = instance;
      _factories.remove(T);
      _registrationTypes[T] = _RegType.singleton;
      return instance;
    };
    _registrationTypes[T] = _RegType.lazySingleton;
    DILogger.registerLazySingleton(T);
  }

  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
    _registrationTypes[T] = _RegType.factory;
    DILogger.registerFactory(T);
  }

  T get<T>() {
    if (_services.containsKey(T)) {
      DILogger.resolve(T);
      return _services[T] as T;
    }
    if (_factories.containsKey(T)) {
      DILogger.resolve(T);
      return _factories[T]!() as T;
    }
    final error = 'Service of type $T not registered';
    DILogger.error(error);
    throw Exception(error);
  }

  bool isRegistered<T>() => _services.containsKey(T) || _factories.containsKey(T);

  void unregister<T>() {
    if (_services.containsKey(T)) {
      final instance = _services[T];
      if (instance is Disposable) {
        DILogger.dispose(T);
        instance.dispose();
      }
      _services.remove(T);
    }
    _factories.remove(T);
    _registrationTypes.remove(T);
    DILogger.unregister(T);
  }

  void reset() {
    for (final entry in _services.entries) {
      if (entry.value is Disposable) {
        DILogger.dispose(entry.key);
        (entry.value as Disposable).dispose();
      }
    }
    _services.clear();
    _factories.clear();
    _registrationTypes.clear();
  }

  Map<Type, String> getRegistrationInfo() {
    return {
      for (final t in [..._services.keys, ..._factories.keys])
        t: _registrationTypes[t]?.name ?? 'unknown',
    };
  }
}

enum _RegType { singleton, lazySingleton, factory }
