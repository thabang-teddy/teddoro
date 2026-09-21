import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teddoro/app/dependencies.dart';
import 'package:teddoro/services/audio_service.dart';
import 'package:teddoro/services/platform_services.dart';
import 'package:teddoro/state/settings_controller.dart';
import 'package:teddoro/state/timer_controller.dart';
import 'package:teddoro/ui/shell/home_shell.dart';
import 'package:teddoro/ui/theme/app_theme.dart';

class TeddoroApp extends StatefulWidget {
  const TeddoroApp({super.key, required this.deps});

  final AppDependencies deps;

  @override
  State<TeddoroApp> createState() => _TeddoroAppState();
}

class _TeddoroAppState extends State<TeddoroApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-evaluate the absolute end time on return; the periodic ticker may
    // have been suspended while backgrounded.
    if (state == AppLifecycleState.resumed) widget.deps.timer.onResumed();
  }

  @override
  Widget build(BuildContext context) {
    final deps = widget.deps;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: deps.settings),
        ChangeNotifierProvider.value(value: deps.tasks),
        ChangeNotifierProvider.value(value: deps.log),
        ChangeNotifierProvider.value(value: deps.timer),
        Provider<AppBlockingService>.value(value: deps.blocking),
        Provider<AudioService>.value(value: deps.audio),
      ],
      child: Consumer2<SettingsController, TimerController>(
        builder: (context, settings, timer, _) {
          final seed = settings.settings.sessionColor(timer.type);
          return MaterialApp(
            title: 'Teddoro',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(seed),
            darkTheme: AppTheme.dark(seed),
            themeMode: AppTheme.modeFor(settings.settings.theme),
            themeAnimationDuration: const Duration(milliseconds: 400),
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
