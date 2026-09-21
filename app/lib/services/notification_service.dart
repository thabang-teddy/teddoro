import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:teddoro/domain/models/session_type.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A one-off alert to fire at an absolute instant.
class ScheduledAlert {
  const ScheduledAlert({
    required this.at,
    required this.title,
    required this.body,
  });

  final DateTime at;
  final String title;
  final String body;
}

/// Session-end alerts plus the persistent "timer running" notification.
abstract interface class NotificationService {
  Future<void> initialize();

  /// Show an ongoing countdown notification that ends at [endsAt], and
  /// schedule each of [alerts] so they fire even if the app is in the
  /// background or killed. The first alert is normally "session finished";
  /// with auto-start on, a second one covers the follow-on session.
  Future<void> showRunning({
    required SessionType type,
    required DateTime endsAt,
    required List<ScheduledAlert> alerts,
  });

  Future<void> showPaused({required SessionType type, required int remaining});

  /// Remove the ongoing notification and cancel the scheduled alert.
  Future<void> clearRunning();
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _runningId = 1;
  static const _firstAlertId = 2;
  static const _maxAlerts = 2;

  static const _runningChannel = AndroidNotificationDetails(
    'teddoro_running',
    'Timer running',
    channelDescription: 'Shows the countdown while a session is active.',
    importance: Importance.low,
    priority: Priority.low,
    ongoing: true,
    autoCancel: false,
    onlyAlertOnce: true,
    playSound: false,
    enableVibration: false,
    showWhen: true,
    usesChronometer: true,
    chronometerCountDown: true,
  );

  static const _finishedChannel = AndroidNotificationDetails(
    'teddoro_finished',
    'Session finished',
    channelDescription: 'Alerts you when a work session or break ends.',
    importance: Importance.max,
    priority: Priority.high,
    category: AndroidNotificationCategory.alarm,
    fullScreenIntent: true,
  );

  @override
  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await _requestPermissions();
    } on Exception catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> showRunning({
    required SessionType type,
    required DateTime endsAt,
    required List<ScheduledAlert> alerts,
  }) async {
    try {
      await _cancelAlerts();
      await _plugin.show(
        id: _runningId,
        title: '${type.label} in progress',
        body: 'Teddoro is counting down',
        notificationDetails: NotificationDetails(
          android: _withWhen(_runningChannel, endsAt),
          iOS: const DarwinNotificationDetails(presentSound: false),
        ),
      );
      for (final (i, alert) in alerts.take(_maxAlerts).indexed) {
        await _plugin.zonedSchedule(
          id: _firstAlertId + i,
          title: alert.title,
          body: alert.body,
          scheduledDate: tz.TZDateTime.from(alert.at.toUtc(), tz.UTC),
          notificationDetails: const NotificationDetails(
            android: _finishedChannel,
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentSound: true,
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    } on Exception catch (e) {
      debugPrint('showRunning failed: $e');
    }
  }

  Future<void> _cancelAlerts() async {
    for (var i = 0; i < _maxAlerts; i++) {
      await _plugin.cancel(id: _firstAlertId + i);
    }
  }

  @override
  Future<void> showPaused({
    required SessionType type,
    required int remaining,
  }) async {
    try {
      await _cancelAlerts();
      await _plugin.show(
        id: _runningId,
        title: '${type.label} paused',
        body: '${(remaining / 60).ceil()} min left',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'teddoro_running',
            'Timer running',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            playSound: false,
          ),
        ),
      );
    } on Exception catch (e) {
      debugPrint('showPaused failed: $e');
    }
  }

  @override
  Future<void> clearRunning() async {
    try {
      await _plugin.cancel(id: _runningId);
      await _cancelAlerts();
    } on Exception catch (e) {
      debugPrint('clearRunning failed: $e');
    }
  }

  static AndroidNotificationDetails _withWhen(
    AndroidNotificationDetails base,
    DateTime endsAt,
  ) => AndroidNotificationDetails(
    base.channelId,
    base.channelName,
    channelDescription: base.channelDescription,
    importance: base.importance,
    priority: base.priority,
    ongoing: base.ongoing,
    autoCancel: base.autoCancel,
    onlyAlertOnce: base.onlyAlertOnce,
    playSound: base.playSound,
    enableVibration: base.enableVibration,
    showWhen: base.showWhen,
    usesChronometer: base.usesChronometer,
    chronometerCountDown: base.chronometerCountDown,
    when: endsAt.millisecondsSinceEpoch,
  );
}

/// Does nothing; used in tests.
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> initialize() async {}
  @override
  Future<void> showRunning({
    required SessionType type,
    required DateTime endsAt,
    required List<ScheduledAlert> alerts,
  }) async {}
  @override
  Future<void> showPaused({
    required SessionType type,
    required int remaining,
  }) async {}
  @override
  Future<void> clearRunning() async {}
}
