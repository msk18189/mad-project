import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deadline/models/deadline.dart';
import 'package:deadline/providers/deadline_provider.dart';
import 'package:deadline/providers/filter_provider.dart';

void main() {
  group('Phase 6 - Search Behavior Tests (Section 27, 28, 54)', () {
    late ProviderContainer container;
    late List<Deadline> testDeadlines;

    setUp(() {
      final now = DateTime.now();
      testDeadlines = [
        Deadline(
          id: 'dl_ai',
          title: 'AI Project Submission',
          description: 'Train convolutional neural networks',
          category: DeadlineCategory.project,
          priority: DeadlinePriority.high,
          deadlineDateTime: now.add(const Duration(hours: 12)),
          subtasks: [
            Subtask(id: 's1', deadlineId: 'dl_ai', title: 'Data Preprocessing', createdAt: now),
            Subtask(id: 's2', deadlineId: 'dl_ai', title: 'Model Evaluation', createdAt: now),
          ],
        ),
        Deadline(
          id: 'dl_db',
          title: 'Database Assignment',
          description: 'SQL indexing and query optimization',
          category: DeadlineCategory.assignment,
          priority: DeadlinePriority.medium,
          deadlineDateTime: now.add(const Duration(days: 3)),
        ),
        Deadline(
          id: 'dl_hack',
          title: 'Web3 Hackathon',
          description: 'Solidity smart contracts',
          category: DeadlineCategory.hackathon,
          priority: DeadlinePriority.low,
          deadlineDateTime: now.add(const Duration(days: 7)),
        ),
      ];

      container = ProviderContainer(
        overrides: [
          deadlineListProvider.overrideWithValue(testDeadlines),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Empty search query returns all deadlines', () {
      container.read(filterProvider.notifier).setSearchQuery('');
      final results = container.read(filteredDeadlinesProvider);
      expect(results.length, 3);
    });

    test('Case-insensitive and trimmed search: "AI", "ai", " AI "', () {
      final notifier = container.read(filterProvider.notifier);

      notifier.setSearchQuery('AI');
      expect(container.read(filteredDeadlinesProvider).map((d) => d.id), contains('dl_ai'));

      notifier.setSearchQuery('ai');
      expect(container.read(filteredDeadlinesProvider).map((d) => d.id), contains('dl_ai'));

      notifier.setSearchQuery('  AI   ');
      expect(container.read(filteredDeadlinesProvider).map((d) => d.id), contains('dl_ai'));
    });

    test('Search finds deadline by title', () {
      container.read(filterProvider.notifier).setSearchQuery('Database');
      final results = container.read(filteredDeadlinesProvider);
      expect(results.length, 1);
      expect(results.first.id, 'dl_db');
    });

    test('Search finds deadline by description', () {
      container.read(filterProvider.notifier).setSearchQuery('neural networks');
      final results = container.read(filteredDeadlinesProvider);
      expect(results.length, 1);
      expect(results.first.id, 'dl_ai');
    });

    test('Search finds deadline by category label', () {
      container.read(filterProvider.notifier).setSearchQuery('Hackathon');
      final results = container.read(filteredDeadlinesProvider);
      expect(results.length, 1);
      expect(results.first.id, 'dl_hack');
    });

    test('Search finds deadline by subtask title', () {
      container.read(filterProvider.notifier).setSearchQuery('Preprocessing');
      final results = container.read(filteredDeadlinesProvider);
      expect(results.length, 1);
      expect(results.first.id, 'dl_ai');
    });

    test('Search returns empty list when query matches nothing', () {
      container.read(filterProvider.notifier).setSearchQuery('Quantum Computing');
      final results = container.read(filteredDeadlinesProvider);
      expect(results.isEmpty, isTrue);
    });
  });

  group('Phase 6 - Filter System Tests (Section 30, 55)', () {
    late ProviderContainer container;
    late List<Deadline> testDeadlines;

    setUp(() {
      final now = DateTime.now();
      testDeadlines = [
        // Urgent, High, Project (between 2h and 24h)
        Deadline(
          id: 'dl_urgent_high',
          title: 'Urgent High Project',
          category: DeadlineCategory.project,
          priority: DeadlinePriority.high,
          deadlineDateTime: now.add(const Duration(hours: 6)), // urgent
        ),
        // Approaching, Medium, Assignment
        Deadline(
          id: 'dl_app_med',
          title: 'Approaching Med Assignment',
          category: DeadlineCategory.assignment,
          priority: DeadlinePriority.medium,
          deadlineDateTime: now.add(const Duration(hours: 36)), // approaching
        ),
        // Upcoming, Low, Exam
        Deadline(
          id: 'dl_up_low',
          title: 'Upcoming Low Exam',
          category: DeadlineCategory.exam,
          priority: DeadlinePriority.low,
          deadlineDateTime: now.add(const Duration(days: 10)), // upcoming
        ),
        // Completed
        Deadline(
          id: 'dl_completed',
          title: 'Finished Project',
          category: DeadlineCategory.project,
          priority: DeadlinePriority.high,
          deadlineDateTime: now.subtract(const Duration(days: 1)),
          isCompleted: true,
          completedAt: now.subtract(const Duration(days: 1)),
        ),
        // Missed (past, incomplete)
        Deadline(
          id: 'dl_missed',
          title: 'Missed Assignment',
          category: DeadlineCategory.assignment,
          priority: DeadlinePriority.medium,
          deadlineDateTime: now.subtract(const Duration(days: 2)),
          isCompleted: false,
        ),
      ];

      container = ProviderContainer(
        overrides: [
          deadlineListProvider.overrideWithValue(testDeadlines),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Priority filter: High only', () {
      container.read(filterProvider.notifier).setPriorityFilter(PriorityFilter.high);
      final results = container.read(filteredDeadlinesProvider);
      for (final d in results) {
        expect(d.priority, DeadlinePriority.high);
      }
      expect(results.map((d) => d.id), containsAll(['dl_urgent_high', 'dl_completed']));
    });

    test('Category filter: Project only', () {
      container.read(filterProvider.notifier).setCategoryFilter(DeadlineCategory.project);
      final results = container.read(filteredDeadlinesProvider);
      for (final d in results) {
        expect(d.category, DeadlineCategory.project);
      }
      expect(results.map((d) => d.id), containsAll(['dl_urgent_high', 'dl_completed']));
    });

    test('Status filter: Completed only', () {
      container.read(filterProvider.notifier).setStatusFilter(StatusFilter.completed);
      final results = container.read(filteredDeadlinesProvider);
      expect(results.length, 1);
      expect(results.first.id, 'dl_completed');
    });

    test('Status filter: Missed only', () {
      container.read(filterProvider.notifier).setStatusFilter(StatusFilter.missed);
      final results = container.read(filteredDeadlinesProvider);
      expect(results.length, 1);
      expect(results.first.id, 'dl_missed');
    });

    test('Combined filter: Status=Urgent, Priority=High, Category=Project', () {
      final notifier = container.read(filterProvider.notifier);
      notifier.setStatusFilter(StatusFilter.urgent);
      notifier.setPriorityFilter(PriorityFilter.high);
      notifier.setCategoryFilter(DeadlineCategory.project);

      final results = container.read(filteredDeadlinesProvider);
      expect(results.length, 1);
      expect(results.first.id, 'dl_urgent_high');
    });

    test('Reset filter clears all filters to default', () {
      final notifier = container.read(filterProvider.notifier);
      notifier.setStatusFilter(StatusFilter.urgent);
      notifier.setPriorityFilter(PriorityFilter.high);
      notifier.setCategoryFilter(DeadlineCategory.project);
      notifier.setSearchQuery('urgent');

      expect(container.read(filterProvider).activeFilterCount, greaterThan(0));

      notifier.reset();
      final state = container.read(filterProvider);
      expect(state.statusFilter, StatusFilter.all);
      expect(state.priorityFilter, PriorityFilter.all);
      expect(state.categoryFilter, isNull);
      expect(state.searchQuery, '');
      expect(state.activeFilterCount, 0);
    });
  });

  group('Phase 6 - Sorting Options Tests (Section 31, 56)', () {
    late ProviderContainer container;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      final deadlines = [
        Deadline(
          id: 'dl_b',
          title: 'Beta Project',
          category: DeadlineCategory.project,
          priority: DeadlinePriority.low,
          createdAt: now.subtract(const Duration(days: 3)),
          deadlineDateTime: now.add(const Duration(days: 5)),
        ),
        Deadline(
          id: 'dl_a',
          title: 'Alpha Exam',
          category: DeadlineCategory.exam,
          priority: DeadlinePriority.high,
          createdAt: now.subtract(const Duration(days: 1)),
          deadlineDateTime: now.add(const Duration(days: 1)),
        ),
        Deadline(
          id: 'dl_c',
          title: 'Charlie Assignment',
          category: DeadlineCategory.assignment,
          priority: DeadlinePriority.medium,
          createdAt: now.subtract(const Duration(days: 5)),
          deadlineDateTime: now.add(const Duration(days: 10)),
        ),
      ];

      container = ProviderContainer(
        overrides: [
          deadlineListProvider.overrideWithValue(deadlines),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Sort by soonest due date', () {
      container.read(filterProvider.notifier).setSortOption(DeadlineSortOption.soonest);
      final results = container.read(filteredDeadlinesProvider);
      expect(results.map((d) => d.id).toList(), ['dl_a', 'dl_b', 'dl_c']);
    });

    test('Sort by latest due date', () {
      container.read(filterProvider.notifier).setSortOption(DeadlineSortOption.latest);
      final results = container.read(filteredDeadlinesProvider);
      expect(results.map((d) => d.id).toList(), ['dl_c', 'dl_b', 'dl_a']);
    });

    test('Sort by recently created', () {
      container.read(filterProvider.notifier).setSortOption(DeadlineSortOption.recentlyCreated);
      final results = container.read(filteredDeadlinesProvider);
      expect(results.map((d) => d.id).toList(), ['dl_a', 'dl_b', 'dl_c']);
    });

    test('Sort by priority (Highest first)', () {
      container.read(filterProvider.notifier).setSortOption(DeadlineSortOption.priority);
      final results = container.read(filteredDeadlinesProvider);
      expect(results.map((d) => d.id).toList(), ['dl_a', 'dl_c', 'dl_b']);
    });

    test('Sort alphabetically (A-Z)', () {
      container.read(filterProvider.notifier).setSortOption(DeadlineSortOption.alphabetical);
      final results = container.read(filteredDeadlinesProvider);
      expect(results.map((d) => d.id).toList(), ['dl_a', 'dl_b', 'dl_c']);
    });
  });

  group('Phase 6 - Calendar Date Grouping Tests (Section 21, 25, 57)', () {
    test('Deadlines match selected date in local timezone', () {
      final now = DateTime.now();
      final targetDate = DateTime(now.year, now.month, now.day + 2, 14, 30);
      final dl1 = Deadline(
        id: 'cal_1',
        title: 'Calendar Task 1',
        category: DeadlineCategory.project,
        deadlineDateTime: targetDate,
      );
      final dl2 = Deadline(
        id: 'cal_2',
        title: 'Calendar Task 2',
        category: DeadlineCategory.exam,
        deadlineDateTime: DateTime(now.year, now.month, now.day + 2, 18, 0),
      );
      final dlOther = Deadline(
        id: 'cal_3',
        title: 'Other Day Task',
        category: DeadlineCategory.event,
        deadlineDateTime: DateTime(now.year, now.month, now.day + 5),
      );

      final all = [dl1, dl2, dlOther];
      final selectedDayDeadlines = all.where((d) {
        final local = d.dueDateTime.toLocal();
        return local.year == targetDate.year &&
            local.month == targetDate.month &&
            local.day == targetDate.day;
      }).toList();

      expect(selectedDayDeadlines.length, 2);
      expect(selectedDayDeadlines.map((d) => d.id), containsAll(['cal_1', 'cal_2']));
    });
  });
}
