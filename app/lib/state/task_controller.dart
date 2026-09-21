import 'package:flutter/foundation.dart';
import 'package:teddoro/core/clock.dart';
import 'package:teddoro/core/ids.dart';
import 'package:teddoro/data/repositories.dart';
import 'package:teddoro/domain/models/task.dart';

/// Tasks, projects and which task is currently being worked on.
class TaskController extends ChangeNotifier {
  TaskController({
    required this._repository,
    required this._ids,
    required this._clock,
  });

  final TaskRepository _repository;
  final IdGenerator _ids;
  final Clock _clock;

  List<Task> _tasks = const [];
  List<Project> _projects = const [];
  String? _activeTaskId;

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Project> get projects => List.unmodifiable(_projects);
  String? get activeTaskId => _activeTaskId;

  Task? get activeTask => taskById(_activeTaskId);

  Task? taskById(String? id) {
    if (id == null) return null;
    for (final t in _tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Project? projectById(String? id) {
    if (id == null) return null;
    for (final p in _projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Tasks that are neither done nor archived, in user order.
  List<Task> get openTasks =>
      _tasks.where((t) => t.isActive).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<Task> get doneTasks =>
      _tasks.where((t) => t.isDone && !t.isArchived).toList();

  Set<String> get allTags => {for (final t in _tasks) ...t.tags};

  Future<void> load() async {
    _tasks = await _repository.loadTasks();
    _projects = await _repository.loadProjects();
    _activeTaskId = await _repository.loadActiveTaskId();
    if (taskById(_activeTaskId)?.isActive != true) _activeTaskId = null;
    notifyListeners();
  }

  Future<void> setActiveTask(String? id) async {
    _activeTaskId = id;
    notifyListeners();
    await _repository.saveActiveTaskId(id);
  }

  Future<Task> addTask({
    required String title,
    int estimatedPomodoros = 1,
    String? projectId,
    List<String> tags = const [],
    String ticket = '',
  }) async {
    final now = _clock.now();
    final maxOrder = _tasks.fold(
      0,
      (m, t) => t.sortOrder > m ? t.sortOrder : m,
    );
    final task = Task(
      id: _ids.next(),
      title: title.trim(),
      estimatedPomodoros: estimatedPomodoros,
      projectId: projectId,
      tags: tags,
      ticket: ticket.trim(),
      sortOrder: maxOrder + 1,
      createdAt: now,
      updatedAt: now,
    );
    await _saveTasks([..._tasks, task]);
    return task;
  }

  Future<void> updateTask(Task updated) => _saveTasks([
    for (final t in _tasks)
      t.id == updated.id ? updated.copyWith(updatedAt: _clock.now()) : t,
  ]);

  Future<void> toggleDone(String id) async {
    final task = taskById(id);
    if (task == null) return;
    await updateTask(task.copyWith(isDone: !task.isDone));
    if (!task.isDone && _activeTaskId == id) await setActiveTask(null);
  }

  Future<void> archiveTask(String id) async {
    final task = taskById(id);
    if (task == null) return;
    await updateTask(task.copyWith(isArchived: true));
    if (_activeTaskId == id) await setActiveTask(null);
  }

  Future<void> deleteTask(String id) async {
    await _saveTasks(_tasks.where((t) => t.id != id).toList());
    if (_activeTaskId == id) await setActiveTask(null);
  }

  /// Called by the timer when a work session completes.
  Future<void> incrementCompleted(String id) async {
    final task = taskById(id);
    if (task == null) return;
    await updateTask(
      task.copyWith(completedPomodoros: task.completedPomodoros + 1),
    );
  }

  /// Persist a new order for the open tasks after a drag-and-drop.
  /// [newIndex] is the final position in the list after removal.
  Future<void> reorderOpenTasks(int oldIndex, int newIndex) async {
    final open = openTasks;
    if (oldIndex < 0 || oldIndex >= open.length) return;
    final moved = open.removeAt(oldIndex);
    open.insert(newIndex.clamp(0, open.length), moved);
    final orderById = {for (final (i, t) in open.indexed) t.id: i};
    await _saveTasks([
      for (final t in _tasks)
        orderById.containsKey(t.id)
            ? t.copyWith(sortOrder: orderById[t.id])
            : t,
    ]);
  }

  Future<Project> addProject({required String name, required int color}) async {
    final project = Project(id: _ids.next(), name: name.trim(), color: color);
    await _saveProjects([..._projects, project]);
    return project;
  }

  Future<void> updateProject(Project updated) => _saveProjects([
    for (final p in _projects) p.id == updated.id ? updated : p,
  ]);

  Future<void> deleteProject(String id) async {
    await _saveProjects(_projects.where((p) => p.id != id).toList());
    await _saveTasks([
      for (final t in _tasks)
        t.projectId == id ? t.copyWith(clearProject: true) : t,
    ]);
  }

  Future<void> _saveTasks(List<Task> tasks) async {
    _tasks = tasks;
    notifyListeners();
    await _repository.saveTasks(tasks);
  }

  Future<void> _saveProjects(List<Project> projects) async {
    _projects = projects;
    notifyListeners();
    await _repository.saveProjects(projects);
  }
}
