import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deadline/models/deadline.dart';
import 'package:deadline/widgets/deadline_progress.dart';

void main() {
  group('Phase 5 - Subtask Model Tests', () {
    test('Create subtask with all fields', () {
      final now = DateTime.now();
      final subtask = Subtask(
        id: 'sub_1',
        deadlineId: 'dl_1',
        title: 'Research dataset',
        description: 'Check Kaggle and HuggingFace',
        isCompleted: false,
        createdAt: now,
        sortOrder: 0,
      );

      expect(subtask.id, 'sub_1');
      expect(subtask.deadlineId, 'dl_1');
      expect(subtask.title, 'Research dataset');
      expect(subtask.description, 'Check Kaggle and HuggingFace');
      expect(subtask.isCompleted, isFalse);
      expect(subtask.completedAt, isNull);
      expect(subtask.sortOrder, 0);
    });

    test('Subtask serialization toJson and fromJson', () {
      final now = DateTime.now();
      final completedTime = now.add(const Duration(minutes: 30));
      final subtask = Subtask(
        id: 'sub_2',
        deadlineId: 'dl_99',
        title: 'Train ML model',
        description: 'Use ResNet50 backbone',
        isCompleted: true,
        createdAt: now,
        completedAt: completedTime,
        sortOrder: 2,
      );

      final json = subtask.toJson();
      final parsed = Subtask.fromJson(json);

      expect(parsed.id, subtask.id);
      expect(parsed.deadlineId, 'dl_99');
      expect(parsed.title, 'Train ML model');
      expect(parsed.description, 'Use ResNet50 backbone');
      expect(parsed.isCompleted, isTrue);
      expect(parsed.completedAt?.millisecondsSinceEpoch, completedTime.millisecondsSinceEpoch);
      expect(parsed.sortOrder, 2);
    });

    test('Subtask copyWith updates completion and timestamp', () {
      final now = DateTime.now();
      final subtask = Subtask(
        id: 'sub_3',
        deadlineId: 'dl_1',
        title: 'Evaluate model',
        isCompleted: false,
        createdAt: now,
      );

      // Incomplete -> Complete (Section 10)
      final completed = subtask.copyWith(
        isCompleted: true,
        completedAt: now,
      );
      expect(completed.isCompleted, isTrue);
      expect(completed.completedAt, isNotNull);

      // Complete -> Incomplete restoration (Section 10)
      final restored = completed.copyWith(
        isCompleted: false,
        completedAt: null,
      );
      expect(restored.isCompleted, isFalse);
      expect(restored.completedAt, isNull);
    });
  });

  group('Phase 5 - Deadline Progress Calculation Tests (Section 11 & 12)', () {
    test('Zero subtasks produces 0.0 progress and hasSubtasks is false', () {
      final deadline = Deadline(
        id: 'dl_progress_0',
        title: 'Project Without Subtasks',
        category: DeadlineCategory.project,
        deadlineDateTime: DateTime.now().add(const Duration(days: 1)),
        subtasks: const [],
      );

      expect(deadline.subtasks.isEmpty, isTrue);
      expect(deadline.subtaskProgress, 0.0);
      expect(deadline.completedSubtasksCount, 0);
      expect(deadline.totalSubtasksCount, 0);
    });

    test('Deterministic progress: 0/5, 1/5, 3/6, 5/5', () {
      final now = DateTime.now();

      // 0 / 5 complete (0%)
      final subtasks5Incomplete = List.generate(
        5,
        (i) => Subtask(
          id: 'sub_$i',
          deadlineId: 'dl_test',
          title: 'Step $i',
          isCompleted: false,
          createdAt: now,
          sortOrder: i,
        ),
      );
      final dl5Incomplete = Deadline(
        id: 'dl_5_0',
        title: 'Project 0/5',
        category: DeadlineCategory.project,
        deadlineDateTime: now.add(const Duration(days: 2)),
        subtasks: subtasks5Incomplete,
      );
      expect(dl5Incomplete.completedSubtasksCount, 0);
      expect(dl5Incomplete.totalSubtasksCount, 5);
      expect(dl5Incomplete.subtaskProgress, 0.0);

      // 1 / 5 complete (20%)
      final subtasks1Done = [
        subtasks5Incomplete[0].copyWith(isCompleted: true, completedAt: now),
        ...subtasks5Incomplete.sublist(1),
      ];
      final dl1Done = dl5Incomplete.copyWith(subtasks: subtasks1Done);
      expect(dl1Done.completedSubtasksCount, 1);
      expect(dl1Done.totalSubtasksCount, 5);
      expect(dl1Done.subtaskProgress, 0.2);

      // 3 / 6 complete (50%)
      final subtasks6 = List.generate(
        6,
        (i) => Subtask(
          id: 'sub_6_$i',
          deadlineId: 'dl_test_6',
          title: 'Step $i',
          isCompleted: i < 3,
          createdAt: now,
          sortOrder: i,
        ),
      );
      final dl3Of6 = Deadline(
        id: 'dl_6_3',
        title: 'Project 3/6',
        category: DeadlineCategory.project,
        deadlineDateTime: now.add(const Duration(days: 2)),
        subtasks: subtasks6,
      );
      expect(dl3Of6.completedSubtasksCount, 3);
      expect(dl3Of6.totalSubtasksCount, 6);
      expect(dl3Of6.subtaskProgress, 0.5);

      // 5 / 5 complete (100%)
      final subtasks5Complete = subtasks5Incomplete.map((s) => s.copyWith(isCompleted: true)).toList();
      final dl5Done = dl5Incomplete.copyWith(subtasks: subtasks5Complete);
      expect(dl5Done.completedSubtasksCount, 5);
      expect(dl5Done.totalSubtasksCount, 5);
      expect(dl5Done.subtaskProgress, 1.0);
    });
  });

  group('Phase 5 - DeadlineProgress Widget Tests (Section 12 & 13)', () {
    testWidgets('Renders encouraging zero-subtask state when total is 0', (tester) async {
      bool addPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineProgress(
              subtasks: const [],
              onAddFirstTask: () => addPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('NO TASKS YET'), findsOneWidget);
      expect(find.text('Break the deadline into smaller steps.'), findsOneWidget);
      expect(find.text('+ ADD FIRST TASK'), findsOneWidget);

      await tester.tap(find.text('+ ADD FIRST TASK'));
      expect(addPressed, isTrue);
    });

    testWidgets('Renders progress bar and percentage when subtasks exist', (tester) async {
      final now = DateTime.now();
      final subtasks = List.generate(
        8,
        (i) => Subtask(
          id: 'sub_$i',
          deadlineId: 'dl_test',
          title: 'Task $i',
          isCompleted: i < 5, // 5 of 8 completed
          createdAt: now,
          sortOrder: i,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineProgress(
              subtasks: subtasks,
            ),
          ),
        ),
      );

      expect(find.text('TASK PROGRESS'), findsOneWidget);
      expect(find.text('5 / 8 COMPLETE'), findsOneWidget);
      expect(find.text('63%'), findsOneWidget); // 5/8 = 62.5% -> rounded to 63%
    });
  });
}
