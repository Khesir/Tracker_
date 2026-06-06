class MusicEntryModel {
  final String title;
  final String artist;
  final String? albumArtUrl;
  final DateTime startedAt;
  final DateTime? endedAt;

  const MusicEntryModel({
    required this.title,
    required this.artist,
    this.albumArtUrl,
    required this.startedAt,
    this.endedAt,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'albumArtUrl': albumArtUrl,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
      };

  factory MusicEntryModel.fromJson(Map<String, dynamic> json) => MusicEntryModel(
        title: json['title'] as String,
        artist: json['artist'] as String,
        albumArtUrl: json['albumArtUrl'] as String?,
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
      );
}
