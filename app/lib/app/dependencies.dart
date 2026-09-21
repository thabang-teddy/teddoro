import 'package:teddoro/core/clock.dart';
import 'package:teddoro/core/ids.dart';
import 'package:teddoro/data/key_value_store.dart';
import 'package:teddoro/data/repositories.dart';
import 'package:teddoro/services/audio_service.dart';
import 'package:teddoro/services/notification_service.dart';
import 'package:teddoro/services/platform_services.dart';
import 'package:teddoro/state/session_log_controller.dart';
import 'package:teddoro/state/settings_controller.dart';
import 'package:teddoro/state/task_controller.dart';
import 'package:teddoro/state/timer_controller.dart';

/// Composition root. Builds every controller with real or fake services so
/// the app and the widget tests share one wiring path.
class AppDependencies {
  const AppDependencies({
    required this.settings,
    required this.tasks,
    required this.log,
    required this.timer,
    required this.blocking,
    required this.audio,
  });

  final SettingsController settings;
  final TaskController tasks;
  final SessionLogController log;
  final TimerController timer;
  final AppBlockingService blocking;
  final AudioService audio;

  static Future<AppDependencies> create({
    required KeyValueStore store,
    Clock clock = const SystemClock(),
    IdGenerator? ids,
    AudioService? audio,
    NotificationService? notifications,
    WakelockService? wakelock,
    WidgetBridge? widgets,
    AppBlockingService? blocking,
  }) async {
    final idGen = ids ?? IdGenerator();
    final notify = notifications ?? LocalNotificationService();
    final audioService = audio ?? AudioPlayersService();
    final blockingService = blocking ?? const MethodChannelAppBlockingService();

    final settings = SettingsController(
      repository: SettingsRepository(store),
      ids: idGen,
    );
    final tasks = TaskController(
      repository: TaskRepository(store),
      ids: idGen,
      clock: clock,
    );
    final log = SessionLogController(repository: SessionRepository(store));

    await Future.wait([settings.load(), tasks.load(), log.load()]);
    await notify.initialize();

    final timer = TimerController(
      settings: settings,
      tasks: tasks,
      log: log,
      repository: TimerStateRepository(store),
      clock: clock,
      ids: idGen,
      audio: audioService,
      notifications: notify,
      wakelock: wakelock ?? const WakelockPlusService(),
      widgets: widgets ?? const HomeWidgetBridge(),
      blocking: blockingService,
    );
    await timer.restore();

    return AppDependencies(
      settings: settings,
      tasks: tasks,
      log: log,
      timer: timer,
      blocking: blockingService,
      audio: audioService,
    );
  }
}
