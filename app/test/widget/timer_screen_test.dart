import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teddoro/app/dependencies.dart';
import 'package:teddoro/app/teddoro_app.dart';
import 'package:teddoro/core/clock.dart';
import 'package:teddoro/data/key_value_store.dart';
import 'package:teddoro/services/audio_service.dart';
import 'package:teddoro/services/notification_service.dart';
import 'package:teddoro/services/platform_services.dart';

Future<AppDependencies> _boot(FixedClock clock, {MemoryKeyValueStore? store}) =>
    AppDependencies.create(
      store: store ?? MemoryKeyValueStore(),
      clock: clock,
      audio: const NoopAudioService(),
      notifications: const NoopNotificationService(),
      wakelock: const NoopWakelockService(),
      widgets: const NoopWidgetBridge(),
      blocking: const NoopAppBlockingService(),
    );

Future<void> _pumpApp(WidgetTester tester, AppDependencies deps) async {
  await tester.pumpWidget(TeddoroApp(deps: deps));
  await tester.pump();
}

/// Unmount the tree and stop the controller's ticker. Must run inside the
/// test body: flutter_test checks for pending timers before tearDowns run.
Future<void> _finish(WidgetTester tester, AppDependencies deps) async {
  await tester.pumpWidget(const SizedBox());
  deps.timer.dispose();
}

void main() {
  final t0 = DateTime(2026, 9, 21, 9);

  testWidgets('shows the idle work timer with a Start button', (tester) async {
    final deps = await _boot(FixedClock(t0));
    await _pumpApp(tester, deps);

    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('WORK'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Ready when you are'), findsOneWidget);
    await _finish(tester, deps);
  });

  testWidgets('starting shows Pause and the focus message', (tester) async {
    final clock = FixedClock(t0);
    final deps = await _boot(clock);
    await _pumpApp(tester, deps);

    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(find.text('Pause'), findsOneWidget);
    expect(find.textContaining('Stay on it'), findsOneWidget);
    expect(deps.timer.isRunning, isTrue);

    clock.advance(const Duration(minutes: 5));
    await deps.timer.onResumed();
    await tester.pump();
    expect(find.text('20:00'), findsOneWidget);
    await _finish(tester, deps);
  });

  testWidgets('a finished work session is logged and moves to a break', (
    tester,
  ) async {
    final clock = FixedClock(t0);
    final deps = await _boot(clock);
    await _pumpApp(tester, deps);

    await tester.tap(find.text('Start'));
    await tester.pump();
    clock.advance(const Duration(minutes: 25));
    await deps.timer.onResumed();
    await tester.pump();

    expect(deps.log.sessions.length, 1);
    expect(deps.log.sessions.single.countsAsPomodoro, isTrue);
    expect(find.text('SHORT BREAK'), findsOneWidget);
    expect(find.text('5:00'), findsOneWidget);
    expect(find.text('1 / 8'), findsOneWidget, reason: 'daily goal bar');
    await _finish(tester, deps);
  });

  testWidgets('strict mode disables pause, skip and reset while running', (
    tester,
  ) async {
    final deps = await _boot(FixedClock(t0));
    await deps.settings.update((s) => s.copyWith(strictMode: true));
    await _pumpApp(tester, deps);

    await tester.tap(find.text('Start'));
    await tester.pump();

    final pause = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Pause'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(pause.onPressed, isNull);
    expect(find.text('Strict mode — see it through'), findsOneWidget);
    for (final icon in [Icons.skip_next_rounded, Icons.replay_rounded]) {
      final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, icon),
      );
      expect(button.onPressed, isNull, reason: '$icon should be locked');
    }
    await _finish(tester, deps);
  });

  testWidgets('a running timer survives a restart from the same store', (
    tester,
  ) async {
    final store = MemoryKeyValueStore();
    final clock = FixedClock(t0);
    final first = await _boot(clock, store: store);
    await first.timer.start();
    first.timer.dispose();

    clock.advance(const Duration(minutes: 10));
    final second = await _boot(clock, store: store);
    await _pumpApp(tester, second);

    expect(second.timer.isRunning, isTrue);
    expect(find.text('15:00'), findsOneWidget);
    await _finish(tester, second);
  });

  testWidgets('a session that ended while the app was closed is logged', (
    tester,
  ) async {
    final store = MemoryKeyValueStore();
    final clock = FixedClock(t0);
    final first = await _boot(clock, store: store);
    await first.timer.start();
    first.timer.dispose();

    clock.advance(const Duration(hours: 2));
    final second = await _boot(clock, store: store);
    await _pumpApp(tester, second);

    expect(second.log.sessions.length, 1);
    expect(second.timer.isIdle, isTrue);
    expect(find.text('SHORT BREAK'), findsOneWidget);
    await _finish(tester, second);
  });
}
