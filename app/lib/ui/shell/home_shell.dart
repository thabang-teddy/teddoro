import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/domain/stats/badges.dart';
import 'package:teddoro/state/timer_controller.dart';
import 'package:teddoro/ui/common/celebration_dialog.dart';
import 'package:teddoro/ui/settings/settings_screen.dart';
import 'package:teddoro/ui/stats/stats_screen.dart';
import 'package:teddoro/ui/tasks/tasks_screen.dart';
import 'package:teddoro/ui/timer/timer_screen.dart';

/// Bottom-navigation shell. Also guards against leaving the app with a
/// session running and shows badge celebrations wherever the user is.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  StreamSubscription<Achievement>? _badges;

  static const _tabs = [
    TimerScreen(),
    TasksScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _badges = context.read<TimerController>().achievementEarned.listen(
      _celebrate,
    );
  }

  @override
  void dispose() {
    _badges?.cancel();
    super.dispose();
  }

  void _celebrate(Achievement badge) {
    if (!mounted) return;
    showCelebrationDialog(context, badge: badge);
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timer is running'),
        content: const Text(
          'Your session keeps counting in the background, but are you sure '
          'you want to leave now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave == true) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final running = context.select<TimerController, bool>((t) => !t.isIdle);
    return PopScope(
      canPop: !running,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer),
              label: 'Timer',
            ),
            NavigationDestination(
              icon: Icon(Icons.check_circle_outline),
              selectedIcon: Icon(Icons.check_circle),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
