/// The three kinds of Pomodoro session.
enum SessionType {
  work,
  shortBreak,
  longBreak;

  bool get isBreak => this != SessionType.work;

  String get label => switch (this) {
    SessionType.work => 'Work',
    SessionType.shortBreak => 'Short break',
    SessionType.longBreak => 'Long break',
  };

  /// Stable key used for JSON persistence.
  String get key => name;

  static SessionType fromKey(String? key) => SessionType.values.firstWhere(
    (t) => t.name == key,
    orElse: () => SessionType.work,
  );
}
