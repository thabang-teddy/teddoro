import 'package:teddoro/domain/models/session_type.dart';

/// One completed (or skipped-but-partially-done) session in the log.
class SessionRecord {
  const SessionRecord({
    required this.id,
    required this.type,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    this.taskId,
    this.projectId,
    this.completed = true,
  });

  final String id;
  final SessionType type;
  final DateTime startedAt;
  final DateTime endedAt;

  /// Seconds actually spent (excludes paused time).
  final int durationSeconds;
  final String? taskId;
  final String? projectId;

  /// False when the session was skipped before it finished.
  final bool completed;

  bool get countsAsPomodoro => type == SessionType.work && completed;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.key,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'duration': durationSeconds,
    'taskId': taskId,
    'projectId': projectId,
    'completed': completed,
  };

  factory SessionRecord.fromJson(Map<String, Object?> json) {
    final started =
        DateTime.tryParse(json['startedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return SessionRecord(
      id: json['id'] as String? ?? '',
      type: SessionType.fromKey(json['type'] as String?),
      startedAt: started,
      endedAt: DateTime.tryParse(json['endedAt'] as String? ?? '') ?? started,
      durationSeconds: json['duration'] as int? ?? 0,
      taskId: json['taskId'] as String?,
      projectId: json['projectId'] as String?,
      completed: json['completed'] as bool? ?? true,
    );
  }
}
