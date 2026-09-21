import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/state/timer_controller.dart';

/// Start / pause, skip and reset. Skip and reset are disabled under strict
/// mode while a session is in progress.
class TimerControls extends StatelessWidget {
  const TimerControls({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerController>();
    final locked = timer.controlsLocked;
    final primaryLabel = timer.isRunning
        ? 'Pause'
        : (timer.isPaused ? 'Resume' : 'Start');
    final primaryIcon = timer.isRunning
        ? Icons.pause_rounded
        : Icons.play_arrow_rounded;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SideButton(
          icon: Icons.replay_rounded,
          tooltip: 'Reset',
          enabled: !locked && !timer.isIdle,
          onPressed: timer.reset,
        ),
        const SizedBox(width: 16),
        Semantics(
          button: true,
          label: primaryLabel,
          child: FilledButton.icon(
            onPressed: timer.isRunning
                ? (locked ? null : timer.pause)
                : timer.start,
            icon: Icon(primaryIcon, size: 28),
            label: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(primaryLabel),
            ),
            style: FilledButton.styleFrom(minimumSize: const Size(180, 64)),
          ),
        ),
        const SizedBox(width: 16),
        _SideButton(
          icon: Icons.skip_next_rounded,
          tooltip: 'Skip',
          enabled: !locked,
          onPressed: timer.skip,
        ),
      ],
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: tooltip,
    onPressed: enabled ? onPressed : null,
    icon: Icon(icon),
    iconSize: 28,
    constraints: const BoxConstraints.tightFor(width: 56, height: 56),
  );
}
