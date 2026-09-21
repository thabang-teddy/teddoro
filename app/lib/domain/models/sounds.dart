/// Alarm played when a session ends.
enum AlarmSound {
  bell('Bell', 'sounds/alarm_bell.wav'),
  chime('Chime', 'sounds/alarm_chime.wav'),
  digital('Digital', 'sounds/alarm_digital.wav');

  const AlarmSound(this.label, this.assetPath);

  final String label;

  /// Path relative to the `assets/` folder.
  final String assetPath;

  static AlarmSound fromKey(String? key) =>
      values.firstWhere((s) => s.name == key, orElse: () => bell);
}

/// Looping background sound played during work sessions.
enum AmbientSound {
  none('Off', null),
  rain('Rain', 'sounds/ambient_rain.wav'),
  cafe('Café', 'sounds/ambient_cafe.wav'),
  whiteNoise('White noise', 'sounds/ambient_white.wav'),
  ticking('Ticking clock', 'sounds/ambient_ticking.wav');

  const AmbientSound(this.label, this.assetPath);

  final String label;
  final String? assetPath;

  static AmbientSound fromKey(String? key) =>
      values.firstWhere((s) => s.name == key, orElse: () => none);
}
