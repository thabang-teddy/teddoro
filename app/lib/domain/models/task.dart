/// A piece of work the user wants to spend pomodoros on.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.estimatedPomodoros = 1,
    this.completedPomodoros = 0,
    this.isDone = false,
    this.isArchived = false,
    this.projectId,
    this.tags = const [],
    this.ticket = '',
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final int estimatedPomodoros;
  final int completedPomodoros;
  final bool isDone;
  final bool isArchived;
  final String? projectId;
  final List<String> tags;

  /// Free-text external reference, e.g. "JIRA-123".
  final String ticket;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => !isDone && !isArchived;

  Task copyWith({
    String? title,
    int? estimatedPomodoros,
    int? completedPomodoros,
    bool? isDone,
    bool? isArchived,
    String? projectId,
    bool clearProject = false,
    List<String>? tags,
    String? ticket,
    int? sortOrder,
    DateTime? updatedAt,
  }) => Task(
    id: id,
    title: title ?? this.title,
    estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
    completedPomodoros: completedPomodoros ?? this.completedPomodoros,
    isDone: isDone ?? this.isDone,
    isArchived: isArchived ?? this.isArchived,
    projectId: clearProject ? null : (projectId ?? this.projectId),
    tags: tags ?? this.tags,
    ticket: ticket ?? this.ticket,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'estimated': estimatedPomodoros,
    'completed': completedPomodoros,
    'done': isDone,
    'archived': isArchived,
    'projectId': projectId,
    'tags': tags,
    'ticket': ticket,
    'sortOrder': sortOrder,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Task.fromJson(Map<String, Object?> json) {
    final created =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();
    return Task(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      estimatedPomodoros: json['estimated'] as int? ?? 1,
      completedPomodoros: json['completed'] as int? ?? 0,
      isDone: json['done'] as bool? ?? false,
      isArchived: json['archived'] as bool? ?? false,
      projectId: json['projectId'] as String?,
      tags: (json['tags'] as List?)?.whereType<String>().toList() ?? const [],
      ticket: json['ticket'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      createdAt: created,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? created,
    );
  }
}

/// Groups tasks. Has a colour so it can be told apart at a glance.
class Project {
  const Project({required this.id, required this.name, required this.color});

  final String id;
  final String name;

  /// ARGB colour value.
  final int color;

  Project copyWith({String? name, int? color}) =>
      Project(id: id, name: name ?? this.name, color: color ?? this.color);

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'color': color};

  factory Project.fromJson(Map<String, Object?> json) => Project(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    color: json['color'] as int? ?? 0xFF8E6C88,
  );
}
