/// The controlled reminder types supported by DEADLINE (Section 7 & 82)
enum ReminderType {
  sevenDaysBefore,
  threeDaysBefore,
  oneDayBefore,
  oneHourBefore,
  atDeadline;

  Duration get leadDuration {
    switch (this) {
      case ReminderType.sevenDaysBefore:
        return const Duration(days: 7);
      case ReminderType.threeDaysBefore:
        return const Duration(days: 3);
      case ReminderType.oneDayBefore:
        return const Duration(days: 1);
      case ReminderType.oneHourBefore:
        return const Duration(hours: 1);
      case ReminderType.atDeadline:
        return Duration.zero;
    }
  }

  String get label {
    switch (this) {
      case ReminderType.sevenDaysBefore:
        return '7 days before';
      case ReminderType.threeDaysBefore:
        return '3 days before';
      case ReminderType.oneDayBefore:
        return '1 day before';
      case ReminderType.oneHourBefore:
        return '1 hour before';
      case ReminderType.atDeadline:
        return 'At deadline';
    }
  }

  String get description {
    switch (this) {
      case ReminderType.sevenDaysBefore:
        return 'Start thinking about it.';
      case ReminderType.threeDaysBefore:
        return 'Time to make progress.';
      case ReminderType.oneDayBefore:
        return 'Tomorrow is the deadline.';
      case ReminderType.oneHourBefore:
        return 'Final warning.';
      case ReminderType.atDeadline:
        return "Time's up.";
    }
  }

  String get iconEmoji {
    switch (this) {
      case ReminderType.sevenDaysBefore:
        return '🗓️';
      case ReminderType.threeDaysBefore:
        return '⚡';
      case ReminderType.oneDayBefore:
        return '⏰';
      case ReminderType.oneHourBefore:
        return '⏳';
      case ReminderType.atDeadline:
        return '🔔';
    }
  }

  /// Calculates the target scheduled time for a given deadline moment
  DateTime calculateScheduledTime(DateTime deadlineDateTime) {
    return deadlineDateTime.subtract(leadDuration);
  }

  /// Checks if this reminder would occur in the future or current moment relative to [now]
  bool isSchedulable(DateTime deadlineDateTime, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final targetTime = calculateScheduledTime(deadlineDateTime);
    return targetTime.isAfter(current) || targetTime.isAtSameMomentAs(current);
  }

  static ReminderType fromString(String? val) {
    if (val == null) return ReminderType.atDeadline;
    return ReminderType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ReminderType.atDeadline,
    );
  }
}
