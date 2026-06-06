import 'package:flutter/foundation.dart';

class DILogger {
  static bool _enabled = false;

  static void enable() => _enabled = true;
  static void disable() => _enabled = false;

  static void log(String msg) {
    if (_enabled) debugPrint('[DI] $msg');
  }

  static void registerSingleton(Type t) => log('singleton: $t');
  static void registerFactory(Type t) => log('factory: $t');
  static void registerLazySingleton(Type t) => log('lazy: $t');
  static void resolve(Type t) => log('resolve: $t');
  static void unregister(Type t) => log('unregister: $t');
  static void dispose(Type t) => log('dispose: $t');
  static void createScope(String? name) => log('scope+: ${name ?? "anon"}');
  static void disposeScope(String? name) => log('scope-: ${name ?? "anon"}');
  static void error(String msg) { if (_enabled) debugPrint('[DI ERROR] $msg'); }
}
