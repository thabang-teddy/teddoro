import 'package:flutter/foundation.dart';
import 'package:teddoro/data/repositories.dart';
import 'package:teddoro/domain/models/session_record.dart';
import 'package:teddoro/domain/stats/stats_calculator.dart';

/// The append-only log of finished sessions and the stats derived from it.
class SessionLogController extends ChangeNotifier {
  SessionLogController({required this._repository});

  final SessionRepository _repository;

  List<SessionRecord> _sessions = const [];
  StatsCalculator _stats = const StatsCalculator([]);

  List<SessionRecord> get sessions => List.unmodifiable(_sessions);
  StatsCalculator get stats => _stats;

  Future<void> load() async {
    _replace(await _repository.load());
  }

  Future<void> add(SessionRecord record) async {
    _replace([..._sessions, record]);
    await _repository.save(_sessions);
  }

  void _replace(List<SessionRecord> sessions) {
    _sessions = sessions;
    _stats = StatsCalculator(sessions);
    notifyListeners();
  }
}
