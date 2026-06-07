class ProjectModel {
  final String id;
  final String name;
  final String colorHex;
  final int? targetMinutes;
  final DateTime createdAt;
  final DateTime? deletedAt;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.colorHex,
    this.targetMinutes,
    required this.createdAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorHex': colorHex,
        'targetMinutes': targetMinutes,
        'createdAt': createdAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
        id: json['id'] as String,
        name: json['name'] as String,
        colorHex: json['colorHex'] as String,
        targetMinutes: json['targetMinutes'] as int?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        deletedAt: json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'] as String)
            : null,
      );

  ProjectModel copyWith({
    String? name,
    String? colorHex,
    int? targetMinutes,
    DateTime? deletedAt,
  }) {
    return ProjectModel(
      id: id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      createdAt: createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
