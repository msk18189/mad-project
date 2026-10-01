import '../core/services/local_database_service.dart';
import '../models/deadline.dart';
import '../models/streak_stats.dart';

abstract class IDeadlineRepository {
  Future<List<Deadline>> getAllDeadlines();
  Future<Deadline?> getDeadlineById(String id);
  Future<void> addDeadline(Deadline deadline);
  Future<void> updateDeadline(Deadline deadline);
  Future<void> deleteDeadline(String id);
  Future<void> completeDeadline(String id);
  Future<void> restoreDeadline(String id);
  Future<void> clearAllDeadlines();
  StreakStats getStreakStats();
}

class DeadlineRepository implements IDeadlineRepository {
  final ILocalDatabaseService _databaseService;

  DeadlineRepository({ILocalDatabaseService? databaseService})
      : _databaseService = databaseService ?? LocalDatabaseService();

  @override
  Future<List<Deadline>> getAllDeadlines() async {
    final list = await _databaseService.getAllDeadlines();
    // Default chronological sorting: active nearest first, completed at the end
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      return a.deadlineDateTime.compareTo(b.deadlineDateTime);
    });
    return list;
  }

  @override
  Future<Deadline?> getDeadlineById(String id) async {
    return await _databaseService.getDeadlineById(id);
  }

  @override
  Future<void> addDeadline(Deadline deadline) async {
    final validationError = deadline.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    await _databaseService.insertDeadline(deadline);
  }

  @override
  Future<void> updateDeadline(Deadline deadline) async {
    final validationError = deadline.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }
    final updated = deadline.copyWith(updatedAt: DateTime.now());
    await _databaseService.updateDeadline(updated);
  }

  @override
  Future<void> deleteDeadline(String id) async {
    await _databaseService.deleteDeadline(id);
  }

  @override
  Future<void> completeDeadline(String id) async {
    final deadline = await _databaseService.getDeadlineById(id);
    if (deadline == null) {
      throw StateError('Cannot complete: Deadline with id $id not found.');
    }

    final updated = deadline.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _databaseService.updateDeadline(updated);
  }

  @override
  Future<void> restoreDeadline(String id) async {
    final deadline = await _databaseService.getDeadlineById(id);
    if (deadline == null) {
      throw StateError('Cannot restore: Deadline with id $id not found.');
    }

    final updated = deadline.copyWith(
      isCompleted: false,
      clearCompletedAt: true,
      updatedAt: DateTime.now(),
    );
    await _databaseService.updateDeadline(updated);
  }

  @override
  Future<void> clearAllDeadlines() async {
    await _databaseService.clearAll();
  }

  @override
  StreakStats getStreakStats() {
    return const StreakStats();
  }

  // Synchronous convenience adapter for existing code if needed
  List<Deadline> getDeadlines() {
    return [];
  }
}
