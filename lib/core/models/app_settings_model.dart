class AppSettingsModel {
  final String themeKey;
  final int inactivityTimeoutSeconds;
  final String inactivityBehavior; // 'disabled', 'pause', 'stop'
  final bool floatLocked;
  final double floatOffsetX;
  final double floatOffsetY;
  final String? hotkeyKey;

  const AppSettingsModel({
    this.themeKey = 'dark',
    this.inactivityTimeoutSeconds = 300,
    this.inactivityBehavior = 'stop',
    this.floatLocked = false,
    this.floatOffsetX = 40,
    this.floatOffsetY = 40,
    this.hotkeyKey,
  });

  Map<String, dynamic> toJson() => {
        'themeKey': themeKey,
        'inactivityTimeoutSeconds': inactivityTimeoutSeconds,
        'inactivityBehavior': inactivityBehavior,
        'floatLocked': floatLocked,
        'floatOffsetX': floatOffsetX,
        'floatOffsetY': floatOffsetY,
        'hotkeyKey': hotkeyKey,
      };

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) => AppSettingsModel(
        themeKey: json['themeKey'] as String? ?? 'dark',
        inactivityTimeoutSeconds: json['inactivityTimeoutSeconds'] as int? ?? 300,
        inactivityBehavior: json['inactivityBehavior'] as String? ?? 'stop',
        floatLocked: json['floatLocked'] as bool? ?? false,
        floatOffsetX: (json['floatOffsetX'] as num?)?.toDouble() ?? 40,
        floatOffsetY: (json['floatOffsetY'] as num?)?.toDouble() ?? 40,
        hotkeyKey: json['hotkeyKey'] as String?,
      );

  AppSettingsModel copyWith({
    String? themeKey,
    int? inactivityTimeoutSeconds,
    String? inactivityBehavior,
    bool? floatLocked,
    double? floatOffsetX,
    double? floatOffsetY,
    String? hotkeyKey,
  }) {
    return AppSettingsModel(
      themeKey: themeKey ?? this.themeKey,
      inactivityTimeoutSeconds: inactivityTimeoutSeconds ?? this.inactivityTimeoutSeconds,
      inactivityBehavior: inactivityBehavior ?? this.inactivityBehavior,
      floatLocked: floatLocked ?? this.floatLocked,
      floatOffsetX: floatOffsetX ?? this.floatOffsetX,
      floatOffsetY: floatOffsetY ?? this.floatOffsetY,
      hotkeyKey: hotkeyKey ?? this.hotkeyKey,
    );
  }
}
