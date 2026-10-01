import 'package:uuid/uuid.dart';
import 'reminder_type.dart';

/// Model representing a scheduled or configured reminder for a deadline.
class DeadlineReminder {
  final String id;
  final String deadlineId;
  final ReminderType type;
  final DateTime scheduledTime;
  final bool isEnabled;
  final int notificationId;
  final DateTime createdAt;

  const DeadlineReminder({
    required this.id,
    required this.deadlineId,
    required this.type,
    required this.scheduledTime,
    this.isEnabled = true,
    required this.notificationId,
    required this.createdAt,
  });

  /// Deterministic notification ID generator (Section 31)
  /// Guarantees the same reminder is identifiable and reproducible later for cancellation
  static int generateNotificationId(String deadlineId, ReminderType type) {
    final combined = '${deadlineId}_${type.name}';
    return (combined.hashCode.abs() % 2147483647);
  }

  /// Creates a single DeadlineReminder
  factory DeadlineReminder.create({
    required String deadlineId,
    required ReminderType type,
    required DateTime deadlineDateTime,
    bool isEnabled = true,
    DateTime? now,
  }) {
    final scheduled = type.calculateScheduledTime(deadlineDateTime);
    return DeadlineReminder(
      id: const Uuid().v4(),
      deadlineId: deadlineId,
      type: type,
      scheduledTime: scheduled,
      isEnabled: isEnabled,
      notificationId: generateNotificationId(deadlineId, type),
      createdAt: now ?? DateTime.now(),
    );
  }

  /// Factory creating default reminder configurations for a deadline (Section 8 & 9)
  /// Skips reminder times that are already in the past
  static List<DeadlineReminder> createValidReminders({
    required String deadlineId,
    required DateTime deadlineDateTime,
    DateTime? now,
    Set<ReminderType>? activeTypes,
  }) {
    final current = now ?? DateTime.now();
    final typesToConsider = activeTypes ?? ReminderType.values.toSet();

    final reminders = <DeadlineReminder>[];
    for (final type in ReminderType.values) {
      final scheduled = type.calculateScheduledTime(deadlineDateTime);
      // Smart scheduling: only schedule if in the future or valid now (Section 9 & 37)
      final isFuture = scheduled.isAfter(current);
      final isSelected = typesToConsider.contains(type);

      if (isSelected && isFuture) {
        reminders.add(DeadlineReminder(
          id: const Uuid().v4(),
          deadlineId: deadlineId,
          type: type,
          scheduledTime: scheduled,
          isEnabled: true,
          notificationId: generateNotificationId(deadlineId, type),
          createdAt: current,
        ));
      }
    }
    return reminders;
  }

  DeadlineReminder copyWith({
    String? id,
    String? deadlineId,
    ReminderType? type,
    DateTime? scheduledTime,
    bool? isEnabled,
    int? notificationId,
    DateTime? createdAt,
  }) {
    return DeadlineReminder(
      id: id ?? this.id,
      deadlineId: deadlineId ?? this.deadlineId,
      type: type ?? this.type,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isEnabled: isEnabled ?? this.isEnabled,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deadlineId': deadlineId,
      'type': type.name,
      'scheduledTime': scheduledTime.toIso8601String(),
      'isEnabled': isEnabled,
      'notificationId': notificationId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DeadlineReminder.fromJson(Map<String, dynamic> json) {
    return DeadlineReminder(
      id: json['id'] as String,
      deadlineId: json['deadlineId'] as String,
      type: ReminderType.fromString(json['type'] as String?),
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      isEnabled: json['isEnabled'] as bool? ?? true,
      notificationId: json['notificationId'] as int? ??
          generateNotificationId(
            json['deadlineId'] as String,
            ReminderType.fromString(json['type'] as String?),
          ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeadlineReminder &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          deadlineId == other.deadlineId &&
          type == other.type &&
          isEnabled == other.isEnabled &&
          notificationId == other.notificationId;

  @override
  int get hashCode =>
      id.hashCode ^
      deadlineId.hashCode ^
      type.hashCode ^
      isEnabled.hashCode ^
      notificationId.hashCode;
}
