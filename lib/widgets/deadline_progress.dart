import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_radius.dart';
import '../core/constants/app_typography.dart';
import '../models/subtask.dart';
import 'tactile_progress_bar.dart';

class DeadlineProgress extends StatelessWidget {
  final List<Subtask> subtasks;
  final VoidCallback? onAddFirstTask;

  const DeadlineProgress({
    super.key,
    required this.subtasks,
    this.onAddFirstTask,
  });

  int get totalCount => subtasks.length;
  int get completedCount => subtasks.where((s) => s.isCompleted).length;
  double get fraction => totalCount == 0 ? 0.0 : (completedCount / totalCount);
  int get percent => (fraction * 100).round();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Section 12: Zero-subtask encouraging state
    if (totalCount == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.softWhite,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.ink.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.playlist_add_check, size: 20, color: AppColors.burntOrange),
                const SizedBox(width: 8),
                Text(
                  'NO TASKS YET',
                  style: AppTypography.stamp.copyWith(
                    color: isDark ? AppColors.darkInk : AppColors.ink,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Break the deadline into smaller steps.',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
              ),
            ),
            if (onAddFirstTask != null) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: onAddFirstTask,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.burntOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.burntOrange, width: 1.0),
                  ),
                  child: Text(
                    '+ ADD FIRST TASK',
                    style: AppTypography.badge.copyWith(
                      color: AppColors.burntOrange,
                      fontWeight: FontWeight.w800,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Section 11 & 13: Standard progress visualization
    final isAllDone = completedCount == totalCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.softWhite,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isAllDone
              ? AppColors.oliveGreen
              : (isDark ? AppColors.darkBorder : AppColors.ink.withValues(alpha: 0.25)),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TASK PROGRESS',
                style: AppTypography.stamp.copyWith(
                  color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  Text(
                    '$completedCount / $totalCount COMPLETE',
                    style: AppTypography.monoMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkInk : AppColors.ink,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percent%',
                    style: AppTypography.monoMedium.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isAllDone ? AppColors.oliveGreen : AppColors.petrolBlue,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          TactileProgressBar(
            value: fraction,
            color: isAllDone ? AppColors.oliveGreen : AppColors.petrolBlue,
            height: 10,
          ),
        ],
      ),
    );
  }
}
