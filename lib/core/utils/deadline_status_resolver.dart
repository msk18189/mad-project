import '../../models/deadline_status.dart';

class DeadlineStatusResolver {
  DeadlineStatusResolver._();

  /// Centralized deterministic thresholds
  static const Duration dueThreshold = Duration(hours: 2);
  static const Duration urgentThreshold = Duration(hours: 24);
  static const Duration approachingThreshold = Duration(days: 3);

  /// Determine the status of a deadline strictly derived from time, target moment, and completion
  static DeadlineStatus resolve({
    required DateTime deadlineDateTime,
    required bool isCompleted,
    DateTime? currentTime,
    DateTime? now,
  }) {
    if (isCompleted) {
      return DeadlineStatus.completed;
    }

    final effectiveNow = now ?? currentTime ?? DateTime.now();

    // Check if the deadline has passed
    if (effectiveNow.isAfter(deadlineDateTime) || effectiveNow.isAtSameMomentAs(deadlineDateTime)) {
      return DeadlineStatus.missed;
    }

    final remaining = deadlineDateTime.difference(effectiveNow);

    if (remaining <= dueThreshold) {
      return DeadlineStatus.due;
    } else if (remaining <= urgentThreshold) {
      return DeadlineStatus.urgent;
    } else if (remaining <= approachingThreshold) {
      return DeadlineStatus.approaching;
    } else {
      return DeadlineStatus.upcoming;
    }
  }
}
