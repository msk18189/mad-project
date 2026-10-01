import '../core/services/local_database_service.dart';
import '../models/deadline_reminder.dart';
import '../models/reminder_type.dart';

abstract class IReminderRepository {
  Future<List<DeadlineReminder>> getAllReminders();
  Future<List<DeadlineReminder>> getRemindersForDeadline(String deadlineId);
  Future<void> saveReminder(DeadlineReminder reminder);
  Future<void> updateReminder(DeadlineReminder reminder);
  Future<void> deleteReminder(String id);
  Future<void> deleteRemindersForDeadline(String deadlineId);
  Future<bool> getGlobalNotificationsEnabled();
  Future<void> setGlobalNotificationsEnabled(bool enabled);
  Future<Set<ReminderType>> getDefaultReminderPreferences();
  Future<void> setDefaultReminderPreferences(Set<ReminderType> types);
}

class ReminderRepository implements IReminderRepository {
  final ILocalDatabaseService _databaseService;

  ReminderRepository({ILocalDatabaseService? databaseService})
      : _databaseService = databaseService ?? LocalDatabaseService();

  @override
  Future<List<DeadlineReminder>> getAllReminders() async {
    return await _databaseService.getAllReminders();
  }

  @override
  Future<List<DeadlineReminder>> getRemindersForDeadline(String deadlineId) async {
    return await _databaseService.getRemindersForDeadline(deadlineId);
  }

  @override
  Future<void> saveReminder(DeadlineReminder reminder) async {
    await _databaseService.saveReminder(reminder);
  }

  @override
  Future<void> updateReminder(DeadlineReminder reminder) async {
    await _databaseService.saveReminder(reminder);
  }

  @override
  Future<void> deleteReminder(String id) async {
    await _databaseService.deleteReminder(id);
  }

  @override
  Future<void> deleteRemindersForDeadline(String deadlineId) async {
    await _databaseService.deleteRemindersForDeadline(deadlineId);
  }

  @override
  Future<bool> getGlobalNotificationsEnabled() async {
    return await _databaseService.getGlobalNotificationsEnabled();
  }

  @override
  Future<void> setGlobalNotificationsEnabled(bool enabled) async {
    await _databaseService.setGlobalNotificationsEnabled(enabled);
  }

  @override
  Future<Set<ReminderType>> getDefaultReminderPreferences() async {
    return await _databaseService.getDefaultReminderPreferences();
  }

  @override
  Future<void> setDefaultReminderPreferences(Set<ReminderType> types) async {
    await _databaseService.setDefaultReminderPreferences(types);
  }
}
