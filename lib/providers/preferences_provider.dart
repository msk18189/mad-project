import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/storage_service.dart';
import '../models/category.dart';
import '../models/deadline_preferences.dart';
import '../models/priority.dart';
import '../models/reminder_type.dart';

export '../models/deadline_preferences.dart';

class DeadlinePreferencesNotifier extends Notifier<DeadlinePreferences> {
  late final StorageService _storage;

  @override
  DeadlinePreferences build() {
    _storage = StorageService();
    return _storage.getDeadlinePreferences();
  }

  Future<void> setDefaultPriority(DeadlinePriority priority) async {
    final updated = state.copyWith(defaultPriority: priority);
    state = updated;
    await _storage.saveDeadlinePreferences(updated);
  }

  Future<void> setDefaultCategory(DeadlineCategory category) async {
    final updated = state.copyWith(defaultCategory: category);
    state = updated;
    await _storage.saveDeadlinePreferences(updated);
  }

  Future<void> toggleDefaultReminder(ReminderType type) async {
    final current = List<ReminderType>.from(state.defaultReminders);
    if (current.contains(type)) {
      current.remove(type);
    } else {
      current.add(type);
    }
    final updated = state.copyWith(defaultReminders: current);
    state = updated;
    await _storage.saveDeadlinePreferences(updated);
  }
}

final preferencesProvider = NotifierProvider<DeadlinePreferencesNotifier, DeadlinePreferences>(() {
  return DeadlinePreferencesNotifier();
});
