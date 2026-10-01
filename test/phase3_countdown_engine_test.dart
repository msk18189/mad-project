import 'package:flutter_test/flutter_test.dart';
import 'package:deadline/core/utils/countdown_utils.dart';
import 'package:deadline/core/utils/deadline_status_resolver.dart';
import 'package:deadline/core/utils/time_progress.dart';
import 'package:deadline/models/deadline.dart';
import 'package:deadline/providers/deadline_state.dart';

void main() {
  final referenceTime = DateTime(2026, 9, 30, 12, 0, 0);

  group('Phase 3 — Countdown Calculations & Formatting (Section 50)', () {
    test('> 7 days remaining format (e.g. 12d 08h LEFT)', () {
      final target = referenceTime.add(const Duration(days: 12, hours: 8));
      final countdown = CountdownUtils.calculate(target, now: referenceTime);

      expect(countdown.isExpired, isFalse);
      expect(countdown.days, equals(12));
      expect(countdown.hours, equals(8));
      expect(countdown.formatted, equals('12d 08h LEFT'));
    });

    test('1 to 7 days remaining format (e.g. 3d 14h 22m LEFT)', () {
      final target = referenceTime.add(const Duration(days: 3, hours: 14, minutes: 22));
      final countdown = CountdownUtils.calculate(target, now: referenceTime);

      expect(countdown.isExpired, isFalse);
      expect(countdown.days, equals(3));
      expect(countdown.hours, equals(14));
      expect(countdown.minutes, equals(22));
      expect(countdown.formatted, equals('3d 14h 22m LEFT'));
    });

    test('1 to 24 hours remaining format (e.g. 08h 14m 32s LEFT)', () {
      final target = referenceTime.add(const Duration(hours: 8, minutes: 14, seconds: 32));
      final countdown = CountdownUtils.calculate(target, now: referenceTime);

      expect(countdown.isExpired, isFalse);
      expect(countdown.days, equals(0));
      expect(countdown.hours, equals(8));
      expect(countdown.minutes, equals(14));
      expect(countdown.seconds, equals(32));
      expect(countdown.formatted, equals('08h 14m 32s LEFT'));
    });

    test('1 to 60 minutes remaining format (e.g. 42m 18s LEFT)', () {
      final target = referenceTime.add(const Duration(minutes: 42, seconds: 18));
      final countdown = CountdownUtils.calculate(target, now: referenceTime);

      expect(countdown.isExpired, isFalse);
      expect(countdown.hours, equals(0));
      expect(countdown.minutes, equals(42));
      expect(countdown.seconds, equals(18));
      expect(countdown.formatted, equals('42m 18s LEFT'));
    });

    test('Less than 1 minute remaining format (e.g. 30s LEFT)', () {
      final target = referenceTime.add(const Duration(seconds: 30));
      final countdown = CountdownUtils.calculate(target, now: referenceTime);

      expect(countdown.isExpired, isFalse);
      expect(countdown.totalSeconds, equals(30));
      expect(countdown.formatted, equals('30s LEFT'));
    });

    test('Exactly zero remaining resolves to DUE NOW', () {
      final target = referenceTime;
      final countdown = CountdownUtils.calculate(target, now: referenceTime);

      expect(countdown.isExpired, isFalse);
      expect(countdown.isDue, isTrue);
      expect(countdown.formatted, equals('DUE NOW'));
    });

    test('One second past deadline resolves to DEADLINE PASSED with no negative values', () {
      final target = referenceTime.subtract(const Duration(seconds: 1));
      final countdown = CountdownUtils.calculate(target, now: referenceTime);

      expect(countdown.isExpired, isTrue);
      expect(countdown.totalSeconds, equals(0));
      expect(countdown.remaining, equals(Duration.zero));
      expect(countdown.formatted, equals('DEADLINE PASSED'));
      expect(countdown.formatted.contains('-'), isFalse);
    });

    test('Semantic label provides detailed breakdown for accessibility', () {
      final target = referenceTime.add(const Duration(days: 2, hours: 3, minutes: 4, seconds: 5));
      final countdown = CountdownUtils.calculate(target, now: referenceTime);

      expect(countdown.semanticLabel, equals('2 days, 3 hours, 4 minutes, 5 seconds remaining'));
    });
  });

  group('Phase 3 — Status Transitions & Priority Rules (Section 51)', () {
    test('5 days in future -> upcoming', () {
      final target = referenceTime.add(const Duration(days: 5));
      final status = DeadlineStatusResolver.resolve(
        isCompleted: false,
        deadlineDateTime: target,
        now: referenceTime,
      );
      expect(status, equals(DeadlineStatus.upcoming));
    });

    test('2 days in future -> approaching', () {
      final target = referenceTime.add(const Duration(days: 2));
      final status = DeadlineStatusResolver.resolve(
        isCompleted: false,
        deadlineDateTime: target,
        now: referenceTime,
      );
      expect(status, equals(DeadlineStatus.approaching));
    });

    test('12 hours in future -> urgent', () {
      final target = referenceTime.add(const Duration(hours: 12));
      final status = DeadlineStatusResolver.resolve(
        isCompleted: false,
        deadlineDateTime: target,
        now: referenceTime,
      );
      expect(status, equals(DeadlineStatus.urgent));
    });

    test('1 hour in future -> due', () {
      final target = referenceTime.add(const Duration(hours: 1));
      final status = DeadlineStatusResolver.resolve(
        isCompleted: false,
        deadlineDateTime: target,
        now: referenceTime,
      );
      expect(status, equals(DeadlineStatus.due));
    });

    test('Past deadline -> missed', () {
      final target = referenceTime.subtract(const Duration(hours: 2));
      final status = DeadlineStatusResolver.resolve(
        isCompleted: false,
        deadlineDateTime: target,
        now: referenceTime,
      );
      expect(status, equals(DeadlineStatus.missed));
    });

    test('Past deadline + completed -> completed (completed always wins)', () {
      final target = referenceTime.subtract(const Duration(days: 1));
      final status = DeadlineStatusResolver.resolve(
        isCompleted: true,
        deadlineDateTime: target,
        now: referenceTime,
      );
      expect(status, equals(DeadlineStatus.completed));
    });
  });

  group('Phase 3 — Time Progress Calculations (Section 52)', () {
    test('Just created -> 0.0 progress', () {
      final created = referenceTime;
      final target = referenceTime.add(const Duration(days: 10));

      final progress = TimeProgress.calculate(
        createdAt: created,
        deadlineDateTime: target,
        now: referenceTime,
      );
      expect(progress, equals(0.0));
      expect(TimeProgress.formatPercent(progress), equals('0%'));
    });

    test('Halfway elapsed -> 0.5 progress', () {
      final created = referenceTime.subtract(const Duration(days: 5));
      final target = referenceTime.add(const Duration(days: 5));

      final progress = TimeProgress.calculate(
        createdAt: created,
        deadlineDateTime: target,
        now: referenceTime,
      );
      expect(progress, closeTo(0.5, 0.001));
      expect(TimeProgress.formatPercent(progress), equals('50%'));
    });

    test('Past deadline -> clamped strictly to 1.0', () {
      final created = referenceTime.subtract(const Duration(days: 10));
      final target = referenceTime.subtract(const Duration(days: 2));

      final progress = TimeProgress.calculate(
        createdAt: created,
        deadlineDateTime: target,
        now: referenceTime,
      );
      expect(progress, equals(1.0));
      expect(TimeProgress.formatPercent(progress), equals('100%'));
    });

    test('Future createdAt (now < createdAt) -> safely returns 0.0', () {
      final created = referenceTime.add(const Duration(hours: 1));
      final target = referenceTime.add(const Duration(days: 5));

      final progress = TimeProgress.calculate(
        createdAt: created,
        deadlineDateTime: target,
        now: referenceTime,
      );
      expect(progress, equals(0.0));
    });

    test('Zero-duration deadline (createdAt == deadlineDateTime) handled without division by zero', () {
      final moment = referenceTime;

      final progress = TimeProgress.calculate(
        createdAt: moment,
        deadlineDateTime: moment,
        now: referenceTime,
      );
      expect(progress, equals(1.0));
    });
  });

  group('Phase 3 — Deterministic Sorting & Selectors (Section 53 & 54)', () {
    final tomorrow = referenceTime.add(const Duration(days: 1));
    final today = referenceTime.add(const Duration(hours: 4));
    final nextWeek = referenceTime.add(const Duration(days: 7));

    final deadlineA = Deadline(
      id: 'a',
      title: 'Tomorrow Deadline',
      category: DeadlineCategory.project,
      priority: DeadlinePriority.medium,
      deadlineDateTime: tomorrow,
    );

    final deadlineB = Deadline(
      id: 'b',
      title: 'Today Deadline',
      category: DeadlineCategory.assignment,
      priority: DeadlinePriority.high,
      deadlineDateTime: today,
    );

    final deadlineC = Deadline(
      id: 'c',
      title: 'Next Week Deadline',
      category: DeadlineCategory.event,
      priority: DeadlinePriority.low,
      deadlineDateTime: nextWeek,
    );

    test('Active deadlines sorted earliest first: B, A, C', () {
      final state = DeadlineState(deadlines: [deadlineA, deadlineB, deadlineC]);
      final sorted = state.activeDeadlines(referenceTime);

      expect(sorted.length, equals(3));
      expect(sorted[0].id, equals('b')); // Today
      expect(sorted[1].id, equals('a')); // Tomorrow
      expect(sorted[2].id, equals('c')); // Next week
    });

    test('Deterministic Hero selection picks nearest active future deadline', () {
      final state = DeadlineState(deadlines: [deadlineA, deadlineB, deadlineC]);
      final hero = state.nextDeadline(referenceTime);

      expect(hero, isNotNull);
      expect(hero!.id, equals('b')); // Today deadline is the hero
    });

    test('Completed and missed deadlines are never selected as Hero', () {
      final completed = Deadline(
        id: 'comp',
        title: 'Old Finished',
        category: DeadlineCategory.assignment,
        priority: DeadlinePriority.high,
        deadlineDateTime: referenceTime.subtract(const Duration(days: 2)),
        isCompleted: true,
      );

      final missed = Deadline(
        id: 'miss',
        title: 'Missed Task',
        category: DeadlineCategory.assignment,
        priority: DeadlinePriority.high,
        deadlineDateTime: referenceTime.subtract(const Duration(hours: 1)),
        isCompleted: false,
      );

      final state = DeadlineState(deadlines: [completed, missed, deadlineC]);
      final hero = state.nextDeadline(referenceTime);

      expect(hero, isNotNull);
      expect(hero!.id, equals('c')); // Only active future item qualifies
      expect(state.completedDeadlines.map((d) => d.id), contains('comp'));
      expect(state.missedDeadlines(referenceTime).map((d) => d.id), contains('miss'));
    });
  });

  group('Phase 3 — Relative Date Formatting (Section 45 & 46)', () {
    test('Formats TODAY correctly with time', () {
      final target = DateTime(2026, 9, 30, 20, 30);
      final text = CountdownUtils.formatRelativeDate(target, now: referenceTime);
      expect(text, equals('TODAY · 8:30 PM'));
    });

    test('Formats TOMORROW correctly with time', () {
      final target = DateTime(2026, 10, 1, 10, 0);
      final text = CountdownUtils.formatRelativeDate(target, now: referenceTime);
      expect(text, equals('TOMORROW · 10:00 AM'));
    });
  });
}
