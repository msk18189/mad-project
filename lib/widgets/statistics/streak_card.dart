import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_typography.dart';
import '../../models/streak_stats.dart';

/// Distinctive editorial Streak card (Phase 7 Section 20-23)
class StreakCard extends StatelessWidget {
  final StreakStats streakStats;

  const StreakCard({
    super.key,
    required this.streakStats,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = streakStats.currentStreak;
    final longest = streakStats.longestStreak;
    final hasActiveStreak = current > 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.softWhite,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.ink,
          width: 1.8,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: hasActiveStreak
                          ? AppColors.burntOrange.withValues(alpha: 0.15)
                          : (isDark ? AppColors.darkPaper : AppColors.paper),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: hasActiveStreak ? AppColors.burntOrange : AppColors.mutedGrey,
                        width: 1.2,
                      ),
                    ),
                    child: Text(
                      hasActiveStreak ? '🔥' : '⏳',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DISCIPLINE STREAK',
                        style: AppTypography.stamp.copyWith(
                          fontSize: 10,
                          letterSpacing: 1.4,
                          color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                        ),
                      ),
                      Text(
                        hasActiveStreak ? '$current DAY${current == 1 ? '' : 'S'} IN A ROW' : 'NO ACTIVE STREAK',
                        style: AppTypography.titleMedium.copyWith(
                          color: hasActiveStreak ? AppColors.burntOrange : (isDark ? AppColors.darkInk : AppColors.ink),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPaper : AppColors.paper,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.ink.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'BEST',
                      style: AppTypography.stamp.copyWith(
                        fontSize: 8.5,
                        color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                      ),
                    ),
                    Text(
                      '$longest d',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.darkInk : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasActiveStreak
                ? "You've been showing up. Keep the momentum alive."
                : "Complete a deadline today to start your streak.",
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
