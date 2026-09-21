import 'package:teddoro/domain/models/session_record.dart';
import 'package:teddoro/domain/models/task.dart';

/// Renders the session log as CSV text.
class CsvExporter {
  const CsvExporter();

  static const header =
      'id,type,started_at,ended_at,duration_seconds,completed,task,project,ticket';

  String export({
    required List<SessionRecord> sessions,
    required List<Task> tasks,
    required List<Project> projects,
  }) {
    final taskById = {for (final t in tasks) t.id: t};
    final projectById = {for (final p in projects) p.id: p};
    final rows = sessions.map((s) {
      final task = taskById[s.taskId];
      final project = projectById[s.projectId];
      return [
        s.id,
        s.type.key,
        s.startedAt.toIso8601String(),
        s.endedAt.toIso8601String(),
        s.durationSeconds.toString(),
        s.completed.toString(),
        task?.title ?? '',
        project?.name ?? '',
        task?.ticket ?? '',
      ].map(_escape).join(',');
    });
    return [header, ...rows].join('\n');
  }

  static String _escape(String value) {
    if (!value.contains(RegExp(r'[",\n]'))) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
