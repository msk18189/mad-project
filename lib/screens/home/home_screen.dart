import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/countdown_utils.dart';
import '../../models/deadline.dart';
import '../../providers/countdown_tick_provider.dart';
import '../../providers/deadline_provider.dart';
import '../../widgets/deadline_ticket_card.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/hero_urgent_card.dart';
import '../calendar/calendar_screen.dart';
import '../deadline/deadline_detail_screen.dart';
import '../deadline/deadline_form_screen.dart';
import '../history/history_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deadlineState = ref.watch(deadlineNotifierProvider);
    // Subscribe to centralized 1-second ticker to drive live countdowns
    final now = ref.watch(currentDateTimeProvider);

    final todayFormatted = DateFormat('EEEE, MMMM d').format(now).toUpperCase();

    // Derived collections using centralized selectors (Section 40)
    final activeDeadlines = deadlineState.activeDeadlines(now);
    final heroDeadline = deadlineState.nextDeadline(now);
    final urgentList = deadlineState.urgentDeadlines(now);
    final upcomingList = deadlineState.upcomingDeadlines(now);
    final laterList = deadlineState.laterDeadlines(now);
    final missedList = deadlineState.missedDeadlines(now);
    final completedList = deadlineState.completedDeadlines;

    // Header dynamic supporting text (Section 18)
    final String dynamicSubtext;
    if (activeDeadlines.isEmpty && completedList.isNotEmpty && missedList.isEmpty) {
      dynamicSubtext = "You've cleared the board. Enjoy the quiet.";
    } else if (activeDeadlines.isEmpty && missedList.isNotEmpty) {
      dynamicSubtext = "The clock won on ${missedList.length} items. On to the next one.";
    } else if (activeDeadlines.isEmpty) {
      dynamicSubtext = 'Your schedule is clear. For now.';
    } else if (heroDeadline != null &&
        (heroDeadline.getStatus(now) == DeadlineStatus.due ||
            heroDeadline.getStatus(now) == DeadlineStatus.urgent)) {
      dynamicSubtext = "Time's running. Prioritize what is due right now.";
    } else {
      dynamicSubtext = "You've got ${activeDeadlines.length} ${activeDeadlines.length == 1 ? 'deadline' : 'deadlines'} on the clock.";
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkPaper : AppColors.paper,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Editorial Header (Section 18)
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          todayFormatted,
                          style: AppTypography.stamp.copyWith(
                            color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.softWhite,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.ink,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            '${activeDeadlines.length} ON THE CLOCK',
                            style: AppTypography.badge.copyWith(
                              color: activeDeadlines.isNotEmpty
                                  ? AppColors.burntOrange
                                  : AppColors.oliveGreen,
                              fontWeight: FontWeight.w900,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CountdownUtils.getGreeting(now: now),
                      style: AppTypography.displayLarge.copyWith(
                        color: isDark ? AppColors.darkInk : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dynamicSubtext,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Urgency Summary Bar (Section 19)
                    if (deadlineState.deadlines.isNotEmpty)
                      _buildUrgencySummaryBar(
                        isDark: isDark,
                        urgentCount: (heroDeadline != null &&
                                (heroDeadline.getStatus(now) == DeadlineStatus.due ||
                                    heroDeadline.getStatus(now) == DeadlineStatus.urgent)
                            ? 1
                            : 0) +
                            urgentList.length,
                        upcomingCount: (heroDeadline != null &&
                                heroDeadline.getStatus(now) == DeadlineStatus.approaching
                            ? 1
                            : 0) +
                            upcomingList.length,
                        laterCount: (heroDeadline != null &&
                                heroDeadline.getStatus(now) == DeadlineStatus.upcoming
                            ? 1
                            : 0) +
                            laterList.length,
                        missedCount: missedList.length,
                      ),
                    const SizedBox(height: 12),

                    // Quick Navigation Shortcuts (Section 42)
                    _buildQuickShortcuts(context, isDark),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Loading State (Section 29)
            if (deadlineState.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView.loading(),
              )

            // Error State (Section 30)
            else if (deadlineState.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView.error(
                  message: deadlineState.errorMessage ?? "We couldn't load your deadlines.",
                  onRetry: () => ref.read(deadlineNotifierProvider.notifier).loadDeadlines(),
                ),
              )

            // Empty State: No deadlines at all (Section 27)
            else if (deadlineState.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView.clearClock(
                  onAdd: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DeadlineFormScreen()),
                    );
                  },
                ),
              )

            // Empty State: All completed (Section 28)
            else if (activeDeadlines.isEmpty && missedList.isEmpty && completedList.isNotEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView.allClear(
                  onAdd: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DeadlineFormScreen()),
                    );
                  },
                ),
              )

            // Empty State: Only missed deadlines remain (Section 29)
            else if (activeDeadlines.isEmpty && missedList.isNotEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView.missedOnly(
                  count: missedList.length,
                  onAdd: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DeadlineFormScreen()),
                    );
                  },
                ),
              )

            // Dynamic Dashboard Content
            else ...[
              // 1. Hero Urgent Card (Section 20 & 21)
              if (heroDeadline != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 18, right: 18, bottom: 8),
                    child: Text(
                      "TIME'S RUNNING",
                      style: AppTypography.stamp.copyWith(
                        color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: HeroUrgentCard(
                      deadline: heroDeadline,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DeadlineDetailScreen(deadlineId: heroDeadline.id),
                          ),
                        );
                      },
                      onToggleComplete: () {
                        ref.read(deadlineNotifierProvider.notifier).toggleComplete(heroDeadline.id);
                      },
                    ),
                  ),
                ),
              ],

              // 2. Urgent Section: ON YOUR RADAR (Section 22)
              if (urgentList.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'ON YOUR RADAR',
                  countLabel: '${urgentList.length} URGENT',
                  countColor: AppColors.burntOrange,
                  isDark: isDark,
                ),
                _buildDeadlineSliverList(
                  items: urgentList,
                  isDark: isDark,
                  ref: ref,
                ),
              ],

              // 3. Upcoming Section: UP NEXT (Section 23)
              if (upcomingList.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'UP NEXT',
                  countLabel: '${upcomingList.length} COMING UP',
                  countColor: AppColors.petrolBlue,
                  isDark: isDark,
                ),
                _buildDeadlineSliverList(
                  items: upcomingList,
                  isDark: isDark,
                  ref: ref,
                ),
              ],

              // 4. Later Section: LATER (Section 24)
              if (laterList.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'LATER',
                  countLabel: '${laterList.length} SCHEDULED',
                  countColor: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                  isDark: isDark,
                ),
                _buildDeadlineSliverList(
                  items: laterList,
                  isDark: isDark,
                  ref: ref,
                ),
              ],

              // 5. Missed Deadlines Section (Section 25 & 44)
              if (missedList.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'MISSED',
                  countLabel: '${missedList.length} EXPIRED',
                  countColor: AppColors.danger,
                  isDark: isDark,
                ),
                _buildDeadlineSliverList(
                  items: missedList,
                  isDark: isDark,
                  ref: ref,
                ),
              ],

              // 6. Completed Deadlines Summary Link (Section 26 & 43)
              if (completedList.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HistoryScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.softWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.oliveGreen.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                color: AppColors.oliveGreen, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${completedList.length} completed ${completedList.length == 1 ? "deadline" : "deadlines"} in history',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.oliveGreen,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DeadlineFormScreen()),
          );
        },
        backgroundColor: AppColors.burntOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.ink, width: 1.8),
        ),
        icon: const Icon(Icons.add, size: 22),
        label: Text(
          'NEW DEADLINE',
          style: AppTypography.badge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  /// Compact Urgency Summary Bar (Section 19)
  Widget _buildUrgencySummaryBar({
    required bool isDark,
    required int urgentCount,
    required int upcomingCount,
    required int laterCount,
    required int missedCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (urgentCount > 0) ...[
            _buildSummaryChip(
              label: '$urgentCount URGENT',
              color: AppColors.burntOrange,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
          ],
          if (upcomingCount > 0) ...[
            _buildSummaryChip(
              label: '$upcomingCount UPCOMING',
              color: AppColors.petrolBlue,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
          ],
          if (laterCount > 0) ...[
            _buildSummaryChip(
              label: '$laterCount LATER',
              color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
          ],
          if (missedCount > 0) ...[
            _buildSummaryChip(
              label: '$missedCount MISSED',
              color: AppColors.danger,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryChip({
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        label,
        style: AppTypography.badge.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String countLabel,
    required Color countColor,
    required bool isDark,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 18, right: 18, top: 24, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTypography.stamp.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              countLabel,
              style: AppTypography.badge.copyWith(
                color: countColor,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineSliverList({
    required List<Deadline> items,
    required bool isDark,
    required WidgetRef ref,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            // Subtle alternating rotation for tactile editorial feel
            final angle = (index % 2 == 0) ? -0.006 : 0.006;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: DeadlineTicketCard(
                deadline: item,
                rotationAngle: angle,
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
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildQuickShortcuts(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildShortcutChip(
            icon: Icons.search_rounded,
            label: 'SEARCH',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildShortcutChip(
            icon: Icons.calendar_month_outlined,
            label: 'CALENDAR',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            ),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildShortcutChip(
            icon: Icons.archive_outlined,
            label: 'HISTORY',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.softWhite,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.ink.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.burntOrange),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.badge.copyWith(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDark ? AppColors.darkInk : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
