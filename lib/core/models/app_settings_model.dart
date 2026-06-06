class AppSettingsModel {
  final String themeKey;
  final int inactivityTimeoutSeconds;
  final String inactivityBehavior; // 'disabled', 'pause', 'stop'
  final bool floatLocked;
  final double floatOffsetX;
  final double floatOffsetY;
  final String? hotkeyKey;
  final bool alwaysOnTop;
  final bool roundToNearest;
  final bool anchorVinyl;
  final bool miniOpacityEnabled;
  final double miniIdleOpacity;

  const AppSettingsModel({
    this.themeKey = 'dark',
    this.inactivityTimeoutSeconds = 300,
    this.inactivityBehavior = 'stop',
    this.floatLocked = false,
    this.floatOffsetX = 40,
    this.floatOffsetY = 40,
    this.hotkeyKey,
    this.alwaysOnTop = true,
    this.roundToNearest = false,
    this.anchorVinyl = true,
    this.miniOpacityEnabled = false,
    this.miniIdleOpacity = 0.3,
  });

  Map<String, dynamic> toJson() => {
        'themeKey': themeKey,
        'inactivityTimeoutSeconds': inactivityTimeoutSeconds,
        'inactivityBehavior': inactivityBehavior,
        'floatLocked': floatLocked,
        'floatOffsetX': floatOffsetX,
        'floatOffsetY': floatOffsetY,
        'hotkeyKey': hotkeyKey,
        'alwaysOnTop': alwaysOnTop,
        'roundToNearest': roundToNearest,
        'anchorVinyl': anchorVinyl,
        'miniOpacityEnabled': miniOpacityEnabled,
        'miniIdleOpacity': miniIdleOpacity,
      };

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) => AppSettingsModel(
        themeKey: json['themeKey'] as String? ?? 'dark',
        inactivityTimeoutSeconds: json['inactivityTimeoutSeconds'] as int? ?? 300,
        inactivityBehavior: json['inactivityBehavior'] as String? ?? 'stop',
        floatLocked: json['floatLocked'] as bool? ?? false,
        floatOffsetX: (json['floatOffsetX'] as num?)?.toDouble() ?? 40,
        floatOffsetY: (json['floatOffsetY'] as num?)?.toDouble() ?? 40,
        hotkeyKey: json['hotkeyKey'] as String?,
        alwaysOnTop: json['alwaysOnTop'] as bool? ?? true,
        roundToNearest: json['roundToNearest'] as bool? ?? false,
        anchorVinyl: json['anchorVinyl'] as bool? ?? true,
        miniOpacityEnabled: json['miniOpacityEnabled'] as bool? ?? false,
        miniIdleOpacity: (json['miniIdleOpacity'] as num?)?.toDouble() ?? 0.3,
      );

  AppSettingsModel copyWith({
    String? themeKey,
    int? inactivityTimeoutSeconds,
    String? inactivityBehavior,
    bool? floatLocked,
    double? floatOffsetX,
    double? floatOffsetY,
    String? hotkeyKey,
    bool? alwaysOnTop,
    bool? roundToNearest,
    bool? anchorVinyl,
    bool? miniOpacityEnabled,
    double? miniIdleOpacity,
  }) {
    return AppSettingsModel(
      themeKey: themeKey ?? this.themeKey,
      inactivityTimeoutSeconds: inactivityTimeoutSeconds ?? this.inactivityTimeoutSeconds,
      inactivityBehavior: inactivityBehavior ?? this.inactivityBehavior,
      floatLocked: floatLocked ?? this.floatLocked,
      floatOffsetX: floatOffsetX ?? this.floatOffsetX,
      floatOffsetY: floatOffsetY ?? this.floatOffsetY,
      hotkeyKey: hotkeyKey ?? this.hotkeyKey,
      alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
      roundToNearest: roundToNearest ?? this.roundToNearest,
      anchorVinyl: anchorVinyl ?? this.anchorVinyl,
      miniOpacityEnabled: miniOpacityEnabled ?? this.miniOpacityEnabled,
      miniIdleOpacity: miniIdleOpacity ?? this.miniIdleOpacity,
    );
  }
}
