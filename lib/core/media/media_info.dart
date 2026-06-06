class MediaInfo {
  final String title;
  final String artist;
  final String? albumArtUrl;
  final bool isPlaying;

  const MediaInfo({
    required this.title,
    required this.artist,
    this.albumArtUrl,
    required this.isPlaying,
  });

  static const MediaInfo none = MediaInfo(title: '', artist: '', isPlaying: false);

  bool get hasTrack => title.isNotEmpty;

  MediaInfo copyWith({String? title, String? artist, String? albumArtUrl, bool? isPlaying}) {
    return MediaInfo(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}
