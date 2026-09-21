import 'package:teddoro/domain/models/session_type.dart';
import 'package:teddoro/domain/models/sounds.dart';
import 'package:teddoro/domain/models/timer_preset.dart';

/// App theme preference.
enum ThemePreference {
  system,
  light,
  dark;

  static ThemePreference fromKey(String? key) =>
      values.firstWhere((t) => t.name == key, orElse: () => system);
}

/// Every user-editable setting. Immutable; use [copyWith].
class AppSettings {
  const AppSettings({
    this.activePresetId = 'builtin-classic',
    this.customPresets = const [],
    this.autoStartBreaks = false,
    this.autoStartWork = false,
    this.alarmSound = AlarmSound.bell,
    this.alarmVolume = 0.8,
    this.ambientSound = AmbientSound.none,
    this.ambientVolume = 0.5,
    this.keepAwake = true,
    this.strictMode = false,
    this.focusMessage = 'Stay on it — {time} left',
    this.dailyGoal = 8,
    this.theme = ThemePreference.system,
    this.workColor = 0xFFE0523F,
    this.shortBreakColor = 0xFF3E9C6A,
    this.longBreakColor = 0xFF3D7BC7,
    this.breakRemindersEnabled = true,
    this.breakReminders = defaultBreakReminders,
    this.blockedApps = const [],
    this.blockingEnabled = false,
    this.earnedBadges = const {},
  });

  static const defaultBreakReminders = [
    'Stand up and stretch',
    'Drink some water',
    'Look away from the screen for 20 seconds',
    'Roll your shoulders and unclench your jaw',
    'Take three slow breaths',
  ];

  final String activePresetId;
  final List<TimerPreset> customPresets;
  final bool autoStartBreaks;
  final bool autoStartWork;
  final AlarmSound alarmSound;
  final double alarmVolume;
  final AmbientSound ambientSound;
  final double ambientVolume;
  final bool keepAwake;
  final bool strictMode;
  final String focusMessage;
  final int dailyGoal;
  final ThemePreference theme;
  final int workColor;
  final int shortBreakColor;
  final int longBreakColor;
  final bool breakRemindersEnabled;
  final List<String> breakReminders;
  final List<String> blockedApps;
  final bool blockingEnabled;
  final Set<String> earnedBadges;

  List<TimerPreset> get allPresets => [
    ...TimerPreset.builtIns,
    ...customPresets,
  ];

  TimerPreset get activePreset => allPresets.firstWhere(
    (p) => p.id == activePresetId,
    orElse: () => TimerPreset.classic,
  );

  int colorFor(SessionType type) => switch (type) {
    SessionType.work => workColor,
    SessionType.shortBreak => shortBreakColor,
    SessionType.longBreak => longBreakColor,
  };

  AppSettings copyWith({
    String? activePresetId,
    List<TimerPreset>? customPresets,
    bool? autoStartBreaks,
    bool? autoStartWork,
    AlarmSound? alarmSound,
    double? alarmVolume,
    AmbientSound? ambientSound,
    double? ambientVolume,
    bool? keepAwake,
    bool? strictMode,
    String? focusMessage,
    int? dailyGoal,
    ThemePreference? theme,
    int? workColor,
    int? shortBreakColor,
    int? longBreakColor,
    bool? breakRemindersEnabled,
    List<String>? breakReminders,
    List<String>? blockedApps,
    bool? blockingEnabled,
    Set<String>? earnedBadges,
  }) => AppSettings(
    activePresetId: activePresetId ?? this.activePresetId,
    customPresets: customPresets ?? this.customPresets,
    autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
    autoStartWork: autoStartWork ?? this.autoStartWork,
    alarmSound: alarmSound ?? this.alarmSound,
    alarmVolume: alarmVolume ?? this.alarmVolume,
    ambientSound: ambientSound ?? this.ambientSound,
    ambientVolume: ambientVolume ?? this.ambientVolume,
    keepAwake: keepAwake ?? this.keepAwake,
    strictMode: strictMode ?? this.strictMode,
    focusMessage: focusMessage ?? this.focusMessage,
    dailyGoal: dailyGoal ?? this.dailyGoal,
    theme: theme ?? this.theme,
    workColor: workColor ?? this.workColor,
    shortBreakColor: shortBreakColor ?? this.shortBreakColor,
    longBreakColor: longBreakColor ?? this.longBreakColor,
    breakRemindersEnabled: breakRemindersEnabled ?? this.breakRemindersEnabled,
    breakReminders: breakReminders ?? this.breakReminders,
    blockedApps: blockedApps ?? this.blockedApps,
    blockingEnabled: blockingEnabled ?? this.blockingEnabled,
    earnedBadges: earnedBadges ?? this.earnedBadges,
  );

