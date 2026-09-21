import 'package:flutter/material.dart';
import 'package:teddoro/domain/stats/badges.dart';
import 'package:teddoro/ui/logo/teddy_clock_logo.dart';

/// Small bear-themed celebration when a badge is earned.
Future<void> showCelebrationDialog(
  BuildContext context, {
  required Achievement badge,
}) => showDialog<void>(
  context: context,
  builder: (context) => _CelebrationDialog(badge: badge),
);

class _CelebrationDialog extends StatelessWidget {
  const _CelebrationDialog({required this.badge});

  final Achievement badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: reduceMotion ? 1 : 0.6, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: TeddyClockLogo(
              size: 120,
              accentColor: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Achievement earned!',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(badge.description, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Nice!'),
        ),
      ],
    );
  }
}
