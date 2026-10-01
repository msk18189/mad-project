import 'package:flutter_test/flutter_test.dart';
import 'package:deadline/core/services/local_database_service.dart';
import 'package:deadline/core/utils/deadline_status_resolver.dart';
import 'package:deadline/models/deadline.dart';
import 'package:deadline/repositories/deadline_repository.dart';

import 'package:deadline/models/deadline_reminder.dart';

/// In-memory database service implementation for deterministic unit tests
class InMemoryDatabaseService implements ILocalDatabaseService {
  final Map<String, Deadline> _storage = {};
  final Map<String, DeadlineReminder> _reminders = {};
  bool _globalEnabled = true;

  @override
  Future<void> init() async {}

  @override
  Future<List<Deadline>> getAllDeadlines() async {
    return _storage.values.toList();
  }

  @override
  Future<Deadline?> getDeadlineById(String id) async {
    return _storage[id];
  }

  @override
  Future<void> insertDeadline(Deadline deadline) async {
    _storage[deadline.id] = deadline;
  }

  @override
  Future<void> updateDeadline(Deadline deadline) async {
    _storage[deadline.id] = deadline;
  }

  @override
  Future<void> deleteDeadline(String id) async {
    _storage.remove(id);
  }

  @override
  Future<void> clearAll() async {
    _storage.clear();
    _reminders.clear();
  }

  @override
  Future<void> saveReminder(DeadlineReminder reminder) async {
    _reminders[reminder.id] = reminder;
  }

  @override
  Future<List<DeadlineReminder>> getRemindersForDeadline(String deadlineId) async {
    return _reminders.values.where((r) => r.deadlineId == deadlineId).toList();
  }

  @override
  Future<void> deleteReminder(String id) async {
    _reminders.remove(id);
  }

  @override
  Future<void> deleteRemindersForDeadline(String deadlineId) async {
    _reminders.removeWhere((_, r) => r.deadlineId == deadlineId);
  }

  @override
  Future<List<DeadlineReminder>> getAllReminders() async {
    return _reminders.values.toList();
  }

  @override
  Future<bool> getGlobalNotificationsEnabled() async {
    return _globalEnabled;
  }

  @override
  Future<void> setGlobalNotificationsEnabled(bool enabled) async {
    _globalEnabled = enabled;
  }

  Set<ReminderType> _defaultPrefs = ReminderType.values.toSet();

  @override
  Future<Set<ReminderType>> getDefaultReminderPreferences() async {
    return Set.from(_defaultPrefs);
  }

  @override
  Future<void> setDefaultReminderPreferences(Set<ReminderType> types) async {
    _defaultPrefs = Set.from(types);
  }
}

