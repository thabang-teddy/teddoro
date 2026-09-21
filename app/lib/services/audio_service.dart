import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:teddoro/domain/models/sounds.dart';

/// Plays the end-of-session alarm and the looping ambient bed.
abstract interface class AudioService {
  Future<void> playAlarm(AlarmSound sound, double volume);
  Future<void> startAmbient(AmbientSound sound, double volume);
  Future<void> setAmbientVolume(double volume);
  Future<void> stopAmbient();
  Future<void> dispose();
}

class AudioPlayersService implements AudioService {
  AudioPlayersService()
    : _alarm = AudioPlayer(playerId: 'teddoro-alarm'),
      _ambient = AudioPlayer(playerId: 'teddoro-ambient') {
    // Alarm must cut through even when the phone is on silent where the OS
    // allows it, so route it as an alarm rather than media.
    _alarm.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          usageType: AndroidUsageType.alarm,
          contentType: AndroidContentType.sonification,
          audioFocus: AndroidAudioFocus.gainTransient,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.duckOthers},
        ),
      ),
    );
    _ambient.setReleaseMode(ReleaseMode.loop);
    _ambient.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          usageType: AndroidUsageType.media,
          contentType: AndroidContentType.music,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
  }

  final AudioPlayer _alarm;
  final AudioPlayer _ambient;

  @override
  Future<void> playAlarm(AlarmSound sound, double volume) async {
    try {
      await _alarm.stop();
      await _alarm.play(AssetSource(sound.assetPath), volume: volume);
    } on Exception catch (e) {
      debugPrint('Alarm playback failed: $e');
    }
  }

  @override
  Future<void> startAmbient(AmbientSound sound, double volume) async {
    final path = sound.assetPath;
    if (path == null) {
      await stopAmbient();
      return;
    }
    try {
      await _ambient.stop();
      await _ambient.play(AssetSource(path), volume: volume);
    } on Exception catch (e) {
      debugPrint('Ambient playback failed: $e');
    }
  }

  @override
  Future<void> setAmbientVolume(double volume) async {
    try {
      await _ambient.setVolume(volume);
    } on Exception catch (e) {
      debugPrint('Ambient volume change failed: $e');
    }
  }

  @override
  Future<void> stopAmbient() async {
    try {
      await _ambient.stop();
    } on Exception catch (e) {
      debugPrint('Ambient stop failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _alarm.dispose();
    await _ambient.dispose();
  }
}

/// Silent implementation for tests.
class NoopAudioService implements AudioService {
  const NoopAudioService();

  @override
  Future<void> playAlarm(AlarmSound sound, double volume) async {}
  @override
  Future<void> startAmbient(AmbientSound sound, double volume) async {}
  @override
  Future<void> setAmbientVolume(double volume) async {}
  @override
  Future<void> stopAmbient() async {}
  @override
  Future<void> dispose() async {}
}
