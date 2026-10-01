import 'package:flutter/foundation.dart';
import 'category.dart';
import 'priority.dart';
import 'streak_stats.dart';

/// Supported statistics time periods (Section 7 & 24)
enum StatisticsPeriod {
  week,
  month,
  allTime;

  String get label {
    switch (this) {
      case StatisticsPeriod.week:
        return 'THIS WEEK';
      case StatisticsPeriod.month:
        return 'THIS MONTH';
      case StatisticsPeriod.allTime:
        return 'ALL TIME';
    }
  }
}

/// Comprehensive, strictly deterministic statistics model (Sections 8-23)
@immutable
class DeadlineStatistics {
  final StatisticsPeriod period;
  final int totalCount;
  final int completedCount;
  final int pendingCount;
  final int missedCount;

  /// On-time rate: completed on/before deadline / total completed. Null if 0 completed. (Section 11)
  final double? onTimeRate;

  /// Completion rate: completed / (completed + missed). Null if 0 (Section 12)
  final double? completionRate;

  /// Phase 5 Subtask Metrics (Section 13)
  final int completedSubtasksCount;
  final int totalSubtasksCount;
  final double subtaskProgress;

  /// Time Pressure Metrics (Section 14 & 15)
  final int completedBeforeUrgentCount;
  final int lastMinuteCompletionsCount;
  final double? completedBeforeUrgentRate;

  /// Breakdowns (Section 18 & 19)
  final Map<DeadlineCategory, int> categoryCounts;
  final Map<DeadlinePriority, int> priorityCounts;

  /// Completion trend: Map of day index (0=Mon..6=Sun for week, or day of month) to count
  final Map<int, int> completionTrend;

  /// Real calculated streak stats (Section 20 & 21)
  final StreakStats streakStats;

  const DeadlineStatistics({
    required this.period,
    required this.totalCount,
    required this.completedCount,
    required this.pendingCount,
    required this.missedCount,
    required this.onTimeRate,
    required this.completionRate,
    required this.completedSubtasksCount,
    required this.totalSubtasksCount,
    required this.subtaskProgress,
    required this.completedBeforeUrgentCount,
    required this.lastMinuteCompletionsCount,
    required this.completedBeforeUrgentRate,
    required this.categoryCounts,
    required this.priorityCounts,
    required this.completionTrend,
    required this.streakStats,
  });

  bool get isEmpty => totalCount == 0 && completedCount == 0 && missedCount == 0;
  int get currentStreak => streakStats.currentStreak;
  int get longestStreak => streakStats.longestStreak;
}
