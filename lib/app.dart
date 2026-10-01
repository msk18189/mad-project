import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/deadline_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/deadline/deadline_detail_screen.dart';
import 'screens/splash_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class DeadlineApp extends ConsumerStatefulWidget {
  const DeadlineApp({super.key});

  @override
  ConsumerState<DeadlineApp> createState() => _DeadlineAppState();
}

class _DeadlineAppState extends ConsumerState<DeadlineApp> {
  StreamSubscription<String>? _notifSub;

  @override
  void initState() {
    super.initState();
    // Section 32 & 33: Notification tap navigation stream listener
    _notifSub = NotificationService.onNotificationTapped.stream.listen((payload) {
      _handleNotificationNavigation(payload);
    });
  }

  void _handleNotificationNavigation(String payload) {
    String deadlineId = payload;
    if (payload.startsWith('deadline:')) {
      deadlineId = payload.substring('deadline:'.length);
    }
    if (deadlineId.isEmpty) return;

    final navState = appNavigatorKey.currentState;
    if (navState == null) return;

    final deadlines = ref.read(deadlineNotifierProvider).deadlines;
    final exists = deadlines.any((d) => d.id == deadlineId);

    if (exists) {
      navState.push(
        MaterialPageRoute(
          builder: (_) => DeadlineDetailScreen(deadlineId: deadlineId),
        ),
      );
    } else {
      // Section 35: Safe fallback for deleted or invalid deadlines
      final currentCtx = appNavigatorKey.currentContext;
      if (currentCtx != null) {
        ScaffoldMessenger.of(currentCtx).showSnackBar(
          const SnackBar(
            content: Text('The selected deadline no longer exists.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'DEADLINE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
