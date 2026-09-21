import 'dart:convert';

import 'package:teddoro/data/key_value_store.dart';
import 'package:teddoro/domain/models/app_settings.dart';
import 'package:teddoro/domain/models/session_record.dart';
import 'package:teddoro/domain/models/task.dart';
import 'package:teddoro/domain/timer/timer_snapshot.dart';

/// Shared JSON helpers for the document repositories below.
abstract class _JsonRepository {
  const _JsonRepository(this.store);

  final KeyValueStore store;

  Future<Map<String, Object?>?> readObject(String key) async {
    final raw = await store.read(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } on FormatException {
      return null;
    }
  }

  Future<List<Map<String, Object?>>> readList(String key) async {
    final raw = await store.read(key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => m.cast<String, Object?>())
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> writeJson(String key, Object value) =>
      store.write(key, jsonEncode(value));
}

class SettingsRepository extends _JsonRepository {
  const SettingsRepository(super.store);

  static const _key = 'settings';

  Future<AppSettings> load() async {
    final json = await readObject(_key);
    return json == null ? const AppSettings() : AppSettings.fromJson(json);
  }

  Future<void> save(AppSettings settings) => writeJson(_key, settings.toJson());
}

class TimerStateRepository extends _JsonRepository {
  const TimerStateRepository(super.store);

  static const _key = 'timer';

  Future<TimerSnapshot?> load() async {
    final json = await readObject(_key);
    return json == null ? null : TimerSnapshot.fromJson(json);
  }

  Future<void> save(TimerSnapshot snapshot) =>
      writeJson(_key, snapshot.toJson());
}

class TaskRepository extends _JsonRepository {
  const TaskRepository(super.store);

  static const _tasksKey = 'tasks';
  static const _projectsKey = 'projects';
  static const _activeKey = 'active_task';

  Future<List<Task>> loadTasks() async =>
      (await readList(_tasksKey)).map(Task.fromJson).toList();

  Future<void> saveTasks(List<Task> tasks) =>
      writeJson(_tasksKey, tasks.map((t) => t.toJson()).toList());

  Future<List<Project>> loadProjects() async =>
      (await readList(_projectsKey)).map(Project.fromJson).toList();

  Future<void> saveProjects(List<Project> projects) =>
      writeJson(_projectsKey, projects.map((p) => p.toJson()).toList());

  Future<String?> loadActiveTaskId() async =>
      (await readObject(_activeKey))?['id'] as String?;

  Future<void> saveActiveTaskId(String? id) =>
      writeJson(_activeKey, {'id': id});
}

class SessionRepository extends _JsonRepository {
  const SessionRepository(super.store);

  static const _key = 'sessions';

  Future<List<SessionRecord>> load() async =>
      (await readList(_key)).map(SessionRecord.fromJson).toList();

  Future<void> save(List<SessionRecord> sessions) =>
      writeJson(_key, sessions.map((s) => s.toJson()).toList());
}
