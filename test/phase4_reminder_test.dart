import 'package:flutter_test/flutter_test.dart';
import 'package:deadline/core/services/notification_service.dart';
import 'package:deadline/core/services/reminder_scheduler.dart';
import 'package:deadline/models/deadline.dart';
import 'package:deadline/models/deadline_reminder.dart';
import 'package:deadline/repositories/reminder_repository.dart';

class MockNotificationService implements INotificationService {
  final Map<int, Map<String, dynamic>> scheduledNotifications = {};
  final List<int> cancelledNotificationIds = [];
  bool permissionsGranted = true;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => permissionsGranted;

  @override
  Future<bool> areNotificationsEnabled() async => permissionsGranted;

  @override
  Future<void> scheduleNotification({
    required int id,
    required String deadlineId,
    required String deadlineTitle,
    required ReminderType type,
    required DateTime scheduledTime,
  }) async {
    scheduledNotifications[id] = {
      'id': id,
      'deadlineId': deadlineId,
      'deadlineTitle': deadlineTitle,
      'type': type,
      'scheduledTime': scheduledTime,
    };
  }

  @override
  Future<void> cancelNotification(int id) async {
    scheduledNotifications.remove(id);
    cancelledNotificationIds.add(id);
  }

  @override
  Future<void> cancelAll() async {
    scheduledNotifications.clear();
  }

  @override
  Future<void> showTestNotification({String? title, String? body}) async {}
}

class MockReminderRepository implements IReminderRepository {
  final Map<String, DeadlineReminder> reminders = {};
  bool globalNotificationsEnabled = true;
  Set<ReminderType> defaultPreferences = ReminderType.values.toSet();

  @override
  Future<List<DeadlineReminder>> getAllReminders() async =>
      reminders.values.toList();

  @override
  Future<List<DeadlineReminder>> getRemindersForDeadline(String deadlineId) async {
    return reminders.values.where((r) => r.deadlineId == deadlineId).toList();
  }

  @override
  Future<void> saveReminder(DeadlineReminder reminder) async {
    reminders[reminder.id] = reminder;
  }

  @override
  Future<void> updateReminder(DeadlineReminder reminder) async {
    reminders[reminder.id] = reminder;
  }

  @override
  Future<void> deleteReminder(String id) async {
    reminders.remove(id);
  }

  @override
  Future<void> deleteRemindersForDeadline(String deadlineId) async {
    reminders.removeWhere((_, r) => r.deadlineId == deadlineId);
  }

  @override
  Future<bool> getGlobalNotificationsEnabled() async =>
      globalNotificationsEnabled;

  @override
  Future<void> setGlobalNotificationsEnabled(bool enabled) async {
    globalNotificationsEnabled = enabled;
  }

  @override
  Future<Set<ReminderType>> getDefaultReminderPreferences() async =>
      Set.from(defaultPreferences);

  @override
  Future<void> setDefaultReminderPreferences(Set<ReminderType> types) async {
    defaultPreferences = Set.from(types);
  }
}

