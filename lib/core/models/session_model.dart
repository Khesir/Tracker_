import 'music_entry_model.dart';

class SessionModel {
  final String id;
  final String projectId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final String noteJson;
  final List<MusicEntryModel> musicLog;
  final DateTime? deletedAt;

  const SessionModel({
    required this.id,
    required this.projectId,
    required this.startedAt,
    this.endedAt,
    required this.durationSeconds,
    required this.noteJson,
    required this.musicLog,
    this.deletedAt,
  });

  bool get isActive => endedAt == null;

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'durationSeconds': durationSeconds,
        'noteJson': noteJson,
        'musicLog': musicLog.map((e) => e.toJson()).toList(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
        id: json['id'] as String,
        projectId: json['projectId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
        durationSeconds: json['durationSeconds'] as int,
        noteJson: json['noteJson'] as String? ?? '',
        musicLog: (json['musicLog'] as List<dynamic>? ?? [])
            .map((e) => MusicEntryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
      );

  SessionModel copyWith({
    DateTime? endedAt,
    int? durationSeconds,
    String? noteJson,
    List<MusicEntryModel>? musicLog,
    DateTime? deletedAt,
  }) {
    return SessionModel(
      id: id,
      projectId: projectId,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      noteJson: noteJson ?? this.noteJson,
      musicLog: musicLog ?? this.musicLog,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
