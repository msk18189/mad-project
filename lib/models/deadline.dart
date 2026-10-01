import '../core/utils/deadline_status_resolver.dart';
import 'deadline_category.dart';
import 'deadline_priority.dart';
import 'deadline_status.dart';
import 'reminder_type.dart';
import 'subtask.dart';

export 'deadline_category.dart';
export 'deadline_priority.dart';
export 'deadline_status.dart';
export 'reminder_type.dart';
export 'subtask.dart';

class Deadline {
  final String id;
  final String title;
  final DeadlineCategory category;
  final String? description;
  final DateTime deadlineDateTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DeadlinePriority priority;
  final List<Subtask> subtasks;
  final bool isCompleted;
  final DateTime? completedAt;

  // Additional optional metadata
  final List<ReminderType> reminders;
  final String? url;
  final String? notes;

  Deadline({
    required this.id,
    required this.title,
    required this.category,
    this.description,
    required this.deadlineDateTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.priority = DeadlinePriority.medium,
    this.subtasks = const [],
    this.isCompleted = false,
    this.completedAt,
    this.reminders = const [ReminderType.oneDayBefore],
    this.url,
    this.notes,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Compatibility alias for dueDateTime
  DateTime get dueDateTime => deadlineDateTime;

  /// Derived status using centralized status resolver
  DeadlineStatus get status => DeadlineStatusResolver.resolve(
        deadlineDateTime: deadlineDateTime,
        isCompleted: isCompleted,
      );

  /// Determine status at a specific point in time
  DeadlineStatus getStatus([DateTime? now]) {
    return DeadlineStatusResolver.resolve(
      deadlineDateTime: deadlineDateTime,
      isCompleted: isCompleted,
      currentTime: now,
    );
  }

  /// Whether the deadline has elapsed
  bool isPassed([DateTime? now]) {
    final current = now ?? DateTime.now();
    return current.isAfter(deadlineDateTime) || current.isAtSameMomentAs(deadlineDateTime);
  }

  /// Subtask completion ratio: 0.0 to 1.0 (clamped)
  double get subtaskProgress {
    if (subtasks.isEmpty) return 0.0;
    final completedCount = subtasks.where((s) => s.isCompleted).length;
    return (completedCount / subtasks.length).clamp(0.0, 1.0);
  }

  /// Total number of subtasks
  int get totalSubtasksCount => subtasks.length;

  /// Number of completed subtasks
  int get completedSubtasksCount => subtasks.where((s) => s.isCompleted).length;

  /// Subtask completion summary string: e.g. "2 / 6"
  String get subtaskSummary {
    if (subtasks.isEmpty) return '0 / 0';
    final completedCount = subtasks.where((s) => s.isCompleted).length;
    return '$completedCount / ${subtasks.length}';
  }

  /// Time progress ratio: (now - createdAt) / (deadlineDateTime - createdAt)
  /// Always clamped strictly between 0.0 and 1.0
  double timeProgress([DateTime? now]) {
    final current = now ?? DateTime.now();
    final totalDuration = deadlineDateTime.difference(createdAt).inMilliseconds;
    if (totalDuration <= 0) return 1.0;

    final elapsed = current.difference(createdAt).inMilliseconds;
    if (elapsed <= 0) return 0.0;
    if (elapsed >= totalDuration) return 1.0;

    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }

  /// Deterministic time pressure score (0 to 100)
  double calculateTimePressure([DateTime? now]) {
    if (isCompleted) return 0.0;
    final current = now ?? DateTime.now();
    if (isPassed(current)) return 100.0;

    final remainingHours = deadlineDateTime.difference(current).inMinutes / 60.0;

    // Proximity factor (0 to 60 points)
    double proximityPoints;
    if (remainingHours <= 3) {
      proximityPoints = 60;
    } else if (remainingHours <= 12) {
      proximityPoints = 50;
    } else if (remainingHours <= 24) {
      proximityPoints = 40;
    } else if (remainingHours <= 72) {
      proximityPoints = 25;
    } else if (remainingHours <= 168) {
      proximityPoints = 15;
    } else {
      proximityPoints = 5;
    }

    // Priority factor (0 to 25 points)
    final priorityPoints = priority.weight * 8.33;

    // Incomplete subtask factor (0 to 15 points)
    final incompleteFactor = subtasks.isNotEmpty ? (1.0 - subtaskProgress) * 15 : 7.5;

    final total = proximityPoints + priorityPoints + incompleteFactor;
    return total.clamp(0.0, 100.0);
  }

  /// Validation logic
  String? validate() {
    if (title.trim().isEmpty) {
      return 'Deadline title cannot be empty.';
    }
    return null;
  }

  Deadline copyWith({
    String? id,
    String? title,
    DeadlineCategory? category,
    String? description,
    DateTime? deadlineDateTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    DeadlinePriority? priority,
    List<Subtask>? subtasks,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    List<ReminderType>? reminders,
    String? url,
    String? notes,
  }) {
    return Deadline(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      deadlineDateTime: deadlineDateTime ?? this.deadlineDateTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priority: priority ?? this.priority,
      subtasks: subtasks ?? this.subtasks,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      reminders: reminders ?? this.reminders,
      url: url ?? this.url,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'description': description,
      'deadlineDateTime': deadlineDateTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'priority': priority.name,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'reminders': reminders.map((r) => r.name).toList(),
      'url': url,
      'notes': notes,
    };
  }

  factory Deadline.fromJson(Map<String, dynamic> json) {
    // Graceful backward compatibility for either 'deadlineDateTime' or 'dueDateTime'
    final rawDue = json['deadlineDateTime'] ?? json['dueDateTime'];
    final parsedDue = rawDue != null
        ? DateTime.tryParse(rawDue as String) ?? DateTime.now().add(const Duration(days: 1))
        : DateTime.now().add(const Duration(days: 1));

    return Deadline(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: DeadlineCategory.fromString(json['category'] as String?),
      description: json['description'] as String?,
      deadlineDateTime: parsedDue,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      priority: DeadlinePriority.fromString(json['priority'] as String?),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((s) => Subtask.fromJson(Map<String, dynamic>.from(s as Map)))
              .toList() ??
          const [],
      reminders: (json['reminders'] as List<dynamic>?)
              ?.map((r) => ReminderType.fromString(r.toString()))
              .toList() ??
          const [ReminderType.oneDayBefore],
      url: json['url'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
