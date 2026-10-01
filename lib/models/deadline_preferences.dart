import 'package:flutter/foundation.dart';
import 'category.dart';
import 'priority.dart';
import 'reminder_type.dart';

/// User default deadline creation preferences (Phase 9 Section 10-12)
@immutable
class DeadlinePreferences {
  final DeadlinePriority defaultPriority;
  final DeadlineCategory defaultCategory;
  final List<ReminderType> defaultReminders;

  const DeadlinePreferences({
    this.defaultPriority = DeadlinePriority.medium,
    this.defaultCategory = DeadlineCategory.project,
    this.defaultReminders = const [
      ReminderType.oneDayBefore,
      ReminderType.oneHourBefore,
      ReminderType.atDeadline,
    ],
  });

  DeadlinePreferences copyWith({
    DeadlinePriority? defaultPriority,
    DeadlineCategory? defaultCategory,
    List<ReminderType>? defaultReminders,
  }) {
    return DeadlinePreferences(
      defaultPriority: defaultPriority ?? this.defaultPriority,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      defaultReminders: defaultReminders ?? this.defaultReminders,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultPriority': defaultPriority.name,
      'defaultCategory': defaultCategory.name,
      'defaultReminders': defaultReminders.map((r) => r.name).toList(),
    };
  }

  factory DeadlinePreferences.fromJson(Map<String, dynamic> json) {
    DeadlinePriority priority = DeadlinePriority.medium;
    if (json['defaultPriority'] != null) {
      try {
        priority = DeadlinePriority.values.byName(json['defaultPriority'] as String);
      } catch (_) {}
    }

    DeadlineCategory category = DeadlineCategory.project;
    if (json['defaultCategory'] != null) {
      try {
        category = DeadlineCategory.values.byName(json['defaultCategory'] as String);
      } catch (_) {}
    }

    List<ReminderType> reminders = const [
      ReminderType.oneDayBefore,
      ReminderType.oneHourBefore,
      ReminderType.atDeadline,
    ];
    if (json['defaultReminders'] is List) {
      final parsed = <ReminderType>[];
      for (final item in json['defaultReminders'] as List) {
        try {
          parsed.add(ReminderType.values.byName(item as String));
        } catch (_) {}
      }
      if (parsed.isNotEmpty) {
        reminders = parsed;
      }
    }

    return DeadlinePreferences(
      defaultPriority: priority,
      defaultCategory: category,
      defaultReminders: reminders,
    );
  }
}
