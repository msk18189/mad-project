import 'dart:math';
import '../models/deadline.dart';
import '../models/deadline_statistics.dart';
import '../models/streak_stats.dart';

/// Centralized deterministic statistics computation service (Phase 7 Sections 5-23)
class StatisticsService {
  const StatisticsService();

  /// Calculates complete, reliable metrics from stored deadlines
  DeadlineStatistics calculate({
    required List<Deadline> deadlines,
    required StatisticsPeriod period,
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final streakStats = calculateStreak(deadlines, effectiveNow);

    // 1. Filter deadlines belonging to the requested period (Section 7 & 24)
    final filtered = deadlines.where((d) => _isInPeriod(d, period, effectiveNow)).toList();

    int completed = 0;
    int missed = 0;
    int pending = 0;
    int onTime = 0;
    int completedBeforeUrgent = 0;
    int completedSubtasks = 0;
    int totalSubtasks = 0;

    final Map<DeadlineCategory, int> catCounts = {
      for (final cat in DeadlineCategory.values) cat: 0,
    };

    final Map<DeadlinePriority, int> priorityCounts = {
      for (final prio in DeadlinePriority.values) prio: 0,
    };

    final Map<int, int> completionTrend = {};

    for (final d in filtered) {
      catCounts[d.category] = (catCounts[d.category] ?? 0) + 1;
      priorityCounts[d.priority] = (priorityCounts[d.priority] ?? 0) + 1;

      completedSubtasks += d.completedSubtasksCount;
      totalSubtasks += d.totalSubtasksCount;

      if (d.isCompleted) {
        completed++;

        // Section 11: On-time check
        final completionDate = d.completedAt ?? d.dueDateTime;
        if (!completionDate.isAfter(d.dueDateTime)) {
          onTime++;
        }

        // Section 14: Completed before entering urgent window (> 24 hours before due)
        final remainingAtCompletion = d.dueDateTime.difference(completionDate);
        if (remainingAtCompletion > const Duration(hours: 24)) {
          completedBeforeUrgent++;
        }

        // Section 17: Completion Trend
        if (period == StatisticsPeriod.week) {
          final weekday = completionDate.toLocal().weekday; // 1 = Monday .. 7 = Sunday
          completionTrend[weekday] = (completionTrend[weekday] ?? 0) + 1;
        } else if (period == StatisticsPeriod.month) {
          final day = completionDate.toLocal().day;
          completionTrend[day] = (completionTrend[day] ?? 0) + 1;
        } else {
          // All time: group by last 7 days index
          final daysAgo = effectiveNow.difference(completionDate).inDays;
          if (daysAgo >= 0 && daysAgo < 7) {
            completionTrend[6 - daysAgo] = (completionTrend[6 - daysAgo] ?? 0) + 1;
          }
        }
      } else if (d.isPassed(effectiveNow)) {
        missed++;
      } else {
        pending++;
      }
    }

    final total = completed + missed + pending;

    // Section 11: On-time rate
    final double? onTimeRate = completed > 0 ? (onTime / completed) * 100 : null;

    // Section 12: Completion rate (completed / [completed + missed])
    final totalResolved = completed + missed;
    final double? completionRate = totalResolved > 0 ? (completed / totalResolved) * 100 : null;

    // Section 13: Subtask progress
    final double subtaskProgress = totalSubtasks > 0 ? (completedSubtasks / totalSubtasks).clamp(0.0, 1.0) : 0.0;

    // Section 14 & 15: Urgent pressure
    final lastMinute = completed - completedBeforeUrgent;
    final double? beforeUrgentRate = completed > 0 ? (completedBeforeUrgent / completed) * 100 : null;

    return DeadlineStatistics(
      period: period,
      totalCount: total,
      completedCount: completed,
      pendingCount: pending,
      missedCount: missed,
      onTimeRate: onTimeRate,
      completionRate: completionRate,
      completedSubtasksCount: completedSubtasks,
      totalSubtasksCount: totalSubtasks,
      subtaskProgress: subtaskProgress,
      completedBeforeUrgentCount: completedBeforeUrgent,
      lastMinuteCompletionsCount: lastMinute,
      completedBeforeUrgentRate: beforeUrgentRate,
      categoryCounts: catCounts,
      priorityCounts: priorityCounts,
      completionTrend: completionTrend,
      streakStats: streakStats,
    );
  }

  /// Determines whether a deadline is relevant to the given period (Section 7)
  bool _isInPeriod(Deadline d, StatisticsPeriod period, DateTime now) {
    if (period == StatisticsPeriod.allTime) return true;

    final targetDate = d.isCompleted
        ? (d.completedAt?.toLocal() ?? d.dueDateTime.toLocal())
        : d.dueDateTime.toLocal();

    if (period == StatisticsPeriod.week) {
      // Monday 00:00 of current week
      final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      final nextMonday = monday.add(const Duration(days: 7));
      return (targetDate.isAfter(monday) || targetDate.isAtSameMomentAs(monday)) &&
          targetDate.isBefore(nextMonday);
    } else {
      // Current month
      return targetDate.year == now.year && targetDate.month == now.month;
    }
  }

  /// Calculates real consecutive day streak from user completion events (Section 20-22)
  StreakStats calculateStreak(List<Deadline> deadlines, [DateTime? now]) {
    final effectiveNow = now ?? DateTime.now();
    final today = DateTime(effectiveNow.year, effectiveNow.month, effectiveNow.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Extract unique completion calendar dates in local time
    final Set<DateTime> completionDays = {};
    for (final d in deadlines) {
      if (d.isCompleted) {
        final date = (d.completedAt ?? d.dueDateTime).toLocal();
        completionDays.add(DateTime(date.year, date.month, date.day));
      }
    }

    if (completionDays.isEmpty) {
      return const StreakStats();
    }

    final sortedDays = completionDays.toList()..sort((a, b) => a.compareTo(b));

    // Calculate longest consecutive streak in user history
    int longest = 1;
    int currentRun = 1;
    for (int i = 1; i < sortedDays.length; i++) {
      if (sortedDays[i].difference(sortedDays[i - 1]).inDays == 1) {
        currentRun++;
        longest = max(longest, currentRun);
      } else {
        currentRun = 1;
      }
    }

    // Calculate current active streak leading up to today (or yesterday)
    int current = 0;
    final lastDay = sortedDays.last;

    if (lastDay.isAtSameMomentAs(today) || lastDay.isAtSameMomentAs(yesterday)) {
      // Count backwards
      current = 1;
      var checkDay = lastDay.subtract(const Duration(days: 1));
      while (completionDays.contains(checkDay)) {
        current++;
        checkDay = checkDay.subtract(const Duration(days: 1));
      }
    }

    return StreakStats(
      currentStreak: current,
      longestStreak: longest,
      totalCompleted: sortedDays.length,
      lastCompletedDate: sortedDays.last,
    );
  }
}
