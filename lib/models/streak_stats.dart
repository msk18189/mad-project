class StreakStats {
  final int currentStreak;
  final int longestStreak;
  final int totalCompleted;
  final int completedEarly;
  final DateTime? lastCompletedDate;

  const StreakStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCompleted = 0,
    this.completedEarly = 0,
    this.lastCompletedDate,
  });

  StreakStats copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalCompleted,
    int? completedEarly,
    DateTime? lastCompletedDate,
  }) {
    return StreakStats(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalCompleted: totalCompleted ?? this.totalCompleted,
      completedEarly: completedEarly ?? this.completedEarly,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalCompleted': totalCompleted,
      'completedEarly': completedEarly,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
    };
  }

  factory StreakStats.fromJson(Map<String, dynamic> json) {
    return StreakStats(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalCompleted: json['totalCompleted'] as int? ?? 0,
      completedEarly: json['completedEarly'] as int? ?? 0,
      lastCompletedDate: json['lastCompletedDate'] != null
          ? DateTime.tryParse(json['lastCompletedDate'] as String)
          : null,
    );
  }
}
