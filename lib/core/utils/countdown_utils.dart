import 'package:intl/intl.dart';
import '../../models/countdown_state.dart';
import '../../models/deadline_status.dart';
import 'time_progress.dart';

/// Centralized utility for countdown calculations, formatting, urgency copy,
/// and relative date presentation.
class CountdownUtils {
  CountdownUtils._();

  /// Calculate live [CountdownState] from target date and reference time
  static CountdownState calculate(DateTime deadlineDateTime, {DateTime? now}) {
    return CountdownState.fromDateTime(deadlineDateTime, now: now);
  }

  /// Calculates remaining non-negative Duration
  static Duration calculateRemainingTime(DateTime target, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final diff = target.difference(current);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Centralized formatter for target countdown string
  static String formatCountdown(DateTime target, {DateTime? now}) {
    return calculate(target, now: now).formatted;
  }

  /// Whether target deadline has expired
  static bool isExpired(DateTime target, {DateTime? now}) {
    final current = now ?? DateTime.now();
    return target.isBefore(current);
  }

  /// Returns breakdown map: days, hours, minutes, seconds
  static Map<String, int> getCountdownParts(DateTime target, {DateTime? now}) {
    return calculate(target, now: now).parts;
  }

  /// Calculates elapsed time progress percentage clamped [0.0, 1.0]
  static double getProgress({
    required DateTime createdAt,
    required DateTime deadlineDateTime,
    DateTime? now,
  }) {
    return TimeProgress.calculate(
      createdAt: createdAt,
      deadlineDateTime: deadlineDateTime,
      now: now,
    );
  }

  /// Format deadline date with current-day awareness:
  /// - TODAY · 8:30 PM
  /// - TOMORROW · 10:00 AM
  /// - FRI · 4 OCT · 6:00 PM
  static String formatRelativeDate(DateTime date, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final timeStr = DateFormat('h:mm a').format(date);

    final isToday = date.year == current.year &&
        date.month == current.month &&
        date.day == current.day;

    final tomorrow = current.add(const Duration(days: 1));
    final isTomorrow = date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;

    final yesterday = current.subtract(const Duration(days: 1));
    final isYesterday = date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;

    if (isToday) {
      return 'TODAY · $timeStr';
    } else if (isTomorrow) {
      return 'TOMORROW · $timeStr';
    } else if (isYesterday) {
      return 'YESTERDAY · $timeStr';
    } else if (date.year == current.year) {
      final dateStr = DateFormat('EEE · d MMM').format(date).toUpperCase();
      return '$dateStr · $timeStr';
    } else {
      final dateStr = DateFormat('d MMM yyyy').format(date).toUpperCase();
      return '$dateStr · $timeStr';
    }
  }

  /// Context-aware urgency copy (Section 60)
  static String getUrgencyCopy(DeadlineStatus status) {
    switch (status) {
      case DeadlineStatus.upcoming:
        return "Plenty of time. Don't get comfortable.";
      case DeadlineStatus.approaching:
        return 'You might want to start now.';
      case DeadlineStatus.urgent:
        return 'Okay. NOW would be a good time.';
      case DeadlineStatus.due:
        return 'This is the moment.';
      case DeadlineStatus.completed:
        return 'One less thing haunting you.';
      case DeadlineStatus.missed:
        return 'The clock won. On to the next one.';
    }
  }

  /// Dynamic greeting based on current local hour (Section 18)
  static String getGreeting({DateTime? now, String? userName}) {
    final hour = (now ?? DateTime.now()).hour;
    final String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'GOOD MORNING';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'GOOD AFTERNOON';
    } else {
      greeting = 'GOOD EVENING';
    }

    if (userName != null && userName.trim().isNotEmpty) {
      return '$greeting, ${userName.trim().toUpperCase()}';
    }
    return greeting;
  }
}
