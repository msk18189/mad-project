import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../models/deadline.dart';
import '../../providers/deadline_provider.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/deadline_ticket_card.dart';
import '../../widgets/empty_state_view.dart';
import '../deadline/deadline_detail_screen.dart';

/// Phase 6 Archives & History Screen (Sections 34-38)
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Section 38: Confirmed deletion respecting Phase 4 notification cancellation
  Future<void> _confirmDelete(BuildContext context, Deadline deadline) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark ? AppColors.darkCard : AppColors.softWhite,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusMd,
          side: const BorderSide(color: AppColors.ink, width: 2),
        ),
        title: Text(
          'DELETE DEADLINE?',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently remove:',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 6),
            Text(
              deadline.title,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.burntOrange,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This action cannot be undone.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'CANCEL',
              style: AppTypography.badge.copyWith(color: AppColors.mutedGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              'DELETE',
              style: AppTypography.badge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(deadlineNotifierProvider.notifier).deleteDeadline(deadline.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allDeadlines = ref.watch(deadlineListProvider);
    final now = DateTime.now();

    final completedList = allDeadlines.where((d) => d.isCompleted).toList()
      ..sort((a, b) {
        final aTime = a.completedAt ?? a.dueDateTime;
        final bTime = b.completedAt ?? b.dueDateTime;
        return bTime.compareTo(aTime);
      });

    final missedList = allDeadlines.where((d) => !d.isCompleted && d.isPassed(now)).toList()
      ..sort((a, b) => b.dueDateTime.compareTo(a.dueDateTime));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkPaper : AppColors.paper,
      appBar: AppBar(
        title: Text(
          'ARCHIVES & HISTORY',
          style: AppTypography.titleMedium.copyWith(letterSpacing: 1.2),
        ),
        actions: [
          if (completedList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cleaning_services_outlined, size: 20),
              tooltip: 'Clear Completed',
              onPressed: () async {
                final confirmed = await ConfirmationDialog.show(
                  context,
                  title: 'Clear Completed History?',
                  content: 'All finished deadlines will be permanently removed.',
                  confirmLabel: 'Clear All',
                );
                if (confirmed == true) {
                  await ref.read(deadlineNotifierProvider.notifier).clearCompleted();
                }
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.burntOrange,
          unselectedLabelColor: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
          indicatorColor: AppColors.burntOrange,
          indicatorWeight: 3.0,
          labelStyle: AppTypography.badge.copyWith(fontSize: 11, fontWeight: FontWeight.w900),
          tabs: [
            Tab(text: 'COMPLETED (${completedList.length})'),
            Tab(text: 'MISSED (${missedList.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Completed Tab (Section 34)
          completedList.isEmpty
              ? EmptyStateView.noCompleted()
              : _buildGroupedHistoryList(completedList, isDark: isDark, isCompletedTab: true),

          // Missed Tab (Section 35)
          missedList.isEmpty
              ? EmptyStateView.noMissed()
              : _buildGroupedHistoryList(missedList, isDark: isDark, isCompletedTab: false),
        ],
      ),
    );
  }

  /// Groups deadlines by month for clear editorial reading (Section 34 & 35)
  Widget _buildGroupedHistoryList(List<Deadline> items, {required bool isDark, required bool isCompletedTab}) {
    final Map<String, List<Deadline>> grouped = {};
    for (final item in items) {
      final date = isCompletedTab ? (item.completedAt ?? item.dueDateTime) : item.dueDateTime;
      final monthKey = DateFormat('MMMM yyyy').format(date).toUpperCase();
      grouped.putIfAbsent(monthKey, () => []).add(item);
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: grouped.keys.length,
      itemBuilder: (context, groupIdx) {
        final month = grouped.keys.elementAt(groupIdx);
        final monthDeadlines = grouped[month]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                children: [
                  Text(
                    month,
                    style: AppTypography.stamp.copyWith(
                      color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Divider(
                      color: isDark ? AppColors.darkBorder : AppColors.ink.withOpacity(0.2),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
            ),
            ...monthDeadlines.map((d) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  children: [
                    DeadlineTicketCard(
                      deadline: d,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DeadlineDetailScreen(deadlineId: d.id),
                          ),
                        );
                      },
                      onToggleComplete: () {
                        // Section 37: Restoration
                        ref.read(deadlineNotifierProvider.notifier).toggleComplete(d.id);
                      },
                    ),
                    // Quick Action Bar under card
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, right: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isCompletedTab)
                            TextButton.icon(
                              onPressed: () {
                                ref.read(deadlineNotifierProvider.notifier).toggleComplete(d.id);
                              },
                              icon: const Icon(Icons.undo_rounded, size: 14, color: AppColors.burntOrange),
                              label: Text(
                                'RESTORE',
                                style: AppTypography.badge.copyWith(
                                  color: AppColors.burntOrange,
                                  fontSize: 10,
                                ),
                              ),
                            )
                          else
                            TextButton.icon(
                              onPressed: () {
                                ref.read(deadlineNotifierProvider.notifier).toggleComplete(d.id);
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 14, color: AppColors.oliveGreen),
                              label: Text(
                                'MARK DONE',
                                style: AppTypography.badge.copyWith(
                                  color: AppColors.oliveGreen,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () => _confirmDelete(context, d),
                            icon: const Icon(Icons.delete_outline, size: 14, color: AppColors.danger),
                            label: Text(
                              'DELETE',
                              style: AppTypography.badge.copyWith(
                                color: AppColors.danger,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
