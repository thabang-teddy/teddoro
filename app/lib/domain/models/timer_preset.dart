import 'package:teddoro/domain/models/session_type.dart';

/// A named set of session durations, e.g. "Classic 25/5/15".
class TimerPreset {
  const TimerPreset({
    required this.id,
    required this.name,
    required this.workMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    this.longBreakEvery = 4,
    this.isBuiltIn = false,
  });

  final String id;
  final String name;
  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  /// Number of work sessions before a long break.
  final int longBreakEvery;
  final bool isBuiltIn;

  static const classic = TimerPreset(
    id: 'builtin-classic',
    name: 'Classic',
    workMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    isBuiltIn: true,
  );

  static const deepWork = TimerPreset(
    id: 'builtin-deep',
    name: 'Deep work',
    workMinutes: 50,
    shortBreakMinutes: 10,
    longBreakMinutes: 20,
    isBuiltIn: true,
  );

  static const ultradian = TimerPreset(
    id: 'builtin-ultradian',
    name: 'Ultradian',
    workMinutes: 90,
    shortBreakMinutes: 20,
    longBreakMinutes: 30,
    longBreakEvery: 2,
    isBuiltIn: true,
  );

  static const builtIns = [classic, deepWork, ultradian];

  int minutesFor(SessionType type) => switch (type) {
    SessionType.work => workMinutes,
    SessionType.shortBreak => shortBreakMinutes,
    SessionType.longBreak => longBreakMinutes,
  };

  Duration durationFor(SessionType type) => Duration(minutes: minutesFor(type));

  String get summary => '$workMinutes / $shortBreakMinutes / $longBreakMinutes';

  TimerPreset copyWith({
    String? name,
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? longBreakEvery,
  }) => TimerPreset(
    id: id,
    name: name ?? this.name,
    workMinutes: workMinutes ?? this.workMinutes,
    shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
    longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
    longBreakEvery: longBreakEvery ?? this.longBreakEvery,
    isBuiltIn: isBuiltIn,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'work': workMinutes,
    'short': shortBreakMinutes,
    'long': longBreakMinutes,
    'every': longBreakEvery,
    'builtIn': isBuiltIn,
  };

  factory TimerPreset.fromJson(Map<String, Object?> json) => TimerPreset(
    id: json['id'] as String? ?? 'unknown',
    name: json['name'] as String? ?? 'Preset',
    workMinutes: json['work'] as int? ?? 25,
    shortBreakMinutes: json['short'] as int? ?? 5,
    longBreakMinutes: json['long'] as int? ?? 15,
    longBreakEvery: json['every'] as int? ?? 4,
    isBuiltIn: json['builtIn'] as bool? ?? false,
  );
}
