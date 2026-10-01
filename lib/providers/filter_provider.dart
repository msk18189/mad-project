import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deadline.dart';
import 'deadline_provider.dart';

/// Phase 6 Status Filter (Section 30)
enum StatusFilter {
  all,
  upcoming,
  approaching,
  urgent,
  due,
  completed,
  missed;

  String get label {
    switch (this) {
      case StatusFilter.all:
        return 'ALL';
      case StatusFilter.upcoming:
        return 'UPCOMING';
      case StatusFilter.approaching:
        return 'APPROACHING';
      case StatusFilter.urgent:
        return 'URGENT';
      case StatusFilter.due:
        return 'DUE NOW';
      case StatusFilter.completed:
        return 'COMPLETED';
      case StatusFilter.missed:
        return 'MISSED';
    }
  }
}

/// Phase 6 Priority Filter (Section 30)
enum PriorityFilter {
  all,
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case PriorityFilter.all:
        return 'ALL';
      case PriorityFilter.low:
        return 'LOW';
      case PriorityFilter.medium:
        return 'MEDIUM';
      case PriorityFilter.high:
        return 'HIGH';
    }
  }
}

/// Phase 6 Sorting Options (Section 31)
enum DeadlineSortOption {
  soonest,
  latest,
  recentlyCreated,
  priority,
  alphabetical;

  String get label {
    switch (this) {
      case DeadlineSortOption.soonest:
        return 'Deadline soonest';
      case DeadlineSortOption.latest:
        return 'Deadline latest';
      case DeadlineSortOption.recentlyCreated:
        return 'Recently created';
      case DeadlineSortOption.priority:
        return 'Priority (Highest)';
      case DeadlineSortOption.alphabetical:
        return 'Alphabetical (A-Z)';
    }
  }
}

// Compatibility aliases for previous references
typedef DeadlineTimeFilter = StatusFilter;
typedef DeadlineSortOrder = DeadlineSortOption;

class FilterState {
  final StatusFilter statusFilter;
  final PriorityFilter priorityFilter;
  final DeadlineCategory? categoryFilter;
  final String searchQuery;
  final DeadlineSortOption sortOption;

  const FilterState({
    this.statusFilter = StatusFilter.all,
    this.priorityFilter = PriorityFilter.all,
    this.categoryFilter,
    this.searchQuery = '',
    this.sortOption = DeadlineSortOption.soonest,
  });

  // Compatibility getter
  StatusFilter get timeFilter => statusFilter;
  DeadlineSortOption get sortOrder => sortOption;

  /// Section 33: Active filter indicator
  int get activeFilterCount {
    int count = 0;
    if (statusFilter != StatusFilter.all) count++;
    if (priorityFilter != PriorityFilter.all) count++;
    if (categoryFilter != null) count++;
    if (sortOption != DeadlineSortOption.soonest) count++;
    return count;
  }

  FilterState copyWith({
    StatusFilter? statusFilter,
    StatusFilter? timeFilter,
    PriorityFilter? priorityFilter,
    DeadlineCategory? categoryFilter,
    bool clearCategory = false,
    String? searchQuery,
    DeadlineSortOption? sortOption,
    DeadlineSortOption? sortOrder,
  }) {
    return FilterState(
      statusFilter: statusFilter ?? timeFilter ?? this.statusFilter,
      priorityFilter: priorityFilter ?? this.priorityFilter,
      categoryFilter: clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      sortOption: sortOption ?? sortOrder ?? this.sortOption,
    );
  }
}

class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() {
    return const FilterState();
  }

  void setStatusFilter(StatusFilter filter) {
    state = state.copyWith(statusFilter: filter);
  }

  void setTimeFilter(StatusFilter filter) => setStatusFilter(filter);

  void setPriorityFilter(PriorityFilter filter) {
    state = state.copyWith(priorityFilter: filter);
  }

  void setCategoryFilter(DeadlineCategory? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(categoryFilter: category);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSortOption(DeadlineSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  void setSortOrder(DeadlineSortOption option) => setSortOption(option);

  void reset() {
    state = const FilterState();
  }
}

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(() {
  return FilterNotifier();
});

/// Filtered and sorted deadline stream/list derived reactively (Section 30, 31, 39)
final filteredDeadlinesProvider = Provider<List<Deadline>>((ref) {
  final deadlines = ref.watch(deadlineListProvider);
  final filter = ref.watch(filterProvider);
  final now = DateTime.now();

  var result = deadlines.where((d) {
    // 1. Search Query (Section 27 & 28): Title, Description, Category, Subtask titles
    final query = filter.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      final matchTitle = d.title.toLowerCase().contains(query);
      final matchDesc = d.description != null && d.description!.toLowerCase().contains(query);
      final matchCat = d.category.label.toLowerCase().contains(query);
      final matchSubtask = d.subtasks.any((s) => s.title.toLowerCase().contains(query));
      if (!matchTitle && !matchDesc && !matchCat && !matchSubtask) {
        return false;
      }
    }

    // 2. Status Filter (Section 30)
    final dStatus = d.getStatus(now);
    switch (filter.statusFilter) {
      case StatusFilter.all:
        break;
      case StatusFilter.upcoming:
        if (d.isCompleted || dStatus != DeadlineStatus.upcoming) return false;
        break;
      case StatusFilter.approaching:
        if (d.isCompleted || dStatus != DeadlineStatus.approaching) return false;
        break;
      case StatusFilter.urgent:
        if (d.isCompleted || dStatus != DeadlineStatus.urgent) return false;
        break;
      case StatusFilter.due:
        if (d.isCompleted || dStatus != DeadlineStatus.due) return false;
        break;
      case StatusFilter.completed:
        if (!d.isCompleted) return false;
        break;
      case StatusFilter.missed:
        if (d.isCompleted || !d.isPassed(now)) return false;
        break;
    }

    // 3. Priority Filter (Section 30)
    switch (filter.priorityFilter) {
      case PriorityFilter.all:
        break;
      case PriorityFilter.low:
        if (d.priority != DeadlinePriority.low) return false;
        break;
      case PriorityFilter.medium:
        if (d.priority != DeadlinePriority.medium) return false;
        break;
      case PriorityFilter.high:
        if (d.priority != DeadlinePriority.high) return false;
        break;
    }

    // 4. Category Filter (Section 30)
    if (filter.categoryFilter != null && d.category != filter.categoryFilter) {
      return false;
    }

    return true;
  }).toList();

  // 5. Sorting (Section 31)
  result.sort((a, b) {
    switch (filter.sortOption) {
      case DeadlineSortOption.soonest:
        // Active deadlines first, ordered by earliest due date
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return a.dueDateTime.compareTo(b.dueDateTime);
      case DeadlineSortOption.latest:
        // Active deadlines first, ordered by latest due date
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.dueDateTime.compareTo(a.dueDateTime);
      case DeadlineSortOption.recentlyCreated:
        return b.createdAt.compareTo(a.createdAt);
      case DeadlineSortOption.priority:
        final cmp = b.priority.weight.compareTo(a.priority.weight);
        if (cmp != 0) return cmp;
        return a.dueDateTime.compareTo(b.dueDateTime);
      case DeadlineSortOption.alphabetical:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    }
  });

  return result;
});
