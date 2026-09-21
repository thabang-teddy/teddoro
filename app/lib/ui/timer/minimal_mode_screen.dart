import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/state/settings_controller.dart';
import 'package:teddoro/state/timer_controller.dart';
import 'package:teddoro/ui/theme/app_theme.dart';
import 'package:teddoro/ui/timer/timer_ring.dart';

/// Full-screen view with nothing but the countdown and the focus message.
/// Tap anywhere to leave.
class MinimalModeScreen extends StatefulWidget {
  const MinimalModeScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => const MinimalModeScreen(),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );

  @override
  State<MinimalModeScreen> createState() => _MinimalModeScreenState();
}

class _MinimalModeScreenState extends State<MinimalModeScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerController>();
    final settings = context.watch<SettingsController>().settings;
    final color = settings.sessionColor(timer.type);
    final theme = Theme.of(context);
    final message = timer.type.isBreak
        ? timer.currentBreakReminder
        : (timer.isIdle ? null : timer.focusMessage);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TimerRing(
                  remainingSeconds: timer.remainingSeconds,
                  progress: timer.progress,
                  label: timer.type.label,
                  color: color,
                  size: 320,
                ),
                const SizedBox(height: 32),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 48),
                Text(
                  'Tap anywhere to exit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
