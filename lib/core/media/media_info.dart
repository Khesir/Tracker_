import 'dart:typed_data';

class MediaInfo {
  final String title;
  final String artist;
  final Uint8List? albumArtBytes;
  final bool isPlaying;

  const MediaInfo({
    required this.title,
    required this.artist,
    this.albumArtBytes,
    required this.isPlaying,
  });

  static const MediaInfo none = MediaInfo(title: '', artist: '', isPlaying: false);

  bool get hasTrack => title.isNotEmpty;

  MediaInfo copyWith({String? title, String? artist, Uint8List? albumArtBytes, bool? isPlaying}) {
    return MediaInfo(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArtBytes: albumArtBytes ?? this.albumArtBytes,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}
