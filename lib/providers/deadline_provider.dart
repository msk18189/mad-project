import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/services/local_database_service.dart';
import '../data/demo_data.dart';
import '../models/deadline.dart';
import '../repositories/deadline_repository.dart';
import 'countdown_tick_provider.dart';
import 'deadline_state.dart';

export 'deadline_state.dart';

import '../core/services/reminder_scheduler.dart';
import '../models/deadline_reminder.dart';
import 'reminder_provider.dart';

final deadlineRepositoryProvider = Provider<DeadlineRepository>((ref) {
  return DeadlineRepository(databaseService: LocalDatabaseService());
});

class DeadlineNotifier extends Notifier<DeadlineState> {
  late final DeadlineRepository _repository;
  late final IReminderScheduler _scheduler;

  @override
  DeadlineState build() {
    _repository = ref.watch(deadlineRepositoryProvider);
    _scheduler = ref.watch(reminderSchedulerProvider);
    // Initial async load
    Future.microtask(() => loadDeadlines());
    return const DeadlineState(isLoading: true);
  }

  /// Load all stored deadlines from database and reconcile notifications
  Future<void> loadDeadlines() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repository.getAllDeadlines();
      state = state.copyWith(
        deadlines: items,
        isLoading: false,
        clearError: true,
      );
      try {
        await _scheduler.reconcileAll(items);
      } catch (_) {
        // Safeguard for headless tests or mocked notification service
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load deadlines from storage: $e',
      );
    }
  }

  /// Select a deadline for detailed viewing/editing
  void selectDeadline(String id) {
    try {
      final d = state.deadlines.firstWhere((item) => item.id == id);
      state = state.copyWith(selectedDeadline: d);
    } catch (_) {
      state = state.copyWith(clearSelected: true);
    }
  }

  /// Add a new validated deadline to database and schedule valid reminders
  Future<void> addDeadline(Deadline deadline, {List<DeadlineReminder>? reminders}) async {
    final validationError = deadline.validate();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      throw ArgumentError(validationError);
    }

    try {
      await _repository.addDeadline(deadline);
      try {
        await _scheduler.scheduleDeadlineReminders(deadline, reminders: reminders);
      } catch (_) {}
      await loadDeadlines();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create deadline: $e');
      rethrow;
    }
  }

  /// Update an existing deadline and reschedule notifications
  Future<void> updateDeadline(Deadline deadline, {List<DeadlineReminder>? reminders}) async {
    final validationError = deadline.validate();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      throw ArgumentError(validationError);
    }

    try {
      await _repository.updateDeadline(deadline);
      try {
        await _scheduler.rescheduleDeadlineReminders(deadline, newReminders: reminders);
      } catch (_) {}
      await loadDeadlines();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update deadline: $e');
      rethrow;
    }
  }

  /// Delete deadline by id and cancel associated reminders
  Future<void> deleteDeadline(String id) async {
    try {
      try {
        await _scheduler.cancelDeadlineReminders(id);
      } catch (_) {}
      await _repository.deleteDeadline(id);
      await loadDeadlines();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete deadline: $e');
      rethrow;
    }
  }

  /// Mark deadline completed or restore to active with proper reminder rescheduling
  Future<void> toggleComplete(String id) async {
    try {
      final deadline = state.deadlines.firstWhere((d) => d.id == id);
      if (deadline.isCompleted) {
        await _repository.restoreDeadline(id);
        try {
          await _scheduler.onDeadlineRestored(deadline);
        } catch (_) {}
      } else {
        await _repository.completeDeadline(id);
        try {
          await _scheduler.onDeadlineCompleted(id);
        } catch (_) {}
      }
      await loadDeadlines();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to toggle completion: $e');
    }
  }

  /// Subtask: add subtask to deadline with optional description and sortOrder
  Future<void> addSubtask(String deadlineId, String title, {String? description}) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Task title cannot be empty.');
    }
    try {
      final deadline = state.deadlines.firstWhere((d) => d.id == deadlineId);
      final newSubtask = Subtask(
        id: const Uuid().v4(),
        deadlineId: deadlineId,
        title: trimmed,
        description: description?.trim().isNotEmpty == true ? description!.trim() : null,
        sortOrder: deadline.subtasks.length,
        createdAt: DateTime.now(),
      );
      final updated = deadline.copyWith(
        subtasks: [...deadline.subtasks, newSubtask],
        updatedAt: DateTime.now(),
      );
      await _repository.updateDeadline(updated);
      await loadDeadlines();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add subtask: $e');
      rethrow;
    }
  }

  /// Subtask: update an existing subtask (rename, edit description, etc.)
  Future<void> updateSubtask(String deadlineId, Subtask updatedSubtask) async {
    if (updatedSubtask.title.trim().isEmpty) {
      throw ArgumentError('Task title cannot be empty.');
    }
    try {
      final deadline = state.deadlines.firstWhere((d) => d.id == deadlineId);
      final updatedSubtasks = deadline.subtasks.map((s) {
        if (s.id == updatedSubtask.id) {
          return updatedSubtask;
        }
        return s;
      }).toList();

      final updated = deadline.copyWith(
        subtasks: updatedSubtasks,
        updatedAt: DateTime.now(),
      );
      await _repository.updateDeadline(updated);
      await loadDeadlines();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update subtask: $e');
      rethrow;
    }
  }

  /// Subtask: toggle subtask completion
  Future<void> toggleSubtask(String deadlineId, String subtaskId) async {
    try {
      final deadline = state.deadlines.firstWhere((d) => d.id == deadlineId);
      final updatedSubtasks = deadline.subtasks.map((s) {
        if (s.id == subtaskId) {
          final isDone = !s.isCompleted;
          return s.copyWith(
            isCompleted: isDone,
            completedAt: isDone ? DateTime.now() : null,
            clearCompletedAt: !isDone,
          );
        }
        return s;
      }).toList();

      final updated = deadline.copyWith(
        subtasks: updatedSubtasks,
        updatedAt: DateTime.now(),
      );
      await _repository.updateDeadline(updated);
      await loadDeadlines();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update subtask: $e');
    }
  }

  /// Subtask: delete subtask
  Future<void> deleteSubtask(String deadlineId, String subtaskId) async {
    try {
      final deadline = state.deadlines.firstWhere((d) => d.id == deadlineId);
      final remaining = deadline.subtasks.where((s) => s.id != subtaskId).toList();
      // Re-index sort order
      final reindexed = remaining.asMap().entries.map((e) {
        return e.value.copyWith(sortOrder: e.key);
      }).toList();

      final updated = deadline.copyWith(
        subtasks: reindexed,
        updatedAt: DateTime.now(),
      );
      await _repository.updateDeadline(updated);
      await loadDeadlines();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete subtask: $e');
    }
  }

  /// Subtask: reorder subtasks and persist sortOrder
  Future<void> reorderSubtasks(String deadlineId, int oldIndex, int newIndex) async {
    try {
      final deadline = state.deadlines.firstWhere((d) => d.id == deadlineId);
      final list = List<Subtask>.from(deadline.subtasks);
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);

      // Re-index sort orders
      final reordered = list.asMap().entries.map((e) {
        return e.value.copyWith(sortOrder: e.key);
      }).toList();

      final updated = deadline.copyWith(
        subtasks: reordered,
        updatedAt: DateTime.now(),
      );
      await _repository.updateDeadline(updated);
      await loadDeadlines();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to reorder subtasks: $e');
    }
  }

  /// Optional debug/demo mode loader
  Future<void> loadDemoData() async {
    final demoItems = DemoData.getSampleDeadlines();
    for (final item in demoItems) {
      await _repository.addDeadline(item);
    }
    await loadDeadlines();
  }

  /// Clear only completed deadlines
  Future<void> clearCompleted() async {
    final completed = state.deadlines.where((d) => d.isCompleted).toList();
    for (final item in completed) {
      try {
        await _scheduler.cancelDeadlineReminders(item.id);
      } catch (_) {}
      await _repository.deleteDeadline(item.id);
    }
    await loadDeadlines();
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    for (final item in state.deadlines) {
      try {
        await _scheduler.cancelDeadlineReminders(item.id);
      } catch (_) {}
    }
    await _repository.clearAllDeadlines();
    await loadDeadlines();
  }
}