void main() {
  group('Phase 4: Reminder Calculation & Smart Lead Times (Section 60)', () {
    final fixedNow = DateTime(2026, 10, 1, 12, 0, 0);

    test('10-day deadline: Schedules 7d, 3d, 1d, 1h, and atDeadline', () {
      final deadlineTime = fixedNow.add(const Duration(days: 10));
      final reminders = DeadlineReminder.createValidReminders(
        deadlineId: 'd-10d',
        deadlineDateTime: deadlineTime,
        now: fixedNow,
      );

      final scheduledTypes = reminders.map((r) => r.type).toList();
      expect(scheduledTypes, containsAll([
        ReminderType.sevenDaysBefore,
        ReminderType.threeDaysBefore,
        ReminderType.oneDayBefore,
        ReminderType.oneHourBefore,
        ReminderType.atDeadline,
      ]));
      expect(reminders.length, equals(5));
    });

    test('5-day deadline: Skips 7d; schedules 3d, 1d, 1h, and atDeadline', () {
      final deadlineTime = fixedNow.add(const Duration(days: 5));
      final reminders = DeadlineReminder.createValidReminders(
        deadlineId: 'd-5d',
        deadlineDateTime: deadlineTime,
        now: fixedNow,
      );

      final scheduledTypes = reminders.map((r) => r.type).toList();
      expect(scheduledTypes, isNot(contains(ReminderType.sevenDaysBefore)));
      expect(scheduledTypes, containsAll([
        ReminderType.threeDaysBefore,
        ReminderType.oneDayBefore,
        ReminderType.oneHourBefore,
        ReminderType.atDeadline,
      ]));
      expect(reminders.length, equals(4));
    });

    test('2-day deadline: Skips 7d and 3d; schedules 1d, 1h, and atDeadline', () {
      final deadlineTime = fixedNow.add(const Duration(days: 2));
      final reminders = DeadlineReminder.createValidReminders(
        deadlineId: 'd-2d',
        deadlineDateTime: deadlineTime,
        now: fixedNow,
      );

      final scheduledTypes = reminders.map((r) => r.type).toList();
      expect(scheduledTypes, isNot(contains(ReminderType.sevenDaysBefore)));
      expect(scheduledTypes, isNot(contains(ReminderType.threeDaysBefore)));
      expect(scheduledTypes, containsAll([
        ReminderType.oneDayBefore,
        ReminderType.oneHourBefore,
        ReminderType.atDeadline,
      ]));
      expect(reminders.length, equals(3));
    });

    test('20-minute deadline: Skips earlier offsets; schedules only atDeadline', () {
      final deadlineTime = fixedNow.add(const Duration(minutes: 20));
      final reminders = DeadlineReminder.createValidReminders(
        deadlineId: 'd-20m',
        deadlineDateTime: deadlineTime,
        now: fixedNow,
      );

      final scheduledTypes = reminders.map((r) => r.type).toList();
      expect(scheduledTypes, equals([ReminderType.atDeadline]));
    });

    test('Past deadline: Schedules nothing', () {
      final deadlineTime = fixedNow.subtract(const Duration(minutes: 5));
      final reminders = DeadlineReminder.createValidReminders(
        deadlineId: 'd-past',
        deadlineDateTime: deadlineTime,
        now: fixedNow,
      );

      expect(reminders, isEmpty);
    });
  });

  group('Phase 4: Deterministic Notification IDs (Section 31)', () {
    test('Same deadline ID and type produce identical integer notification IDs', () {
      final id1 = DeadlineReminder.generateNotificationId('project-alpha', ReminderType.oneHourBefore);
      final id2 = DeadlineReminder.generateNotificationId('project-alpha', ReminderType.oneHourBefore);
      expect(id1, equals(id2));
    });

    test('Different reminder types produce different notification IDs', () {
      final id1 = DeadlineReminder.generateNotificationId('project-alpha', ReminderType.oneHourBefore);
      final id2 = DeadlineReminder.generateNotificationId('project-alpha', ReminderType.atDeadline);
      expect(id1, isNot(equals(id2)));
    });

    test('Notification ID is within valid 32-bit signed integer range', () {
      final id = DeadlineReminder.generateNotificationId('very-long-unique-uuid-1234567890', ReminderType.sevenDaysBefore);
      expect(id, greaterThanOrEqualTo(0));
      expect(id, lessThanOrEqualTo(2147483647));
    });
  });

  group('Phase 4: Reminder Scheduler Lifecycle (Section 61-66)', () {
    late MockNotificationService mockNotif;
    late MockReminderRepository mockRepo;
    late ReminderScheduler scheduler;
    final fixedNow = DateTime(2026, 10, 1, 10, 0, 0);

    setUp(() {
      mockNotif = MockNotificationService();
      mockRepo = MockReminderRepository();
      scheduler = ReminderScheduler(
        notificationService: mockNotif,
        reminderRepository: mockRepo,
      );
    });

    test('Create deadline schedules valid future reminders', () async {
      final deadline = Deadline(
        id: 'test-1',
        title: 'Project Launch',
        category: DeadlineCategory.project,
        deadlineDateTime: fixedNow.add(const Duration(days: 4)),
      );

      await scheduler.scheduleDeadlineReminders(deadline, now: fixedNow);

      // 4 days left: 3d, 1d, 1h, atDeadline = 4 notifications
      expect(mockNotif.scheduledNotifications.length, equals(4));
      expect(mockRepo.reminders.length, equals(4));
    });

    test('Edit deadline cancels old reminders and schedules new ones (Section 12, 61)', () async {
      final oldDeadline = Deadline(
        id: 'test-edit',
        title: 'Draft Report',
        category: DeadlineCategory.assignment,
        deadlineDateTime: fixedNow.add(const Duration(days: 5)),
      );
      await scheduler.scheduleDeadlineReminders(oldDeadline, now: fixedNow);
      expect(mockNotif.scheduledNotifications.length, equals(4));

      // User changes due date to 2 days from now
      final updatedDeadline = oldDeadline.copyWith(
        deadlineDateTime: fixedNow.add(const Duration(days: 2)),
      );
      await scheduler.rescheduleDeadlineReminders(updatedDeadline, now: fixedNow);

      // Old notifications cancelled and new ones (1d, 1h, atDeadline = 3) scheduled
      expect(mockNotif.scheduledNotifications.length, equals(3));
      final scheduledTypes = mockNotif.scheduledNotifications.values.map((n) => n['type']);
      expect(scheduledTypes, isNot(contains(ReminderType.threeDaysBefore)));
      expect(scheduledTypes, containsAll([
        ReminderType.oneDayBefore,
        ReminderType.oneHourBefore,
        ReminderType.atDeadline,
      ]));
    });

    test('Delete deadline cancels all OS notifications and clears DB records (Section 13, 62)', () async {
      final deadline = Deadline(
        id: 'test-del',
        title: 'Delete Me',
        category: DeadlineCategory.other,
        deadlineDateTime: fixedNow.add(const Duration(days: 8)),
      );
      await scheduler.scheduleDeadlineReminders(deadline, now: fixedNow);
      expect(mockNotif.scheduledNotifications.isNotEmpty, isTrue);

      await scheduler.cancelDeadlineReminders(deadline.id);

      expect(mockNotif.scheduledNotifications.isEmpty, isTrue);
      final remaining = await mockRepo.getRemindersForDeadline(deadline.id);
      expect(remaining, isEmpty);
    });

    test('Complete deadline cancels future notifications (Section 14, 63)', () async {
      final deadline = Deadline(
        id: 'test-complete',
        title: 'Submit Paper',
        category: DeadlineCategory.assignment,
        deadlineDateTime: fixedNow.add(const Duration(days: 2)),
      );
      await scheduler.scheduleDeadlineReminders(deadline, now: fixedNow);
      expect(mockNotif.scheduledNotifications.length, equals(3));

      await scheduler.onDeadlineCompleted(deadline.id);

      expect(mockNotif.scheduledNotifications.isEmpty, isTrue);
    });

    test('Restore deadline reschedules valid reminders if future; skips if past (Section 15, 64)', () async {
      final futureDeadline = Deadline(
        id: 'test-restore-future',
        title: 'Restored Future Project',
        category: DeadlineCategory.project,
        deadlineDateTime: fixedNow.add(const Duration(hours: 3)),
      );
      // Simulating restore while deadline is still 3 hours away (valid for 1h and atDeadline)
      await scheduler.onDeadlineRestored(futureDeadline, now: fixedNow);
      expect(mockNotif.scheduledNotifications.length, equals(2));

      // Simulating restore when deadline has already passed
      mockNotif.scheduledNotifications.clear();
      final pastDeadline = Deadline(
        id: 'test-restore-past',
        title: 'Restored Past Project',
        category: DeadlineCategory.project,
        deadlineDateTime: fixedNow.subtract(const Duration(minutes: 30)),
      );
      await scheduler.onDeadlineRestored(pastDeadline, now: fixedNow);
      expect(mockNotif.scheduledNotifications.isEmpty, isTrue);
    });

    test('Global toggle OFF cancels all notifications; ON reconciles and recreates without duplicates (Section 24, 65)', () async {
      final d1 = Deadline(
        id: 'g1',
        title: 'Task 1',
        category: DeadlineCategory.assignment,
        deadlineDateTime: fixedNow.add(const Duration(days: 2)),
      );
      final d2 = Deadline(
        id: 'g2',
        title: 'Task 2',
        category: DeadlineCategory.project,
        deadlineDateTime: fixedNow.add(const Duration(days: 5)),
      );

      await scheduler.scheduleDeadlineReminders(d1, now: fixedNow);
      await scheduler.scheduleDeadlineReminders(d2, now: fixedNow);
      final initialCount = mockNotif.scheduledNotifications.length;
      expect(initialCount, greaterThan(0));

      // Turn OFF globally
      await scheduler.onGlobalToggleChanged(false, [d1, d2]);
      expect(mockNotif.scheduledNotifications.isEmpty, isTrue);
      expect(await mockRepo.getGlobalNotificationsEnabled(), isFalse);

      // Turn ON globally
      await scheduler.onGlobalToggleChanged(true, [d1, d2]);
      expect(mockNotif.scheduledNotifications.length, equals(initialCount));
    });

    test('Reconcile is idempotent: multiple calls do not create duplicate notifications (Section 42, 66)', () async {
      final deadline = Deadline(
        id: 'idem-1',
        title: 'Idempotency Test',
        category: DeadlineCategory.exam,
        deadlineDateTime: fixedNow.add(const Duration(days: 3, hours: 2)),
      );

      await scheduler.scheduleDeadlineReminders(deadline, now: fixedNow);
      final firstCount = mockNotif.scheduledNotifications.length;

      // Reconcile multiple times
      await scheduler.reconcileAll([deadline], now: fixedNow);
      await scheduler.reconcileAll([deadline], now: fixedNow);

      expect(mockNotif.scheduledNotifications.length, equals(firstCount));
    });
  });

  group('Phase 4: Time Edge Cases (Section 70)', () {
    final fixedNow = DateTime(2026, 10, 1, 12, 0, 0);

    test('Exactly 7 days away: 7-day reminder is scheduled for current moment', () {
      final target = fixedNow.add(const Duration(days: 7));
      expect(ReminderType.sevenDaysBefore.isSchedulable(target, now: fixedNow), isTrue);
    });

    test('7 days minus 1 second: 7-day reminder is skipped (already in past)', () {
      final target = fixedNow.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
      expect(ReminderType.sevenDaysBefore.isSchedulable(target, now: fixedNow), isFalse);
      expect(ReminderType.threeDaysBefore.isSchedulable(target, now: fixedNow), isTrue);
    });

    test('Exactly 1 hour away: 1-hour reminder is schedulable', () {
      final target = fixedNow.add(const Duration(hours: 1));
      expect(ReminderType.oneHourBefore.isSchedulable(target, now: fixedNow), isTrue);
      expect(ReminderType.oneDayBefore.isSchedulable(target, now: fixedNow), isFalse);
    });

    test('1 second after deadline: atDeadline is skipped', () {
      final target = fixedNow.subtract(const Duration(seconds: 1));
      expect(ReminderType.atDeadline.isSchedulable(target, now: fixedNow), isFalse);
    });
  });
}