void main() {
  group('Phase 2 — Data Models & Validation', () {
    test('Valid deadline creation succeeds and validates', () {
      final now = DateTime(2026, 9, 30, 12, 0);
      final deadline = Deadline(
        id: 'valid-1',
        title: 'Complete Software Architecture',
        category: DeadlineCategory.project,
        priority: DeadlinePriority.high,
        deadlineDateTime: now.add(const Duration(days: 3)),
      );

      expect(deadline.id, equals('valid-1'));
      expect(deadline.title, equals('Complete Software Architecture'));
      expect(deadline.category, equals(DeadlineCategory.project));
      expect(deadline.priority, equals(DeadlinePriority.high));
      expect(deadline.validate(), isNull);
    });

    test('Rejects empty or whitespace-only title', () {
      final deadlineEmpty = Deadline(
        id: 'invalid-1',
        title: '',
        category: DeadlineCategory.assignment,
        deadlineDateTime: DateTime.now().add(const Duration(days: 1)),
      );

      final deadlineWhitespace = Deadline(
        id: 'invalid-2',
        title: '    ',
        category: DeadlineCategory.assignment,
        deadlineDateTime: DateTime.now().add(const Duration(days: 1)),
      );

      expect(deadlineEmpty.validate(), isNotNull);
      expect(deadlineWhitespace.validate(), isNotNull);
    });

    test('Handles very long titles and descriptions gracefully', () {
      final longTitle = 'A' * 500;
      final longDesc = 'B' * 5000;

      final deadline = Deadline(
        id: 'long-1',
        title: longTitle,
        description: longDesc,
        category: DeadlineCategory.other,
        deadlineDateTime: DateTime.now().add(const Duration(days: 1)),
      );

      expect(deadline.validate(), isNull);
      expect(deadline.title.length, equals(500));
      expect(deadline.description?.length, equals(5000));
    });

    test('Subtask model supports toggling, copyWith, and timestamp updates', () {
      final subtask = Subtask(
        id: 'sub-1',
        title: 'Write test cases',
        isCompleted: false,
      );

      expect(subtask.isCompleted, isFalse);
      expect(subtask.completedAt, isNull);

      final now = DateTime(2026, 9, 30, 15, 0);
      final completed = subtask.copyWith(
        isCompleted: true,
        completedAt: now,
      );

      expect(completed.isCompleted, isTrue);
      expect(completed.completedAt, equals(now));

      final restored = completed.copyWith(
        isCompleted: false,
        clearCompletedAt: true,
      );
      expect(restored.isCompleted, isFalse);
      expect(restored.completedAt, isNull);
    });
  });

  group('Phase 2 — Category & Priority Configurations', () {
    test('DeadlineCategoryConfig returns centralized metadata', () {
      final config = DeadlineCategoryConfig.from(DeadlineCategory.project);
      expect(config.displayName, equals('Project'));
      expect(config.emoji, equals('💻'));

      final fromString = DeadlineCategory.fromString('exam');
      expect(fromString, equals(DeadlineCategory.exam));
    });

    test('DeadlinePriorityConfig provides distinct weights and labels', () {
      final low = DeadlinePriorityConfig.from(DeadlinePriority.low);
      final med = DeadlinePriorityConfig.from(DeadlinePriority.medium);
      final high = DeadlinePriorityConfig.from(DeadlinePriority.high);

      expect(low.weight, equals(1));
      expect(med.weight, equals(2));
      expect(high.weight, equals(3));
      expect(low.label, equals('LOW'));
      expect(med.label, equals('MEDIUM'));
      expect(high.label, equals('HIGH'));
    });
  });

  group('Phase 2 — DeadlineStatusResolver Logic & Edge Cases', () {
    final baseTime = DateTime(2026, 9, 30, 12, 0, 0);

    test('Completed deadline always resolves to DeadlineStatus.completed', () {
      final status = DeadlineStatusResolver.resolve(
        deadlineDateTime: baseTime.subtract(const Duration(days: 5)),
        isCompleted: true,
        currentTime: baseTime,
      );
      expect(status, equals(DeadlineStatus.completed));
    });

    test('Deadline exactly now resolves to missed', () {
      final status = DeadlineStatusResolver.resolve(
        deadlineDateTime: baseTime,
        isCompleted: false,
        currentTime: baseTime,
      );
      expect(status, equals(DeadlineStatus.missed));
    });

    test('Deadline 1 second in the past resolves to missed', () {
      final status = DeadlineStatusResolver.resolve(
        deadlineDateTime: baseTime.subtract(const Duration(seconds: 1)),
        isCompleted: false,
        currentTime: baseTime,
      );
      expect(status, equals(DeadlineStatus.missed));
    });

    test('Deadline 1 second in the future resolves to due', () {
      final status = DeadlineStatusResolver.resolve(
        deadlineDateTime: baseTime.add(const Duration(seconds: 1)),
        isCompleted: false,
        currentTime: baseTime,
      );
      expect(status, equals(DeadlineStatus.due));
    });

    test('Deadline 1 hour in the future resolves to due (threshold <= 2h)', () {
      final status = DeadlineStatusResolver.resolve(
        deadlineDateTime: baseTime.add(const Duration(hours: 1)),
        isCompleted: false,
        currentTime: baseTime,
      );
      expect(status, equals(DeadlineStatus.due));
    });

    test('Deadline 12 hours in the future resolves to urgent (threshold <= 24h)', () {
      final status = DeadlineStatusResolver.resolve(
        deadlineDateTime: baseTime.add(const Duration(hours: 12)),
        isCompleted: false,
        currentTime: baseTime,
      );
      expect(status, equals(DeadlineStatus.urgent));
    });

    test('Deadline 2 days in the future resolves to approaching (threshold <= 72h)', () {
      final status = DeadlineStatusResolver.resolve(
        deadlineDateTime: baseTime.add(const Duration(days: 2)),
        isCompleted: false,
        currentTime: baseTime,
      );
      expect(status, equals(DeadlineStatus.approaching));
    });

    test('Deadline 5 days in the future resolves to upcoming (> 3 days)', () {
      final status = DeadlineStatusResolver.resolve(
        deadlineDateTime: baseTime.add(const Duration(days: 5)),
        isCompleted: false,
        currentTime: baseTime,
      );
      expect(status, equals(DeadlineStatus.upcoming));
    });
  });

  group('Phase 2 — Serialization & Persistence Integrity', () {
    test('Full Deadline serialization preserves all fields losslessly', () {
      final original = Deadline(
        id: 'ser-1',
        title: 'Compiler Design Submission',
        description: 'AST generation and LLVM IR generation',
        category: DeadlineCategory.assignment,
        priority: DeadlinePriority.high,
        createdAt: DateTime(2026, 9, 20, 10, 0),
        updatedAt: DateTime(2026, 9, 25, 14, 30),
        deadlineDateTime: DateTime(2026, 10, 5, 23, 59),
        isCompleted: true,
        completedAt: DateTime(2026, 9, 28, 18, 0),
        subtasks: [
          Subtask(id: 'sub-1', title: 'Lexer', isCompleted: true),
          Subtask(id: 'sub-2', title: 'Parser', isCompleted: true),
          Subtask(id: 'sub-3', title: 'Code generator', isCompleted: false),
        ],
      );

      final json = original.toJson();
      final restored = Deadline.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.description, equals(original.description));
      expect(restored.category, equals(original.category));
      expect(restored.priority, equals(original.priority));
      expect(restored.deadlineDateTime, equals(original.deadlineDateTime));
      expect(restored.isCompleted, equals(original.isCompleted));
      expect(restored.completedAt, equals(original.completedAt));
      expect(restored.subtasks.length, equals(3));
      expect(restored.subtasks[0].title, equals('Lexer'));
      expect(restored.subtasks[0].isCompleted, isTrue);
      expect(restored.subtasks[2].isCompleted, isFalse);
    });
  });

  group('Phase 2 — Repository CRUD Operations', () {
    late InMemoryDatabaseService memoryDb;
    late DeadlineRepository repository;

    setUp(() {
      memoryDb = InMemoryDatabaseService();
      repository = DeadlineRepository(databaseService: memoryDb);
    });

    test('Add and retrieve deadline', () async {
      final deadline = Deadline(
        id: 'repo-1',
        title: 'Operating Systems Lab',
        category: DeadlineCategory.assignment,
        deadlineDateTime: DateTime(2026, 10, 15, 14, 0),
      );

      await repository.addDeadline(deadline);

      final retrieved = await repository.getDeadlineById('repo-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Operating Systems Lab'));

      final all = await repository.getAllDeadlines();
      expect(all.length, equals(1));
    });

    test('Multiple deadlines with identical titles are stored as separate records', () async {
      final d1 = Deadline(
        id: 'id-alpha',
        title: 'Math Assignment',
        category: DeadlineCategory.assignment,
        deadlineDateTime: DateTime(2026, 10, 1),
      );

      final d2 = Deadline(
        id: 'id-beta',
        title: 'Math Assignment',
        category: DeadlineCategory.assignment,
        deadlineDateTime: DateTime(2026, 10, 2),
      );

      await repository.addDeadline(d1);
      await repository.addDeadline(d2);

      final all = await repository.getAllDeadlines();
      expect(all.length, equals(2));
      expect(all.map((d) => d.id).toSet(), equals({'id-alpha', 'id-beta'}));
    });

    test('Update deadline preserves ID and modifies fields', () async {
      final initial = Deadline(
        id: 'upd-1',
        title: 'Initial Title',
        priority: DeadlinePriority.low,
        category: DeadlineCategory.other,
        deadlineDateTime: DateTime(2026, 10, 10),
      );

      await repository.addDeadline(initial);

      final modified = initial.copyWith(
        title: 'Updated Title',
        priority: DeadlinePriority.high,
      );

      await repository.updateDeadline(modified);

      final result = await repository.getDeadlineById('upd-1');
      expect(result!.id, equals('upd-1'));
      expect(result.title, equals('Updated Title'));
      expect(result.priority, equals(DeadlinePriority.high));
    });

    test('Complete and restore deadline', () async {
      final d = Deadline(
        id: 'comp-1',
        title: 'Hackathon Submission',
        category: DeadlineCategory.hackathon,
        deadlineDateTime: DateTime(2026, 10, 20),
      );

      await repository.addDeadline(d);
      await repository.completeDeadline('comp-1');

      var completed = await repository.getDeadlineById('comp-1');
      expect(completed!.isCompleted, isTrue);
      expect(completed.completedAt, isNotNull);

      await repository.restoreDeadline('comp-1');
      var restored = await repository.getDeadlineById('comp-1');
      expect(restored!.isCompleted, isFalse);
      expect(restored.completedAt, isNull);
    });

    test('Delete deadline and clear all', () async {
      final d1 = Deadline(id: 'del-1', title: 'Task 1', category: DeadlineCategory.other, deadlineDateTime: DateTime.now());
      final d2 = Deadline(id: 'del-2', title: 'Task 2', category: DeadlineCategory.other, deadlineDateTime: DateTime.now());

      await repository.addDeadline(d1);
      await repository.addDeadline(d2);

      await repository.deleteDeadline('del-1');
      var all = await repository.getAllDeadlines();
      expect(all.length, equals(1));
      expect(all.first.id, equals('del-2'));

      await repository.clearAllDeadlines();
      all = await repository.getAllDeadlines();
      expect(all.isEmpty, isTrue);
    });
  });
}
