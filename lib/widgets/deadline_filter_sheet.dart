import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_radius.dart';
import '../core/constants/app_typography.dart';
import '../models/category.dart';
import '../providers/filter_provider.dart';

/// Editorial Bottom Sheet for Deadline Filters and Sorting (Section 30, 31, 32)
class DeadlineFilterSheet extends ConsumerStatefulWidget {
  const DeadlineFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DeadlineFilterSheet(),
    );
  }

  @override
  ConsumerState<DeadlineFilterSheet> createState() => _DeadlineFilterSheetState();
}

class _DeadlineFilterSheetState extends ConsumerState<DeadlineFilterSheet> {
  late StatusFilter _selectedStatus;
  late PriorityFilter _selectedPriority;
  late DeadlineCategory? _selectedCategory;
  late DeadlineSortOption _selectedSort;

  @override
  void initState() {
    super.initState();
    final current = ref.read(filterProvider);
    _selectedStatus = current.statusFilter;
    _selectedPriority = current.priorityFilter;
    _selectedCategory = current.categoryFilter;
    _selectedSort = current.sortOption;
  }

  void _reset() {
    setState(() {
      _selectedStatus = StatusFilter.all;
      _selectedPriority = PriorityFilter.all;
      _selectedCategory = null;
      _selectedSort = DeadlineSortOption.soonest;
    });
  }

  void _apply() {
    final notifier = ref.read(filterProvider.notifier);
    notifier.setStatusFilter(_selectedStatus);
    notifier.setPriorityFilter(_selectedPriority);
    notifier.setCategoryFilter(_selectedCategory);
    notifier.setSortOption(_selectedSort);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.softWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.ink,
            width: 2.0,
          ),
          left: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.ink,
            width: 2.0,
          ),
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.ink,
            width: 2.0,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkMuted : AppColors.mutedGrey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 20, color: AppColors.burntOrange),
                    const SizedBox(width: 8),
                    Text(
                      'FILTER DEADLINES',
                      style: AppTypography.titleMedium.copyWith(
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.darkInk : AppColors.ink,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _reset,
                  child: Text(
                    'RESET',
                    style: AppTypography.stamp.copyWith(
                      color: AppColors.burntOrange,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1.2),

          // Filter Content (Scrollable)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Status Filter Section (Section 30)
                  _buildSectionTitle('STATUS', isDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: StatusFilter.values.map((status) {
                      final isSelected = _selectedStatus == status;
                      return _buildFilterChip(
                        label: status.label,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () {
                          setState(() => _selectedStatus = status);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 2. Priority Filter Section (Section 30)
                  _buildSectionTitle('PRIORITY', isDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: PriorityFilter.values.map((priority) {
                      final isSelected = _selectedPriority == priority;
                      return _buildFilterChip(
                        label: priority.label,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () {
                          setState(() => _selectedPriority = priority);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 3. Category Filter Section (Section 30)
                  _buildSectionTitle('CATEGORY', isDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildFilterChip(
                        label: 'ALL CATEGORIES',
                        isSelected: _selectedCategory == null,
                        isDark: isDark,
                        onTap: () {
                          setState(() => _selectedCategory = null);
                        },
                      ),
                      ...DeadlineCategory.values.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return _buildFilterChip(
                          label: '${cat.emoji} ${cat.label.toUpperCase()}',
                          isSelected: isSelected,
                          isDark: isDark,
                          selectedColor: cat.color,
                          onTap: () {
                            setState(() => _selectedCategory = cat);
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. Sort Options Section (Section 31)
                  _buildSectionTitle('SORT BY', isDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: DeadlineSortOption.values.map((option) {
                      final isSelected = _selectedSort == option;
                      return _buildFilterChip(
                        label: option.label.toUpperCase(),
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () {
                          setState(() => _selectedSort = option);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPaper : AppColors.paper,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.ink.withOpacity(0.3),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.ink,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusSm,
                      ),
                    ),
                    child: Text(
                      'CANCEL',
                      style: AppTypography.badge.copyWith(
                        letterSpacing: 1.0,
                        color: isDark ? AppColors.darkInk : AppColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.burntOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusSm,
                        side: const BorderSide(color: AppColors.ink, width: 1.5),
                      ),
                    ),
                    child: Text(
                      'APPLY FILTERS',
                      style: AppTypography.badge.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: AppTypography.stamp.copyWith(
        fontSize: 11,
        color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    Color? selectedColor,
  }) {
    final activeColor = selectedColor ?? AppColors.burntOrange;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? AppColors.darkPaper : AppColors.softWhite),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? AppColors.ink
                : (isDark ? AppColors.darkBorder : AppColors.ink.withOpacity(0.3)),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDark ? Colors.black54 : AppColors.ink,
                    offset: const Offset(1.5, 1.5),
                    blurRadius: 0,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.badge.copyWith(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkInk : AppColors.ink),
          ),
        ),
      ),
    );
  }
}
