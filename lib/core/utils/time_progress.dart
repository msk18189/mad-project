/// Centralized utility for computing time-based deadline progress.
/// Distinct from task/subtask progress (Section 16).
class TimeProgress {
  TimeProgress._();

  /// Calculates elapsed time progress percentage clamped strictly between 0.0 and 1.0
  ///
  /// Edge cases handled (Section 15):
  /// - now < createdAt => 0.0
  /// - now >= deadlineDateTime => 1.0
  /// - deadlineDateTime <= createdAt (zero duration) => safely handled without division by zero
  static double calculate({
    required DateTime createdAt,
    required DateTime deadlineDateTime,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();

    // Not started yet
    if (current.isBefore(createdAt)) {
      return 0.0;
    }

    // Already at or past deadline
    if (current.isAfter(deadlineDateTime) || current.isAtSameMomentAs(deadlineDateTime)) {
      return 1.0;
    }

    final totalMilliseconds = deadlineDateTime.difference(createdAt).inMilliseconds;

    // Guard against zero-duration or negative created-after-deadline anomaly
    if (totalMilliseconds <= 0) {
      return 1.0;
    }

    final elapsedMilliseconds = current.difference(createdAt).inMilliseconds;
    final progress = elapsedMilliseconds / totalMilliseconds;

    return progress.clamp(0.0, 1.0);
  }

  /// Formats time progress as a clean percentage string (e.g. "78%")
  static String formatPercent(double progress) {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    return '$percent%';
  }
}
