library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:time_track/core/error/failure.dart';

abstract class StreamState<T> {
  final _controller = StreamController<T>.broadcast();
  T _state;

  StreamState(this._state);

  T get state => _state;
  Stream<T> get stream => _controller.stream;

  void emit(T newState) {
    _state = newState;
    if (!_controller.isClosed) _controller.add(newState);
  }

  void update(T Function(T current) updater) => emit(updater(_state));

  void dispose() => _controller.close();
}

sealed class AsyncState<T> {
  const AsyncState();
}

class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

class AsyncData<T> extends AsyncState<T> {
  final T data;
  const AsyncData(this.data);
}

class AsyncError<T> extends AsyncState<T> {
  final String message;
  final Object? error;
  const AsyncError(this.message, [this.error]);
}

extension AsyncStateExtension<T> on StreamState<AsyncState<T>> {
  bool get isLoading => state is AsyncLoading;
  bool get hasData => state is AsyncData;
  bool get hasError => state is AsyncError;

  T? get data => state is AsyncData<T> ? (state as AsyncData<T>).data : null;
  String? get errorMessage =>
      state is AsyncError<T> ? (state as AsyncError<T>).message : null;

  Future<void> execute(Future<T> Function() operation) async {
    emit(const AsyncLoading());
    try {
      emit(AsyncData(await operation()));
    } on Failure catch (f) {
      emit(AsyncError(f.message, f));
    } catch (e, st) {
      debugPrint('StreamState error: $e');
      emit(AsyncError(e.toString(), UnknownFailure(message: e.toString(), originalError: e, stackTrace: st)));
    }
  }

  Future<void> executeSilent(Future<T> Function() operation) async {
    try {
      emit(AsyncData(await operation()));
    } on Failure catch (f) {
      emit(AsyncError(f.message, f));
    } catch (e, st) {
      debugPrint('StreamState error: $e');
      emit(AsyncError(e.toString(), UnknownFailure(message: e.toString(), originalError: e, stackTrace: st)));
    }
  }
}
