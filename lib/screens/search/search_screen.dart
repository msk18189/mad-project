import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../models/category.dart';
import '../../providers/deadline_provider.dart';
import '../../providers/filter_provider.dart';
import '../../widgets/deadline_filter_sheet.dart';
import '../../widgets/deadline_ticket_card.dart';
import '../../widgets/empty_state_view.dart';
import '../deadline/deadline_detail_screen.dart';

/// Phase 6 Global Deadline Search & Filter Screen (Sections 27-33)
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filterState = ref.watch(filterProvider);
    final filterNotifier = ref.read(filterProvider.notifier);
    final filteredDeadlines = ref.watch(filteredDeadlinesProvider);
    final activeCount = filterState.activeFilterCount;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkPaper : AppColors.paper,
      appBar: AppBar(
        title: Text(
          'SEARCH DEADLINES',
          style: AppTypography.titleMedium.copyWith(letterSpacing: 1.2),
        ),
        actions: [
          // Filter Sheet Launcher with Active Count Badge (Section 33)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => DeadlineFilterSheet.show(context),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: activeCount > 0 ? AppColors.burntOrange : (isDark ? AppColors.darkCard : AppColors.softWhite),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.ink,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: activeCount > 0 ? Colors.white : (isDark ? AppColors.darkInk : AppColors.ink),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activeCount > 0 ? 'FILTER • $activeCount' : 'FILTERS',
                      style: AppTypography.badge.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: activeCount > 0 ? Colors.white : (isDark ? AppColors.darkInk : AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (activeCount > 0 || filterState.searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Reset All',
              onPressed: () => filterNotifier.reset(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Input Field (Section 27 & 28)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.softWhite,
                borderRadius: AppRadius.radiusSm,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.ink,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black54 : AppColors.ink,
                    offset: const Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => filterNotifier.setSearchQuery(val),
                controller: TextEditingController(text: filterState.searchQuery)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: filterState.searchQuery.length),
                  ),
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkInk : AppColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'Search title, description, category, subtasks...',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppColors.burntOrange, size: 20),
                  suffixIcon: filterState.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => filterNotifier.setSearchQuery(''),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ),

          // Horizontal Quick Filter Chips: Status (Section 30)
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: StatusFilter.values.map((status) {
                final isSelected = filterState.statusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilterChip(
                    label: Text(status.label),
                    selected: isSelected,
                    onSelected: (_) => filterNotifier.setStatusFilter(status),
                    selectedColor: AppColors.burntOrange,
                    labelStyle: AppTypography.badge.copyWith(
                      color: isSelected ? Colors.white : (isDark ? AppColors.darkInk : AppColors.ink),
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    ),
                    backgroundColor: isDark ? AppColors.darkCard : AppColors.softWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.ink
                            : (isDark ? AppColors.darkBorder : AppColors.ink.withOpacity(0.3)),
                        width: 1.2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Horizontal Quick Filter Chips: Category (Section 30)
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ActionChip(
                    label: const Text('ALL CATEGORIES'),
                    onPressed: () => filterNotifier.setCategoryFilter(null),
                    backgroundColor: filterState.categoryFilter == null
                        ? AppColors.ink
                        : (isDark ? AppColors.darkCard : AppColors.softWhite),
                    labelStyle: AppTypography.badge.copyWith(
                      color: filterState.categoryFilter == null
                          ? Colors.white
                          : (isDark ? AppColors.darkInk : AppColors.ink),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.ink.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
                ...DeadlineCategory.values.map((cat) {
                  final isSelected = filterState.categoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ActionChip(
                      label: Text('${cat.emoji} ${cat.label.toUpperCase()}'),
                      onPressed: () => filterNotifier.setCategoryFilter(cat),
                      backgroundColor: isSelected ? cat.color : (isDark ? AppColors.darkCard : AppColors.softWhite),
                      labelStyle: AppTypography.badge.copyWith(
                        color: isSelected ? Colors.white : (isDark ? AppColors.darkInk : AppColors.ink),
                        fontSize: 9.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.ink
                              : (isDark ? AppColors.darkBorder : AppColors.ink.withOpacity(0.3)),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Sort & Results Header Bar (Section 31)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredDeadlines.length} RESULT${filteredDeadlines.length == 1 ? '' : 'S'} FOUND',
                  style: AppTypography.stamp.copyWith(
                    color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                    fontSize: 10,
                  ),
                ),
                PopupMenuButton<DeadlineSortOption>(
                  initialValue: filterState.sortOption,
                  onSelected: (order) => filterNotifier.setSortOption(order),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.softWhite,
                      borderRadius: AppRadius.radiusSm,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.ink.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort_rounded, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          filterState.sortOption.label.toUpperCase(),
                          style: AppTypography.badge.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (context) => DeadlineSortOption.values.map((order) {
                    return PopupMenuItem(
                      value: order,
                      child: Text(
                        order.label,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: order == filterState.sortOption ? FontWeight.w800 : FontWeight.normal,
                          color: order == filterState.sortOption ? AppColors.burntOrange : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Results List (Section 28 & 29)
          Expanded(
            child: filteredDeadlines.isEmpty
                ? (filterState.searchQuery.isNotEmpty
                    ? EmptyStateView.noSearchResults(
                        query: filterState.searchQuery,
                        onClear: () => filterNotifier.setSearchQuery(''),
                      )
                    : (activeCount > 0
                        ? EmptyStateView.noFilterMatches(
                            onReset: () => filterNotifier.reset(),
                          )
                        : EmptyStateView.noSearchResults(
                            onClear: () => filterNotifier.reset(),
                          )))
                : ListView.builder(
                    padding: AppSpacing.screenPadding,
                    itemCount: filteredDeadlines.length,
                    itemBuilder: (context, index) {
                      final item = filteredDeadlines[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: DeadlineTicketCard(
                          deadline: item,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DeadlineDetailScreen(deadlineId: item.id),
                              ),
                            );
                          },
                          onToggleComplete: () {
                            ref.read(deadlineNotifierProvider.notifier).toggleComplete(item.id);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