  Map<String, Object?> toJson() => {
    'activePresetId': activePresetId,
    'customPresets': customPresets.map((p) => p.toJson()).toList(),
    'autoStartBreaks': autoStartBreaks,
    'autoStartWork': autoStartWork,
    'alarmSound': alarmSound.name,
    'alarmVolume': alarmVolume,
    'ambientSound': ambientSound.name,
    'ambientVolume': ambientVolume,
    'keepAwake': keepAwake,
    'strictMode': strictMode,
    'focusMessage': focusMessage,
    'dailyGoal': dailyGoal,
    'theme': theme.name,
    'workColor': workColor,
    'shortBreakColor': shortBreakColor,
    'longBreakColor': longBreakColor,
    'breakRemindersEnabled': breakRemindersEnabled,
    'breakReminders': breakReminders,
    'blockedApps': blockedApps,
    'blockingEnabled': blockingEnabled,
    'earnedBadges': earnedBadges.toList(),
  };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    const d = AppSettings();
    return AppSettings(
      activePresetId: json['activePresetId'] as String? ?? d.activePresetId,
      customPresets: _presetList(json['customPresets']),
      autoStartBreaks: json['autoStartBreaks'] as bool? ?? d.autoStartBreaks,
      autoStartWork: json['autoStartWork'] as bool? ?? d.autoStartWork,
      alarmSound: AlarmSound.fromKey(json['alarmSound'] as String?),
      alarmVolume: (json['alarmVolume'] as num?)?.toDouble() ?? d.alarmVolume,
      ambientSound: AmbientSound.fromKey(json['ambientSound'] as String?),
      ambientVolume:
          (json['ambientVolume'] as num?)?.toDouble() ?? d.ambientVolume,
      keepAwake: json['keepAwake'] as bool? ?? d.keepAwake,
      strictMode: json['strictMode'] as bool? ?? d.strictMode,
      focusMessage: json['focusMessage'] as String? ?? d.focusMessage,
      dailyGoal: json['dailyGoal'] as int? ?? d.dailyGoal,
      theme: ThemePreference.fromKey(json['theme'] as String?),
      workColor: json['workColor'] as int? ?? d.workColor,
      shortBreakColor: json['shortBreakColor'] as int? ?? d.shortBreakColor,
      longBreakColor: json['longBreakColor'] as int? ?? d.longBreakColor,
      breakRemindersEnabled:
          json['breakRemindersEnabled'] as bool? ?? d.breakRemindersEnabled,
      breakReminders:
          _stringList(json['breakReminders']) ?? defaultBreakReminders,
      blockedApps: _stringList(json['blockedApps']) ?? const [],
      blockingEnabled: json['blockingEnabled'] as bool? ?? d.blockingEnabled,
      earnedBadges: (_stringList(json['earnedBadges']) ?? const []).toSet(),
    );
  }

  static List<TimerPreset> _presetList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => TimerPreset.fromJson(m.cast<String, Object?>()))
        .toList();
  }

  static List<String>? _stringList(Object? raw) {
    if (raw is! List) return null;
    return raw.whereType<String>().toList();
  }
}
