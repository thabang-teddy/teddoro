import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/domain/models/session_type.dart';
import 'package:teddoro/state/settings_controller.dart';
import 'package:teddoro/state/timer_controller.dart';
import 'package:teddoro/ui/logo/teddy_clock_logo.dart';
import 'package:teddoro/ui/settings/preset_picker_sheet.dart';
import 'package:teddoro/ui/theme/app_theme.dart';
import 'package:teddoro/ui/timer/active_task_card.dart';
import 'package:teddoro/ui/timer/daily_goal_bar.dart';
import 'package:teddoro/ui/timer/minimal_mode_screen.dart';
import 'package:teddoro/ui/timer/timer_controls.dart';
import 'package:teddoro/ui/timer/timer_ring.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerController>();
    final settings = context.watch<SettingsController>().settings;
    final color = settings.sessionColor(timer.type);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            TeddyClockLogo(
              size: 32,
              accentColor: color,
              progress: timer.progress,
            ),
            const SizedBox(width: 10),
            const Text(
              'Teddoro',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Minimal mode',
            onPressed: () => MinimalModeScreen.open(context),
            icon: const Icon(Icons.fullscreen_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final ringSize = (constraints.maxWidth * 0.72).clamp(200.0, 300.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SessionHeader(timer: timer, color: color),
                  const SizedBox(height: 16),
                  Center(
                    child: TimerRing(
                      remainingSeconds: timer.remainingSeconds,
                      progress: timer.progress,
                      label: timer.type.label,
                      color: color,
                      size: ringSize,
                      child: _RingMessage(timer: timer),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (timer.controlsLocked)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Strict mode — see it through',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  const TimerControls(),
                  const SizedBox(height: 24),
                  const ActiveTaskCard(),
                  const SizedBox(height: 20),
                  const DailyGoalBar(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Preset chip on the left, cycle dots on the right.
class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.timer, required this.color});

  final TimerController timer;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final preset = context.select<SettingsController, String>(
      (s) =>
          '${s.settings.activePreset.name} · ${s.settings.activePreset.summary}',
    );
    return Row(
      children: [
        ActionChip(
          avatar: const Icon(Icons.schedule, size: 18),
          label: Text(preset),
          onPressed: () => showPresetPickerSheet(context),
        ),
        const Spacer(),
        _CycleDots(
          completed: timer.cycleCount,
          total: timer.longBreakEvery,
          activeIsWork: timer.type == SessionType.work && !timer.isIdle,
          color: color,
        ),
      ],
    );
  }
}

class _CycleDots extends StatelessWidget {
  const _CycleDots({
    required this.completed,
    required this.total,
    required this.activeIsWork,
    required this.color,
  });

  final int completed;
  final int total;
  final bool activeIsWork;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$completed of $total work sessions before the long break',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < completed
                  ? color
                  : (i == completed && activeIsWork
                        ? color.withValues(alpha: 0.45)
                        : color.withValues(alpha: 0.15)),
            ),
          ),
      ],
    ),
  );
}

/// Inside the ring: the focus message during work, a reminder during breaks.
class _RingMessage extends StatelessWidget {
  const _RingMessage({required this.timer});

  final TimerController timer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = switch ((timer.isIdle, timer.type.isBreak)) {
      (true, _) => 'Ready when you are',
      (false, true) => timer.currentBreakReminder ?? 'Enjoy the break',
      (false, false) => timer.focusMessage,
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        text,
        key: ValueKey(text),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
