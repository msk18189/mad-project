import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/notification_service.dart';
import '../core/services/reminder_scheduler.dart';
import '../models/deadline.dart';
import '../models/deadline_reminder.dart';
import '../repositories/reminder_repository.dart';
import 'deadline_provider.dart';

final reminderRepositoryProvider = Provider<IReminderRepository>((ref) {
  return ReminderRepository();
});

final notificationServiceProvider = Provider<INotificationService>((ref) {
  return NotificationService();
});

final reminderSchedulerProvider = Provider<IReminderScheduler>((ref) {
  final notif = ref.watch(notificationServiceProvider);
  final repo = ref.watch(reminderRepositoryProvider);
  return ReminderScheduler(
    notificationService: notif,
    reminderRepository: repo,
  );
});

class ReminderSettingsState {
  final bool globalEnabled;
  final Map<ReminderType, bool> defaultPreferences;
  final bool isLoading;
  final String? errorMessage;

  const ReminderSettingsState({
    this.globalEnabled = true,
    this.defaultPreferences = const {
      ReminderType.sevenDaysBefore: true,
      ReminderType.threeDaysBefore: true,
      ReminderType.oneDayBefore: true,
      ReminderType.oneHourBefore: true,
      ReminderType.atDeadline: true,
    },
    this.isLoading = false,
    this.errorMessage,
  });

  ReminderSettingsState copyWith({
    bool? globalEnabled,
    Map<ReminderType, bool>? defaultPreferences,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReminderSettingsState(
      globalEnabled: globalEnabled ?? this.globalEnabled,
      defaultPreferences: defaultPreferences ?? this.defaultPreferences,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ReminderNotifier extends Notifier<ReminderSettingsState> {
  late final IReminderRepository _repository;
  late final IReminderScheduler _scheduler;

  @override
  ReminderSettingsState build() {
    _repository = ref.watch(reminderRepositoryProvider);
    _scheduler = ref.watch(reminderSchedulerProvider);
    Future.microtask(() => loadSettings());
    return const ReminderSettingsState(isLoading: true);
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final enabled = await _repository.getGlobalNotificationsEnabled();
      final defaultSet = await _repository.getDefaultReminderPreferences();
      final defaultsMap = {
        for (final t in ReminderType.values) t: defaultSet.contains(t),
      };
      state = state.copyWith(
        globalEnabled: enabled,
        defaultPreferences: defaultsMap,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load reminder settings: $e',
      );
    }
  }

  Future<void> setGlobalEnabled(bool enabled) async {
    try {
      state = state.copyWith(globalEnabled: enabled);
      final deadlines = ref.read(deadlineNotifierProvider).deadlines;
      await _scheduler.onGlobalToggleChanged(enabled, deadlines);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update reminder settings: $e');
    }
  }

  Future<void> updateDefaultPreference(ReminderType type, bool enabled) async {
    try {
      final updated = Map<ReminderType, bool>.from(state.defaultPreferences);
      updated[type] = enabled;
      state = state.copyWith(defaultPreferences: updated);
      final setTypes = updated.entries.where((e) => e.value).map((e) => e.key).toSet();
      await _repository.setDefaultReminderPreferences(setTypes);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update default preference: $e');
    }
  }

  Future<List<DeadlineReminder>> getRemindersForDeadline(String deadlineId) async {
    return await _repository.getRemindersForDeadline(deadlineId);
  }

  Future<void> saveReminders(Deadline deadline, List<DeadlineReminder> reminders) async {
    await _scheduler.rescheduleDeadlineReminders(deadline, newReminders: reminders);
  }

  Future<bool> requestNotificationPermissions() async {
    final notifService = ref.read(notificationServiceProvider);
    return await notifService.requestPermission();
  }
}

final reminderNotifierProvider =
    NotifierProvider<ReminderNotifier, ReminderSettingsState>(() {
  return ReminderNotifier();
});

/// FutureProvider to easily fetch reminders for a given deadline ID
final deadlineRemindersFamily =
    FutureProvider.family<List<DeadlineReminder>, String>((ref, deadlineId) async {
  final repo = ref.watch(reminderRepositoryProvider);
  return repo.getRemindersForDeadline(deadlineId);
});
