import 'dart:async';
import 'package:flutter/services.dart';
import 'media_info.dart';
import 'media_service.dart';

class WindowsMediaService implements MediaService {
  static const _method = MethodChannel('trackr/media');
  static const _events = EventChannel('trackr/media/events');

  final _controller = StreamController<MediaInfo>.broadcast();
  StreamSubscription<dynamic>? _sub;
  MediaInfo _current = MediaInfo.none;

  @override
  Stream<MediaInfo> get stream => _controller.stream;

  @override
  MediaInfo get current => _current;

  @override
  Future<void> initialize() async {
    _sub = _events.receiveBroadcastStream().listen(
      (event) {
        if (event is! Map) return;
        final title = (event['title'] as String?) ?? '';
        final artist = (event['artist'] as String?) ?? '';
        final isPlaying = (event['isPlaying'] as bool?) ?? false;
        _current = MediaInfo(
          title: title,
          artist: artist,
          isPlaying: isPlaying,
          albumArtUrl: null,
        );
        _controller.add(_current);
      },
      onError: (_) {},
    );
  }

  @override
  Future<void> playPause() async {
    try {
      await _method.invokeMethod('playPause');
    } on PlatformException {
      // no session active
    }
  }

  @override
  Future<void> skipNext() async {
    try {
      await _method.invokeMethod('skipNext');
    } on PlatformException {
      // no session active
    }
  }

  @override
  Future<void> skipPrevious() async {
    try {
      await _method.invokeMethod('skipPrevious');
    } on PlatformException {
      // no session active
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
