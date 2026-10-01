import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deadline/models/deadline.dart';
import 'package:deadline/models/deadline_statistics.dart';
import 'package:deadline/services/statistics_service.dart';
import 'package:deadline/widgets/animations/press_scale.dart';
import 'package:deadline/widgets/statistics/stat_block.dart';
import 'package:deadline/widgets/statistics/streak_card.dart';

void main() {
  const service = StatisticsService();

  group('Phase 7 - Statistics Calculation Tests (Section 61)', () {
    final now = DateTime(2026, 9, 30, 15, 0);

    test('Empty dataset produces null rates and isEmpty true', () {
      final stats = service.calculate(
        deadlines: const [],
        period: StatisticsPeriod.allTime,
        now: now,
      );

      expect(stats.totalCount, 0);
      expect(stats.completedCount, 0);
      expect(stats.missedCount, 0);
      expect(stats.pendingCount, 0);
      expect(stats.completionRate, isNull);
      expect(stats.onTimeRate, isNull);
      expect(stats.completedSubtasksCount, 0);
      expect(stats.totalSubtasksCount, 0);
      expect(stats.subtaskProgress, 0.0);
      expect(stats.isEmpty, isTrue);
    });

    test('Completed, Missed, and Active counts with on-time & completion rates', () {
      final deadlines = [
        // 1. Completed on-time (> 24h before due)
        Deadline(
          id: 'dl_comp_1',
          title: 'Finished Early',
          category: DeadlineCategory.project,
          priority: DeadlinePriority.high,
          deadlineDateTime: now.add(const Duration(days: 3)),
          isCompleted: true,
          completedAt: now,
          subtasks: [
            Subtask(id: 's1', deadlineId: 'dl_comp_1', title: 'Task 1', isCompleted: true, createdAt: now),
            Subtask(id: 's2', deadlineId: 'dl_comp_1', title: 'Task 2', isCompleted: true, createdAt: now),
          ],
        ),
        // 2. Completed last-minute (within 24h of due)
        Deadline(
          id: 'dl_comp_2',
          title: 'Finished Last Minute',
          category: DeadlineCategory.assignment,
          priority: DeadlinePriority.medium,
          deadlineDateTime: now.add(const Duration(hours: 4)),
          isCompleted: true,
          completedAt: now,
          subtasks: [
            Subtask(id: 's3', deadlineId: 'dl_comp_2', title: 'Task 3', isCompleted: true, createdAt: now),
            Subtask(id: 's4', deadlineId: 'dl_comp_2', title: 'Task 4', isCompleted: false, createdAt: now),
          ],
        ),
        // 3. Missed deadline (past, incomplete)
        Deadline(
          id: 'dl_miss_1',
          title: 'Overdue Project',
          category: DeadlineCategory.exam,
          priority: DeadlinePriority.high,
          deadlineDateTime: now.subtract(const Duration(days: 1)),
          isCompleted: false,
        ),
        // 4. Active deadline
        Deadline(
          id: 'dl_active_1',
          title: 'Future Assignment',
          category: DeadlineCategory.hackathon,
          priority: DeadlinePriority.low,
          deadlineDateTime: now.add(const Duration(days: 5)),
          isCompleted: false,
        ),
      ];

      final stats = service.calculate(
        deadlines: deadlines,
        period: StatisticsPeriod.allTime,
        now: now,
      );

      expect(stats.totalCount, 4);
      expect(stats.completedCount, 2);
      expect(stats.missedCount, 1);
      expect(stats.pendingCount, 1);

      // On-time rate: 2 completed on/before deadline / 2 total completed = 100%
      expect(stats.onTimeRate, 100.0);

      // Completion rate: 2 completed / (2 completed + 1 missed) = 66.67%
      expect(stats.completionRate, closeTo(66.66, 0.05));

      // Subtasks: 3 completed out of 4 total = 75%
      expect(stats.completedSubtasksCount, 3);
      expect(stats.totalSubtasksCount, 4);
      expect(stats.subtaskProgress, 0.75);

      // Time pressure: 1 completed before urgent (>24h), 1 last-minute
      expect(stats.completedBeforeUrgentCount, 1);
      expect(stats.lastMinuteCompletionsCount, 1);
      expect(stats.completedBeforeUrgentRate, 50.0);

      // Category breakdown
      expect(stats.categoryCounts[DeadlineCategory.project], 1);
      expect(stats.categoryCounts[DeadlineCategory.assignment], 1);
      expect(stats.categoryCounts[DeadlineCategory.exam], 1);
      expect(stats.categoryCounts[DeadlineCategory.hackathon], 1);

      // Priority breakdown
      expect(stats.priorityCounts[DeadlinePriority.high], 2);
      expect(stats.priorityCounts[DeadlinePriority.medium], 1);
      expect(stats.priorityCounts[DeadlinePriority.low], 1);
    });
  });

  group('Phase 7 - Streak Calculation Tests (Section 20-22, 62)', () {
    test('Zero completed deadlines produces 0 streak', () {
      final now = DateTime(2026, 9, 30);
      final streak = service.calculateStreak(const [], now);

      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
    });

    test('1 completion today produces 1 day streak', () {
      final now = DateTime(2026, 9, 30, 14, 0);
      final deadlines = [
        Deadline(
          id: 's_1',
          title: 'Task Today',
          category: DeadlineCategory.project,
          deadlineDateTime: now,
          isCompleted: true,
          completedAt: now,
        ),
      ];

      final streak = service.calculateStreak(deadlines, now);
      expect(streak.currentStreak, 1);
      expect(streak.longestStreak, 1);
    });

    test('Consecutive completions over 3 days (Sept 28, 29, 30)', () {
      final now = DateTime(2026, 9, 30, 14, 0);
      final deadlines = [
        Deadline(
          id: 's_28',
          title: 'Day 1',
          category: DeadlineCategory.project,
          deadlineDateTime: DateTime(2026, 9, 28),
          isCompleted: true,
          completedAt: DateTime(2026, 9, 28, 10, 0),
        ),
        Deadline(
          id: 's_29',
          title: 'Day 2',
          category: DeadlineCategory.project,
          deadlineDateTime: DateTime(2026, 9, 29),
          isCompleted: true,
          completedAt: DateTime(2026, 9, 29, 12, 0),
        ),
        Deadline(
          id: 's_30',
          title: 'Day 3',
          category: DeadlineCategory.project,
          deadlineDateTime: DateTime(2026, 9, 30),
          isCompleted: true,
          completedAt: DateTime(2026, 9, 30, 9, 0),
        ),
      ];

      final streak = service.calculateStreak(deadlines, now);
      expect(streak.currentStreak, 3);
      expect(streak.longestStreak, 3);
    });

    test('Consecutive across month boundary (Sept 29, 30 -> Oct 1)', () {
      final now = DateTime(2026, 10, 1, 12, 0);
      final deadlines = [
        Deadline(
          id: 's_29',
          title: 'Sept 29',
          category: DeadlineCategory.project,
          deadlineDateTime: DateTime(2026, 9, 29),
          isCompleted: true,
          completedAt: DateTime(2026, 9, 29),
        ),
        Deadline(
          id: 's_30',
          title: 'Sept 30',
          category: DeadlineCategory.project,
          deadlineDateTime: DateTime(2026, 9, 30),
          isCompleted: true,
          completedAt: DateTime(2026, 9, 30),
        ),
        Deadline(
          id: 's_1',
          title: 'Oct 1',
          category: DeadlineCategory.project,
          deadlineDateTime: DateTime(2026, 10, 1),
          isCompleted: true,
          completedAt: DateTime(2026, 10, 1),
        ),
      ];

      final streak = service.calculateStreak(deadlines, now);
      expect(streak.currentStreak, 3);
      expect(streak.longestStreak, 3);
    });

    test('Streak broken by 2-day gap preserves longestStreak', () {
      final now = DateTime(2026, 9, 30, 12, 0);
      // Completed on Sept 20, 21, 22, 23 (4 days), then nothing until today
      final deadlines = [
        for (int i = 20; i <= 23; i++)
          Deadline(
            id: 's_$i',
            title: 'Task $i',
            category: DeadlineCategory.project,
            deadlineDateTime: DateTime(2026, 9, i),
            isCompleted: true,
            completedAt: DateTime(2026, 9, i),
          ),
      ];

      final streak = service.calculateStreak(deadlines, now);
      // Last was Sept 23, today is Sept 30 -> current streak broken (0)
      expect(streak.currentStreak, 0);
      // Longest streak was 4 days
      expect(streak.longestStreak, 4);
    });

    test('Multiple completions on same day count as single streak day', () {
      final now = DateTime(2026, 9, 30, 18, 0);
      final deadlines = [
        for (int i = 0; i < 5; i++)
          Deadline(
            id: 'same_day_$i',
            title: 'Task $i',
            category: DeadlineCategory.project,
            deadlineDateTime: DateTime(2026, 9, 30, 10 + i),
            isCompleted: true,
            completedAt: DateTime(2026, 9, 30, 10 + i),
          ),
      ];

      final streak = service.calculateStreak(deadlines, now);
      expect(streak.currentStreak, 1);
      expect(streak.longestStreak, 1);
    });
  });

  group('Phase 8 - Tactile Micro-interaction & UI Widget Tests (Section 34, 44)', () {
    testWidgets('PressScale renders child and responds to taps', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PressScale(
              onTap: () => tapped = true,
              child: const Text('TACTILE BUTTON'),
            ),
          ),
        ),
      );

      expect(find.text('TACTILE BUTTON'), findsOneWidget);
      await tester.tap(find.text('TACTILE BUTTON'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('StatBlock renders label, value, and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatBlock(
              label: 'COMPLETED',
              value: '14',
              subtitle: 'this month',
            ),
          ),
        ),
      );

      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('this month'), findsOneWidget);
    });

    testWidgets('StreakCard renders streak count and motivational text', (tester) async {
      final stats = service.calculate(
        deadlines: [
          Deadline(
            id: 'streak_t1',
            title: 'Done',
            category: DeadlineCategory.project,
            deadlineDateTime: DateTime.now(),
            isCompleted: true,
            completedAt: DateTime.now(),
          ),
        ],
        period: StatisticsPeriod.allTime,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreakCard(
              streakStats: stats.streakStats,
            ),
          ),
        ),
      );

      expect(find.text('DISCIPLINE STREAK'), findsOneWidget);
      expect(find.text('1 DAY IN A ROW'), findsOneWidget);
      expect(find.text("You've been showing up. Keep the momentum alive."), findsOneWidget);
    });
  });
}
