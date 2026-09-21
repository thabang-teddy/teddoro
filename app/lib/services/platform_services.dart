import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:teddoro/domain/timer/timer_snapshot.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while a session runs.
abstract interface class WakelockService {
  Future<void> setEnabled(bool enabled);
}

class WakelockPlusService implements WakelockService {
  const WakelockPlusService();

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      await WakelockPlus.toggle(enable: enabled);
    } on Exception catch (e) {
      debugPrint('Wakelock toggle failed: $e');
    }
  }
}

/// Pushes timer state to the native home-screen / lock-screen widgets and
/// the iOS Live Activity. The native side reads these keys; see
/// `android/app/src/main/kotlin/.../TeddoroWidgetProvider.kt` and the README
/// for the iOS extension.
abstract interface class WidgetBridge {
  Future<void> publish(TimerSnapshot snapshot);
}

class HomeWidgetBridge implements WidgetBridge {
  const HomeWidgetBridge();

  static const androidProvider = 'TeddoroWidgetProvider';
  static const iosWidget = 'TeddoroWidget';

  @override
  Future<void> publish(TimerSnapshot snapshot) async {
    try {
      await HomeWidget.saveWidgetData<String>('status', snapshot.status.name);
      await HomeWidget.saveWidgetData<String>('type', snapshot.type.label);
      await HomeWidget.saveWidgetData<int>(
        'endsAt',
        snapshot.endsAt?.millisecondsSinceEpoch ?? 0,
      );
      await HomeWidget.saveWidgetData<int>(
        'remaining',
        snapshot.remainingSeconds(DateTime.now()),
      );
      await HomeWidget.updateWidget(
        androidName: androidProvider,
        iOSName: iosWidget,
      );
    } on MissingPluginException {
      // Widgets not wired up on this platform yet; nothing to do.
    } on Exception catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }
}

/// Native app/website blocking. The Dart side only talks to a method
/// channel; each platform decides whether it can honour the request
/// (iOS Screen Time / FamilyControls, Android accessibility service). When
/// the native side is absent the feature reports itself unsupported and the
/// UI hides it.
abstract interface class AppBlockingService {
  Future<bool> isSupported();

  /// Opens the native picker and returns the chosen app identifiers.
  Future<List<String>> pickApps(List<String> current);

  Future<void> setBlocking({required bool enabled, required List<String> apps});
}

class MethodChannelAppBlockingService implements AppBlockingService {
  const MethodChannelAppBlockingService();

  static const _channel = MethodChannel('teddoro/app_blocking');

  @override
  Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('isSupported failed: ${e.message}');
      return false;
    }
  }

  @override
  Future<List<String>> pickApps(List<String> current) async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>('pickApps', {
        'current': current,
      });
      return result?.whereType<String>().toList() ?? current;
    } on MissingPluginException {
      return current;
    } on PlatformException catch (e) {
      debugPrint('pickApps failed: ${e.message}');
      return current;
    }
  }

  @override
  Future<void> setBlocking({
    required bool enabled,
    required List<String> apps,
  }) async {
    try {
      await _channel.invokeMethod<void>('setBlocking', {
        'enabled': enabled,
        'apps': apps,
      });
    } on MissingPluginException {
      // Unsupported platform.
    } on PlatformException catch (e) {
      debugPrint('setBlocking failed: ${e.message}');
    }
  }
}

class NoopWakelockService implements WakelockService {
  const NoopWakelockService();
  @override
  Future<void> setEnabled(bool enabled) async {}
}

class NoopWidgetBridge implements WidgetBridge {
  const NoopWidgetBridge();
  @override
  Future<void> publish(TimerSnapshot snapshot) async {}
}

class NoopAppBlockingService implements AppBlockingService {
  const NoopAppBlockingService();
  @override
  Future<bool> isSupported() async => false;
  @override
  Future<List<String>> pickApps(List<String> current) async => current;
  @override
  Future<void> setBlocking({
    required bool enabled,
    required List<String> apps,
  }) async {}
}
