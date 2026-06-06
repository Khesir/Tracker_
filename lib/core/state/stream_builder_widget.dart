library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'stream_state.dart';

class StreamStateBuilder<T> extends StatefulWidget {
  final StreamState<T> state;
  final Widget Function(BuildContext context, T state) builder;

  const StreamStateBuilder({
    super.key,
    required this.state,
    required this.builder,
  });

  @override
  State<StreamStateBuilder<T>> createState() => _StreamStateBuilderState<T>();
}

class _StreamStateBuilderState<T> extends State<StreamStateBuilder<T>> {
  late StreamSubscription<T> _subscription;
  late T _currentState;

  @override
  void initState() {
    super.initState();
    _currentState = widget.state.state;
    _subscription = widget.state.stream.listen((s) {
      if (mounted) setState(() => _currentState = s);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _currentState);
}

class AsyncStreamBuilder<T> extends StatelessWidget {
  final StreamState<AsyncState<T>> state;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String message)? errorBuilder;

  const AsyncStreamBuilder({
    super.key,
    required this.state,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamStateBuilder<AsyncState<T>>(
      state: state,
      builder: (context, asyncState) => switch (asyncState) {
        AsyncLoading() =>
          loadingBuilder?.call(context) ?? const Center(child: CircularProgressIndicator()),
        AsyncData(data: final data) => builder(context, data),
        AsyncError(message: final msg) =>
          errorBuilder?.call(context, msg) ?? Center(child: Text('error: $msg')),
      },
    );
  }
}
