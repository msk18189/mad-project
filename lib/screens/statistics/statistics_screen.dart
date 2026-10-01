import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../models/category.dart';
import '../../models/priority.dart';
import '../../providers/statistics_provider.dart';
import '../../widgets/animations/press_scale.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/statistics/stat_block.dart';
import '../../widgets/statistics/streak_card.dart';
import '../../widgets/tactile_progress_bar.dart';

/// Phase 7 & 8 Personal Performance Journal & Analytics Dashboard (Sections 3-26)
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = ref.watch(statisticsProvider);
    final currentPeriod = ref.watch(statisticsPeriodProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkPaper : AppColors.paper,
      appBar: AppBar(
        title: Text(
          'PERFORMANCE JOURNAL',
          style: AppTypography.titleMedium.copyWith(letterSpacing: 1.2),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 24: Tactile Period Switcher [ THIS WEEK | THIS MONTH | ALL TIME ]
            _buildPeriodSwitcher(context, ref, currentPeriod, isDark),
            const SizedBox(height: 20),

            // Section 26: Empty State when no data is recorded in this period
            if (stats.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: EmptyStateView(
                  title: 'YOUR STORY STARTS HERE',
                  message: 'Complete your first deadline\nand your statistics will appear.',
                  subMessage: 'Every second counts.',
                  icon: Icons.auto_graph_rounded,
                ),
              )
            else ...[
              // 1. Hero Completion Box (Section 11 & 12)
              _buildHeroCompletionBox(stats, isDark),
              const SizedBox(height: 16),

              // 2. 4-Grid Key Metrics (Section 8, 9, 10, 11)
              Row(
                children: [
                  Expanded(
                    child: StatBlock(
                      label: 'COMPLETED',
                      value: '${stats.completedCount}',
                      subtitle: currentPeriod.label.toLowerCase(),
                      accentColor: AppColors.oliveGreen,
                      rotationAngle: -0.005,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatBlock(
                      label: 'MISSED',
                      value: '${stats.missedCount}',
                      subtitle: stats.missedCount == 0 ? 'flawless' : 'needs focus',
                      accentColor: stats.missedCount > 0 ? AppColors.danger : AppColors.mutedGrey,
                      rotationAngle: 0.005,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: StatBlock(
                      label: 'ON-TIME RATE',
                      value: stats.onTimeRate != null ? '${stats.onTimeRate!.round()}%' : '—',
                      subtitle: 'before deadline',
                      accentColor: AppColors.burntOrange,
                      rotationAngle: 0.004,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatBlock(
                      label: 'ACTIVE',
                      value: '${stats.pendingCount}',
                      subtitle: 'on the clock',
                      accentColor: AppColors.petrolBlue,
                      rotationAngle: -0.004,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. Discipline Streak (Section 20-23)
              StreakCard(streakStats: stats.streakStats),
              const SizedBox(height: 24),

              // 4. Time Pressure Behavior (Section 14 & 15)
              _buildTimePressureSection(stats, isDark),
              const SizedBox(height: 24),

              // 5. Phase 5 Subtask Progress (Section 13)
              _buildSubtaskProgressSection(stats, isDark),
              const SizedBox(height: 24),

              // 6. Category Breakdown (Section 18)
              _buildCategoryBreakdownSection(stats, isDark),
              const SizedBox(height: 24),

              // 7. Priority Breakdown (Section 19)
              _buildPriorityBreakdownSection(stats, isDark),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }

  /// Section 24: Tactile Segmented Period Switcher
  Widget _buildPeriodSwitcher(
    BuildContext context,
    WidgetRef ref,
    StatisticsPeriod current,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
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
      child: Row(
        children: StatisticsPeriod.values.map((period) {
          final isSelected = current == period;
          return Expanded(
            child: PressScale(
              onTap: () {
                ref.read(statisticsPeriodProvider.notifier).setPeriod(period);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.burntOrange : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: isSelected
                      ? Border.all(color: AppColors.ink, width: 1.2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    period.label,
                    style: AppTypography.badge.copyWith(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.darkMuted : AppColors.mutedGrey),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Hero Completion Card (Section 11 & 12)
  Widget _buildHeroCompletionBox(DeadlineStatistics stats, bool isDark) {
    final rateDisplay = stats.completionRate != null
        ? '${stats.completionRate!.toStringAsFixed(1)}%'
        : '—';
    final progressFraction = stats.completionRate != null
        ? (stats.completionRate! / 100.0).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.softWhite,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.ink,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : AppColors.ink,
            offset: const Offset(3.5, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COMPLETION RELIABILITY',
                style: AppTypography.stamp.copyWith(
                  color: AppColors.burntOrange,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                rateDisplay,
                style: AppTypography.displayMedium.copyWith(
                  color: isDark ? AppColors.darkInk : AppColors.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TactileProgressBar(
            value: progressFraction,
            showPercentage: false,
            height: 14,
            color: AppColors.burntOrange,
          ),
          const SizedBox(height: 8),
          Text(
            stats.completionRate != null
                ? '${stats.completedCount} completed of ${stats.completedCount + stats.missedCount} resolved deadlines'
                : 'No finished deadlines in this period',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Section 14 & 15: Time Pressure Behavior
  Widget _buildTimePressureSection(DeadlineStatistics stats, bool isDark) {
    final beforeUrgentRate = stats.completedBeforeUrgentRate != null
        ? '${stats.completedBeforeUrgentRate!.round()}%'
        : '—';
    final fraction = stats.completedBeforeUrgentRate != null
        ? (stats.completedBeforeUrgentRate! / 100.0).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.softWhite,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.ink,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TIME PRESSURE BEHAVIOR',
                style: AppTypography.stamp.copyWith(
                  color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                beforeUrgentRate,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.burntOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TactileProgressBar(
            value: fraction,
            showPercentage: false,
            height: 10,
            color: AppColors.oliveGreen,
          ),
          const SizedBox(height: 10),
          Text(
            stats.completedCount > 0
                ? '${stats.completedBeforeUrgentCount} completed before becoming urgent. ${stats.lastMinuteCompletionsCount} finished during the final urgency window.'
                : 'Complete deadlines ahead of time to build proactive habits.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
            ),
          ),
        ],
      ),
    );
  }

  /// Section 13: Phase 5 Subtask Progress
  Widget _buildSubtaskProgressSection(DeadlineStatistics stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.softWhite,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.ink,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TASK BREAKDOWN PROGRESS',
                style: AppTypography.stamp.copyWith(
                  color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${(stats.subtaskProgress * 100).round()}%',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.darkInk : AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TactileProgressBar(
            value: stats.subtaskProgress,
            showPercentage: false,
            height: 10,
            color: AppColors.petrolBlue,
          ),
          const SizedBox(height: 10),
          Text(
            '${stats.completedSubtasksCount} / ${stats.totalSubtasksCount} subtasks completed across all deadlines.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
            ),
          ),
        ],
      ),
    );
  }

  /// Section 18: Category Breakdown
  Widget _buildCategoryBreakdownSection(DeadlineStatistics stats, bool isDark) {
    final activeCategories = DeadlineCategory.values
        .where((cat) => (stats.categoryCounts[cat] ?? 0) > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BY CATEGORY',
          style: AppTypography.stamp.copyWith(
            color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        if (activeCategories.isEmpty)
          Text(
            'No categorized deadlines in this period.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.mutedGrey),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.softWhite,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.ink,
                width: 1.5,
              ),
            ),
            child: Column(
              children: activeCategories.map((cat) {
                final count = stats.categoryCounts[cat] ?? 0;
                final fraction = stats.totalCount > 0 ? (count / stats.totalCount) : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${cat.emoji} ${cat.label.toUpperCase()}',
                          style: AppTypography.badge.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkInk : AppColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TactileProgressBar(
                          value: fraction,
                          showPercentage: false,
                          height: 8,
                          color: cat.color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$count',
                        style: AppTypography.stamp.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: isDark ? AppColors.darkInk : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  /// Section 19: Priority Breakdown
  Widget _buildPriorityBreakdownSection(DeadlineStatistics stats, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BY PRIORITY',
          style: AppTypography.stamp.copyWith(
            color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.softWhite,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.ink,
              width: 1.5,
            ),
          ),
          child: Column(
            children: DeadlinePriority.values.map((prio) {
              final count = stats.priorityCounts[prio] ?? 0;
              final fraction = stats.totalCount > 0 ? (count / stats.totalCount) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        prio.label.toUpperCase(),
                        style: AppTypography.badge.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: prio.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TactileProgressBar(
                        value: fraction,
                        showPercentage: false,
                        height: 8,
                        color: prio.color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$count',
                      style: AppTypography.stamp.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: isDark ? AppColors.darkInk : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
