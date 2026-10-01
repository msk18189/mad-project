import '../models/deadline.dart';

enum DeadlineStatusFilter {
  all,
  active,
  completed,
}

/// Immutable state container holding the complete deadline store and derived queries
class DeadlineState {
  final List<Deadline> deadlines;
  final bool isLoading;
  final String? errorMessage;
  final Deadline? selectedDeadline;

  const DeadlineState({
    this.deadlines = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedDeadline,
  });

  bool get isEmpty => !isLoading && deadlines.isEmpty;
  bool get hasError => errorMessage != null;
  bool get isLoaded => !isLoading && errorMessage == null;

  int get totalCount => deadlines.length;
  int get activeCount => deadlines.where((d) => !d.isCompleted).length;
  int get completedCount => deadlines.where((d) => d.isCompleted).length;

  /// Completed deadlines (Section 26: excluded from active countdown sections)
  List<Deadline> get completedDeadlines =>
      deadlines.where((d) => d.isCompleted).toList();

  /// Missed deadlines (passed and not completed, Section 25)
  List<Deadline> missedDeadlines([DateTime? now]) {
    final current = now ?? DateTime.now();
    final list = deadlines
        .where((d) => !d.isCompleted && d.isPassed(current))
        .toList();
    // Most recently missed first
    list.sort((a, b) => b.deadlineDateTime.compareTo(a.deadlineDateTime));
    return list;
  }

  /// Active future incomplete deadlines (Section 21)
  /// Sorted deterministically:
  /// 1. Earliest deadline time
  /// 2. Higher priority first if times are identical
  List<Deadline> activeDeadlines([DateTime? now]) {
    final current = now ?? DateTime.now();
    final list = deadlines
        .where((d) => !d.isCompleted && !d.isPassed(current))
        .toList();
    list.sort((a, b) {
      final timeCmp = a.deadlineDateTime.compareTo(b.deadlineDateTime);
      if (timeCmp != 0) return timeCmp;
      return b.priority.weight.compareTo(a.priority.weight);
    });
    return list;
  }

  /// The single hero deadline: nearest incomplete future deadline (Section 21 & 41)
  Deadline? nextDeadline([DateTime? now]) {
    final active = activeDeadlines(now);
    return active.isNotEmpty ? active.first : null;
  }

  /// Urgent deadlines requiring high attention (status == due or urgent), excluding the hero
  List<Deadline> urgentDeadlines([DateTime? now]) {
    final current = now ?? DateTime.now();
    final active = activeDeadlines(current);
    if (active.isEmpty) return [];

    final heroId = active.first.id;
    return active.where((d) {
      if (d.id == heroId) return false;
      final s = d.getStatus(current);
      return s == DeadlineStatus.due || s == DeadlineStatus.urgent;
    }).toList();
  }

  /// Upcoming deadlines with moderate urgency (status == approaching), excluding the hero
  List<Deadline> upcomingDeadlines([DateTime? now]) {
    final current = now ?? DateTime.now();
    final active = activeDeadlines(current);
    if (active.isEmpty) return [];

    final heroId = active.first.id;
    return active.where((d) {
      if (d.id == heroId) return false;
      final s = d.getStatus(current);
      return s == DeadlineStatus.approaching;
    }).toList();
  }

  /// Later deadlines with plenty of time remaining (status == upcoming), excluding the hero
  List<Deadline> laterDeadlines([DateTime? now]) {
    final current = now ?? DateTime.now();
    final active = activeDeadlines(current);
    if (active.isEmpty) return [];

    final heroId = active.first.id;
    return active.where((d) {
      if (d.id == heroId) return false;
      final s = d.getStatus(current);
      return s == DeadlineStatus.upcoming;
    }).toList();
  }

  DeadlineState copyWith({
    List<Deadline>? deadlines,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Deadline? selectedDeadline,
    bool clearSelected = false,
  }) {
    return DeadlineState(
      deadlines: deadlines ?? this.deadlines,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedDeadline: clearSelected ? null : (selectedDeadline ?? this.selectedDeadline),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeadlineState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage &&
          selectedDeadline == other.selectedDeadline &&
          _listEquals(deadlines, other.deadlines);

  @override
  int get hashCode =>
      deadlines.hashCode ^
      isLoading.hashCode ^
      errorMessage.hashCode ^
      selectedDeadline.hashCode;

  static bool _listEquals(List<Deadline> a, List<Deadline> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].updatedAt != b[i].updatedAt ||
          a[i].isCompleted != b[i].isCompleted) {
        return false;
      }
    }
    return true;
  }
}
