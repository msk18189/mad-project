import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../models/reminder_type.dart';

abstract class INotificationService {
  Future<void> init();
  Future<bool> requestPermission();
  Future<bool> areNotificationsEnabled();
  Future<void> scheduleNotification({
    required int id,
    required String deadlineId,
    required String deadlineTitle,
    required ReminderType type,
    required DateTime scheduledTime,
  });
  Future<void> cancelNotification(int id);
  Future<void> cancelAll();
  Future<void> showTestNotification({String title, String body});
}

class NotificationService implements INotificationService {
  static const String channelId = 'deadline_reminders';
  static const String channelName = 'Deadline Reminders';
  static const String channelDescription =
      'Notifications reminding you before deadlines arrive.';

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Global notification tap payload stream for in-app and background navigation
  static final StreamController<String> onNotificationTapped =
      StreamController<String>.broadcast();

  /// Cold-start launch payload (Section 34)
  static String? initialPayload;

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize local timezone (Section 36)
      tz.initializeTimeZones();

      // 2. Platform initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      // 3. Initialize plugin and hook tap listener (Section 32 & 33)
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            onNotificationTapped.add(payload);
          }
        },
      );

      // 4. Create dedicated Android Notification Channel (Section 19)
      if (!kIsWeb) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          const channel = AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.high,
            enableVibration: true,
          );
          await androidPlugin.createNotificationChannel(channel);
        }
      }

      // 5. Inspect cold-start launch payload (Section 34)
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          initialPayload = payload;
          onNotificationTapped.add(payload);
        }
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
    return false;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled();
        return enabled ?? true;
      }
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
    }
    return true;
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String deadlineId,
    required String deadlineTitle,
    required ReminderType type,
    required DateTime scheduledTime,
  }) async {
    if (kIsWeb) return;
    if (!_isInitialized) await init();

    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) {
      debugPrint('Skipping past notification for $deadlineTitle ($type)');
      return;
    }

    try {
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // Section 18: Notification Content Formatting
      final String title = 'DEADLINE · ${deadlineTitle.toUpperCase()}';
      final String body;
      switch (type) {
        case ReminderType.sevenDaysBefore:
          body = '7 days left.';
          break;
        case ReminderType.threeDaysBefore:
          body = '3 days left. Start planning.';
          break;
        case ReminderType.oneDayBefore:
          body = 'Due tomorrow.';
          break;
        case ReminderType.oneHourBefore:
          body = '1 hour left. Every second counts.';
          break;
        case ReminderType.atDeadline:
          body = 'Deadline is now.';
          break;
      }

      // Section 20: Notification Importance by Urgency
      final Importance importance;
      final Priority priority;
      if (type == ReminderType.atDeadline || type == ReminderType.oneHourBefore) {
        importance = Importance.max;
        priority = Priority.high;
      } else if (type == ReminderType.oneDayBefore) {
        importance = Importance.high;
        priority = Priority.high;
      } else {
        importance = Importance.defaultImportance;
        priority = Priority.defaultPriority;
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: importance,
        priority: priority,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      // Payload in format: "deadline:<id>" (Section 32)
      final payload = 'deadline:$deadlineId';

      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: tzScheduledTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: title,
        body: body,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Error canceling notification $id: $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }

  @override
  Future<void> showTestNotification({
    String title = 'DEADLINE TEST ALERT',
    String body = 'Every Second Counts · Reminders are active.',
  }) async {
    if (kIsWeb) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const darwinDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );
      await _plugin.show(
        id: 999999,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Error showing test notification: $e');
    }
  }
}
