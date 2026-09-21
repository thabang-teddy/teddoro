import 'package:flutter/foundation.dart';
import 'package:teddoro/core/ids.dart';
import 'package:teddoro/data/repositories.dart';
import 'package:teddoro/domain/models/app_settings.dart';
import 'package:teddoro/domain/models/timer_preset.dart';

/// Owns [AppSettings]; every change is persisted immediately.
class SettingsController extends ChangeNotifier {
  SettingsController({required this._repository, required this._ids});

  final SettingsRepository _repository;
  final IdGenerator _ids;

  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  Future<void> load() async {
    _settings = await _repository.load();
    notifyListeners();
  }

  /// Apply a transformation and persist the result.
  Future<void> update(AppSettings Function(AppSettings current) change) async {
    _settings = change(_settings);
    notifyListeners();
    await _repository.save(_settings);
  }

  Future<void> selectPreset(String id) =>
      update((s) => s.copyWith(activePresetId: id));

  Future<TimerPreset> addCustomPreset({
    required String name,
    required int work,
    required int shortBreak,
    required int longBreak,
    required int longBreakEvery,
  }) async {
    final preset = TimerPreset(
      id: _ids.next(),
      name: name,
      workMinutes: work,
      shortBreakMinutes: shortBreak,
      longBreakMinutes: longBreak,
      longBreakEvery: longBreakEvery,
    );
    await update(
      (s) => s.copyWith(
        customPresets: [...s.customPresets, preset],
        activePresetId: preset.id,
      ),
    );
    return preset;
  }

  Future<void> updateCustomPreset(TimerPreset preset) => update(
    (s) => s.copyWith(
      customPresets: [
        for (final p in s.customPresets) p.id == preset.id ? preset : p,
      ],
    ),
  );

  Future<void> deleteCustomPreset(String id) => update((s) {
    final remaining = s.customPresets.where((p) => p.id != id).toList();
    final active = s.activePresetId == id
        ? TimerPreset.classic.id
        : s.activePresetId;
    return s.copyWith(customPresets: remaining, activePresetId: active);
  });

  Future<void> recordBadges(Set<String> earned) =>
      update((s) => s.copyWith(earnedBadges: {...s.earnedBadges, ...earned}));
}
