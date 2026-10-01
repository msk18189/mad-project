import 'package:flutter/foundation.dart';
import '../../models/deadline.dart';
import '../../models/deadline_reminder.dart';
import '../../repositories/reminder_repository.dart';
import 'notification_service.dart';

abstract class IReminderScheduler {
  Future<void> scheduleDeadlineReminders(
    Deadline deadline, {
    List<DeadlineReminder>? reminders,
    DateTime? now,
  });
  Future<void> cancelDeadlineReminders(String deadlineId);
  Future<void> rescheduleDeadlineReminders(
    Deadline deadline, {
    List<DeadlineReminder>? newReminders,
    DateTime? now,
  });
  Future<void> onDeadlineCompleted(String deadlineId);
  Future<void> onDeadlineRestored(Deadline deadline, {DateTime? now});
  Future<void> reconcileAll(List<Deadline> deadlines, {DateTime? now});
  Future<void> onGlobalToggleChanged(bool enabled, List<Deadline> deadlines);
}

class ReminderScheduler implements IReminderScheduler {
  final INotificationService _notificationService;
  final IReminderRepository _reminderRepository;

  ReminderScheduler({
    INotificationService? notificationService,
    IReminderRepository? reminderRepository,
  })  : _notificationService = notificationService ?? NotificationService(),
        _reminderRepository = reminderRepository ?? ReminderRepository();

  @override
  Future<void> scheduleDeadlineReminders(
    Deadline deadline, {
    List<DeadlineReminder>? reminders,
    DateTime? now,
  }) async {
    final isGloballyEnabled =
        await _reminderRepository.getGlobalNotificationsEnabled();
    if (!isGloballyEnabled) {
      debugPrint('Reminders globally disabled. Skipping scheduling for ${deadline.id}');
      return;
    }

    // Do not schedule for completed or missed deadlines (Section 14 & 16)
    final current = now ?? DateTime.now();
    if (deadline.isCompleted || deadline.isPassed(current)) {
      return;
    }

    final remindersToSchedule = reminders ??
        await _reminderRepository.getRemindersForDeadline(deadline.id);

    final finalReminders = remindersToSchedule.isNotEmpty
        ? remindersToSchedule
        : DeadlineReminder.createValidReminders(
            deadlineId: deadline.id,
            deadlineDateTime: deadline.deadlineDateTime,
            now: current,
          );

    for (final reminder in finalReminders) {
      // Save/persist reminder state
      await _reminderRepository.saveReminder(reminder);

      // Only schedule if enabled and in the future (Section 9 & 37)
      if (reminder.isEnabled && reminder.scheduledTime.isAfter(current)) {
        await _notificationService.scheduleNotification(
          id: reminder.notificationId,
          deadlineId: deadline.id,
          deadlineTitle: deadline.title,
          type: reminder.type,
          scheduledTime: reminder.scheduledTime,
        );
      }
    }
  }

  @override
  Future<void> cancelDeadlineReminders(String deadlineId) async {
    // 1. Cancel deterministic notifications for all possible reminder types
    for (final type in ReminderType.values) {
      final notifId = DeadlineReminder.generateNotificationId(deadlineId, type);
      await _notificationService.cancelNotification(notifId);
    }

    // 2. Remove persisted reminder records
    await _reminderRepository.deleteRemindersForDeadline(deadlineId);
  }

  @override
  Future<void> rescheduleDeadlineReminders(
    Deadline deadline, {
    List<DeadlineReminder>? newReminders,
    DateTime? now,
  }) async {
    // Cancel old notifications first to avoid orphan reminders (Section 12 & 40)
    await cancelDeadlineReminders(deadline.id);

    // Schedule new valid notifications
    await scheduleDeadlineReminders(
      deadline,
      reminders: newReminders,
      now: now,
    );
  }

  @override
  Future<void> onDeadlineCompleted(String deadlineId) async {
    // Section 14: Completed deadline cancels future notifications
    for (final type in ReminderType.values) {
      final notifId = DeadlineReminder.generateNotificationId(deadlineId, type);
      await _notificationService.cancelNotification(notifId);
    }
  }

  @override
  Future<void> onDeadlineRestored(Deadline deadline, {DateTime? now}) async {
    final current = now ?? DateTime.now();
    // Section 15: If deadline is in future, reschedule valid reminders
    if (!deadline.isPassed(current)) {
      await scheduleDeadlineReminders(deadline, now: current);
    }
  }

  @override
  Future<void> reconcileAll(List<Deadline> deadlines, {DateTime? now}) async {
    // Section 41 & 42: Idempotent startup reconciliation
    final isGloballyEnabled =
        await _reminderRepository.getGlobalNotificationsEnabled();
    if (!isGloballyEnabled) {
      await _notificationService.cancelAll();
      return;
    }

    final current = now ?? DateTime.now();
    for (final deadline in deadlines) {
      if (deadline.isCompleted || deadline.isPassed(current)) {
        // Cancel any lingering alarms for completed/passed items
        for (final type in ReminderType.values) {
          final notifId =
              DeadlineReminder.generateNotificationId(deadline.id, type);
          await _notificationService.cancelNotification(notifId);
        }
      } else {
        // Schedule valid future notifications
        final reminders =
            await _reminderRepository.getRemindersForDeadline(deadline.id);
        if (reminders.isNotEmpty) {
          for (final reminder in reminders) {
            if (reminder.isEnabled && reminder.scheduledTime.isAfter(current)) {
              await _notificationService.scheduleNotification(
                id: reminder.notificationId,
                deadlineId: deadline.id,
                deadlineTitle: deadline.title,
                type: reminder.type,
                scheduledTime: reminder.scheduledTime,
              );
            }
          }
        }
      }
    }
  }

  @override
  Future<void> onGlobalToggleChanged(bool enabled, List<Deadline> deadlines) async {
    await _reminderRepository.setGlobalNotificationsEnabled(enabled);
    if (!enabled) {
      // Cancel all scheduled OS alarms (Section 24)
      await _notificationService.cancelAll();
    } else {
      // Re-schedule for all active future deadlines
      await reconcileAll(deadlines);
    }
  }
}