/// Primary reactive state provider
final deadlineNotifierProvider = NotifierProvider<DeadlineNotifier, DeadlineState>(() {
  return DeadlineNotifier();
});

/// Convenience provider exposing the list of deadlines
final deadlineListProvider = Provider<List<Deadline>>((ref) {
  return ref.watch(deadlineNotifierProvider).deadlines;
});

/// Dedicated reactive selectors driven by state and the centralized clock (Section 40)
final activeDeadlinesProvider = Provider<List<Deadline>>((ref) {
  final now = ref.watch(currentDateTimeProvider);
  return ref.watch(deadlineNotifierProvider).activeDeadlines(now);
});

final heroDeadlineProvider = Provider<Deadline?>((ref) {
  final now = ref.watch(currentDateTimeProvider);
  return ref.watch(deadlineNotifierProvider).nextDeadline(now);
});

final urgentDeadlinesProvider = Provider<List<Deadline>>((ref) {
  final now = ref.watch(currentDateTimeProvider);
  return ref.watch(deadlineNotifierProvider).urgentDeadlines(now);
});

final upcomingDeadlinesProvider = Provider<List<Deadline>>((ref) {
  final now = ref.watch(currentDateTimeProvider);
  return ref.watch(deadlineNotifierProvider).upcomingDeadlines(now);
});

final laterDeadlinesProvider = Provider<List<Deadline>>((ref) {
  final now = ref.watch(currentDateTimeProvider);
  return ref.watch(deadlineNotifierProvider).laterDeadlines(now);
});

final missedDeadlinesProvider = Provider<List<Deadline>>((ref) {
  final now = ref.watch(currentDateTimeProvider);
  return ref.watch(deadlineNotifierProvider).missedDeadlines(now);
});

final completedDeadlinesProvider = Provider<List<Deadline>>((ref) {
  return ref.watch(deadlineNotifierProvider).completedDeadlines;
});
