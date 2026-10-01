import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_radius.dart';
import '../core/constants/app_typography.dart';
import '../core/utils/countdown_utils.dart';
import '../core/utils/time_progress.dart';
import '../models/deadline.dart';
import 'animations/press_scale.dart';
import 'category_badge.dart';
import 'countdown_display.dart';
import 'priority_badge.dart';
import 'tactile_progress_bar.dart';
import 'time_pressure_gauge.dart';

class HeroUrgentCard extends StatelessWidget {
  final Deadline deadline;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;

  const HeroUrgentCard({
    super.key,
    required this.deadline,
    required this.onTap,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final relativeDateStr = CountdownUtils.formatRelativeDate(deadline.dueDateTime, now: now);
    final pressure = deadline.calculateTimePressure(now);
    final timeProgressValue = TimeProgress.calculate(
      createdAt: deadline.createdAt,
      deadlineDateTime: deadline.deadlineDateTime,
      now: now,
    );

    return PressScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.softWhite,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.ink,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : AppColors.burntOrange.withValues(alpha: 0.9),
              offset: const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Accent Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.burntOrange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        'MOST URGENT DEADLINE',
                        style: AppTypography.stamp.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  CategoryBadge(category: deadline.category, compact: true),
                ],
              ),
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deadline.title,
                              style: AppTypography.displayMedium.copyWith(
                                color: isDark ? AppColors.darkInk : AppColors.ink,
                                fontSize: 24,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (deadline.description != null && deadline.description!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                deadline.description!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        onPressed: onToggleComplete,
                        tooltip: 'Mark Complete',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.oliveGreen.withValues(alpha: 0.15),
                          side: const BorderSide(color: AppColors.oliveGreen, width: 1.5),
                        ),
                        icon: const Icon(Icons.check, color: AppColors.oliveGreen, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Countdown Box (Visual Focal Point - Section 20)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPaper : AppColors.paper,
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.ink,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: CountdownDisplay(
                        targetDate: deadline.dueDateTime,
                        style: CountdownStyle.hero,
                        textColor: isDark ? AppColors.darkInk : AppColors.ink,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Time Pressure Gauge
                  TimePressureGauge(score: pressure),

                  const SizedBox(height: 14),

                  // Time Progress Bar (Section 14 & 16)
                  TactileProgressBar(
                    value: timeProgressValue,
                    label: 'TIME USED: ${TimeProgress.formatPercent(timeProgressValue)}',
                    color: AppColors.burntOrange,
                    height: 10,
                  ),

                  // Task Progress if subtasks exist
                  if (deadline.subtasks.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    TactileProgressBar(
                      value: deadline.subtaskProgress,
                      label: 'TASKS: ${deadline.subtaskSummary}',
                      color: AppColors.petrolBlue,
                      height: 10,
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Bottom Meta: Priority & Relative Date (Section 45 & 46)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PriorityBadge(priority: deadline.priority),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            relativeDateStr,
                            style: AppTypography.badge.copyWith(
                              fontSize: 11,
                              color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
