class Subtask {
  final String id;
  final String? deadlineId;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int sortOrder;

  Subtask({
    required this.id,
    this.deadlineId,
    required this.title,
    this.description,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
    this.sortOrder = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Subtask copyWith({
    String? id,
    String? deadlineId,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? sortOrder,
  }) {
    return Subtask(
      id: id ?? this.id,
      deadlineId: deadlineId ?? this.deadlineId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt || (isCompleted == false && completedAt == null)
          ? null
          : (completedAt ?? this.completedAt),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deadlineId': deadlineId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'sortOrder': sortOrder,
    };
  }

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'] as String? ?? '',
      deadlineId: json['deadlineId'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subtask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          deadlineId == other.deadlineId &&
          title == other.title &&
          description == other.description &&
          isCompleted == other.isCompleted &&
          createdAt == other.createdAt &&
          completedAt == other.completedAt &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      id.hashCode ^
      deadlineId.hashCode ^
      title.hashCode ^
      description.hashCode ^
      isCompleted.hashCode ^
      createdAt.hashCode ^
      completedAt.hashCode ^
      sortOrder.hashCode;
}
