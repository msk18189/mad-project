import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_radius.dart';
import '../core/constants/app_typography.dart';
import '../core/utils/countdown_utils.dart';
import '../models/deadline.dart';
import 'animations/press_scale.dart';
import 'category_badge.dart';
import 'countdown_display.dart';
import 'editorial_stamp.dart';
import 'priority_badge.dart';
import 'tactile_progress_bar.dart';

class DeadlineTicketCard extends StatelessWidget {
  final Deadline deadline;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final double rotationAngle; // subtle rotation e.g. -0.015 or 0.012

  const DeadlineTicketCard({
    super.key,
    required this.deadline,
    required this.onTap,
    required this.onToggleComplete,
    this.rotationAngle = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final status = deadline.getStatus(now);

    final card = PressScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.softWhite,
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.ink,
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : AppColors.ink,
              offset: const Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.radiusLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Category & Status / Stamp
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, top: 12, bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CategoryBadge(category: deadline.category, compact: true),
                        const SizedBox(width: 8),
                        PriorityBadge(priority: deadline.priority, compact: true),
                      ],
                    ),
                    if (deadline.isCompleted)
                      const EditorialStamp(type: StampType.done)
                    else if (status == DeadlineStatus.missed)
                      const EditorialStamp(type: StampType.missed)
                    else if (status == DeadlineStatus.due || status == DeadlineStatus.urgent)
                      const EditorialStamp(type: StampType.urgent)
                    else if (status == DeadlineStatus.approaching)
                      const EditorialStamp(type: StampType.dueSoon),
                  ],
                ),
              ),

              // Title and Completion Checkbox
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deadline.title,
                            style: AppTypography.titleMedium.copyWith(
                              decoration: deadline.isCompleted ? TextDecoration.lineThrough : null,
                              color: deadline.isCompleted
                                  ? AppColors.mutedGrey
                                  : (isDark ? AppColors.darkInk : AppColors.ink),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (deadline.description != null && deadline.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              deadline.description!,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quick completion toggle
                    InkWell(
                      onTap: onToggleComplete,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: deadline.isCompleted ? AppColors.oliveGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: deadline.isCompleted ? AppColors.oliveGreen : AppColors.ink,
                            width: 1.5,
                          ),
                        ),
                        child: deadline.isCompleted
                            ? const Icon(Icons.check, size: 18, color: Colors.white)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Perforated Ticket Divider Line with Left & Right Cutouts
              _buildPerforatedDivider(isDark),

              // Bottom Section: Live Countdown & Subtask progress
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 15,
                            color: deadline.isCompleted
                                ? AppColors.mutedGrey
                                : (status == DeadlineStatus.due || status == DeadlineStatus.urgent
                                    ? AppColors.burntOrange
                                    : (isDark ? AppColors.darkMuted : AppColors.ink)),
                          ),
                          const SizedBox(width: 6),
                          if (deadline.isCompleted)
                            Text(
                              'FINISHED',
                              style: AppTypography.badge.copyWith(
                                color: AppColors.oliveGreen,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          else
                            Flexible(
                              child: CountdownDisplay(
                                targetDate: deadline.dueDateTime,
                                style: CountdownStyle.compact,
                                textColor: (status == DeadlineStatus.due || status == DeadlineStatus.urgent)
                                    ? AppColors.danger
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (deadline.subtasks.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkPaper : AppColors.paper,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.ink.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              deadline.subtaskSummary,
                              style: AppTypography.badge.copyWith(
                                fontSize: 9.5,
                                color: isDark ? AppColors.darkMuted : AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          CountdownUtils.formatRelativeDate(deadline.dueDateTime, now: now),
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (deadline.subtasks.isNotEmpty && !deadline.isCompleted)
                Padding(
                  padding: const EdgeInsets.only(left: 14, right: 14, bottom: 8),
                  child: TactileProgressBar(
                    value: deadline.subtaskProgress,
                    showPercentage: false,
                    height: 5,
                    color: AppColors.petrolBlue,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (rotationAngle != 0.0) {
      return Transform.rotate(
        angle: rotationAngle,
        child: card,
      );
    }

    return card;
  }

  Widget _buildPerforatedDivider(bool isDark) {
    return Row(
      children: [
        // Left notch
        Container(
          width: 8,
          height: 16,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkPaper : AppColors.paper,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border(
              top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.ink, width: 1.5),
              right: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.ink, width: 1.5),
              bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.ink, width: 1.5),
            ),
          ),
        ),
        // Dashed line
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const dashWidth = 5.0;
              const dashSpace = 4.0;
              final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(dashCount, (_) {
                  return Container(
                    width: dashWidth,
                    height: 1.2,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  );
                }),
              );
            },
          ),
        ),
        // Right notch
        Container(
          width: 8,
          height: 16,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkPaper : AppColors.paper,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            border: Border(
              top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.ink, width: 1.5),
              left: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.ink, width: 1.5),
              bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.ink, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
