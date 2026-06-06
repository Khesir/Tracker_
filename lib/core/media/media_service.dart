import 'media_info.dart';

abstract class MediaService {
  Stream<MediaInfo> get stream;
  MediaInfo get current;

  Future<void> initialize();
  Future<void> requestSnapshot();
  Future<void> playPause();
  Future<void> skipNext();
  Future<void> skipPrevious();
  void dispose();
}

class NullMediaService implements MediaService {
  @override
  Stream<MediaInfo> get stream => const Stream.empty();

  @override
  MediaInfo get current => MediaInfo.none;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestSnapshot() async {}

  @override
  Future<void> playPause() async {}

  @override
  Future<void> skipNext() async {}

  @override
  Future<void> skipPrevious() async {}

  @override
  void dispose() {}
}
