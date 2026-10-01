import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deadline/core/utils/countdown_engine.dart';
import 'package:deadline/models/deadline.dart';
import 'package:deadline/widgets/category_badge.dart';
import 'package:deadline/widgets/countdown_display.dart';
import 'package:deadline/widgets/priority_badge.dart';
import 'package:deadline/widgets/tactile_progress_bar.dart';
import 'package:deadline/widgets/time_pressure_gauge.dart';

void main() {
  group('CountdownEngine Tests', () {
    test('Calculates future target correctly', () {
      final now = DateTime(2026, 9, 30, 12, 0, 0);
      final target = DateTime(2026, 10, 2, 14, 30, 45); // 2 days, 2 hours, 30 min, 45 sec

      final result = CountdownEngine.calculate(target, now);
      expect(result.isPassed, isFalse);
      expect(result.days, equals(2));
      expect(result.hours, equals(2));
      expect(result.minutes, equals(30));
      expect(result.seconds, equals(45));
    });

    test('Detects passed deadline', () {
      final now = DateTime(2026, 9, 30, 12, 0, 0);
      final target = DateTime(2026, 9, 30, 11, 59, 59);

      final result = CountdownEngine.calculate(target, now);
      expect(result.isPassed, isTrue);
      expect(result.formattedAdaptive, equals('PASSED'));
    });
  });

  group('Deadline Domain Logic Tests', () {
    test('Calculates subtask progress accurately and clamps', () {
      final deadline = Deadline(
        id: 'test-1',
        title: 'Project Alpha',
        category: DeadlineCategory.project,
        priority: DeadlinePriority.high,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        deadlineDateTime: DateTime.now().add(const Duration(days: 1)),
        subtasks: [
          Subtask(id: 's1', title: 'Task 1', isCompleted: true),
          Subtask(id: 's2', title: 'Task 2', isCompleted: false),
          Subtask(id: 's3', title: 'Task 3', isCompleted: true),
          Subtask(id: 's4', title: 'Task 4', isCompleted: false),
        ],
      );

      expect(deadline.subtaskProgress, equals(0.5));
      expect(deadline.subtaskSummary, equals('2 / 4'));
    });

    test('Clamps time progress strictly between 0.0 and 1.0', () {
      final created = DateTime(2026, 9, 1, 0, 0);
      final due = DateTime(2026, 9, 10, 0, 0);

      final deadline = Deadline(
        id: 'test-2',
        title: 'Time Clamping Test',
        category: DeadlineCategory.assignment,
        priority: DeadlinePriority.medium,
        createdAt: created,
        deadlineDateTime: due,
      );

      // Before creation
      expect(deadline.timeProgress(DateTime(2026, 8, 30)), equals(0.0));
      // Midpoint
      expect(deadline.timeProgress(DateTime(2026, 9, 5, 12, 0)), closeTo(0.5, 0.01));
      // After due
      expect(deadline.timeProgress(DateTime(2026, 9, 15)), equals(1.0));
    });

    test('Calculates deterministic time pressure', () {
      final now = DateTime(2026, 9, 30, 12, 0);
      final deadline = Deadline(
        id: 'test-3',
        title: 'Critical Rush',
        category: DeadlineCategory.exam,
        priority: DeadlinePriority.high,
        createdAt: now.subtract(const Duration(days: 2)),
        deadlineDateTime: now.add(const Duration(hours: 2)), // Under 3h -> 60 proximity points
      );

      final pressure = deadline.calculateTimePressure(now);
      expect(pressure, greaterThan(85.0));
    });

    test('Serializes to and from JSON losslessly', () {
      final original = Deadline(
        id: 'json-1',
        title: 'Serialization Check',
        description: 'Verify JSON integrity',
        category: DeadlineCategory.hackathon,
        priority: DeadlinePriority.high,
        createdAt: DateTime(2026, 9, 30, 10, 0),
        deadlineDateTime: DateTime(2026, 10, 5, 18, 0),
        subtasks: [
          Subtask(id: 'sub-1', title: 'Subtask 1', isCompleted: true),
        ],
      );

      final json = original.toJson();
      final restored = Deadline.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.category, equals(original.category));
      expect(restored.priority, equals(original.priority));
      expect(restored.subtasks.length, equals(1));
      expect(restored.subtasks.first.isCompleted, isTrue);
    });
  });

  group('UI Core Widgets Smoke Tests', () {
    testWidgets('Renders Badges and Progress bars cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const PriorityBadge(priority: DeadlinePriority.high),
                    const CategoryBadge(category: DeadlineCategory.project),
                    const TactileProgressBar(value: 0.75, label: 'Progress'),
                    const TimePressureGauge(score: 85),
                    CountdownDisplay(
                      targetDate: DateTime.now().add(const Duration(hours: 3)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PriorityBadge), findsOneWidget);
      expect(find.byType(CategoryBadge), findsOneWidget);
      expect(find.byType(TactileProgressBar), findsOneWidget);
      expect(find.byType(TimePressureGauge), findsOneWidget);
      expect(find.byType(CountdownDisplay), findsOneWidget);
      expect(find.text('PROJECT'), findsOneWidget);
      expect(find.text('PROGRESS'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });
  });
}
