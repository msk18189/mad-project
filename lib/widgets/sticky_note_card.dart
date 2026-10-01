import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_radius.dart';
import '../core/constants/app_typography.dart';
import '../models/deadline.dart';
import 'countdown_display.dart';
import 'priority_badge.dart';

class StickyNoteCard extends StatelessWidget {
  final Deadline deadline;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final double rotationAngle;

  const StickyNoteCard({
    super.key,
    required this.deadline,
    required this.onTap,
    required this.onToggleComplete,
    this.rotationAngle = -0.015,
  });

  @override
  Widget build(BuildContext context) {
    final noteColors = [
      AppColors.stickyYellow,
      AppColors.stickyBlue,
      AppColors.stickyPink,
      AppColors.stickyGreen,
    ];
    final color = noteColors[deadline.id.hashCode.abs() % noteColors.length];

    final card = InkWell(
      onTap: onTap,
      borderRadius: AppRadius.radiusMd,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppRadius.radiusMd,
          border: Border.all(color: AppColors.ink, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Pin & Priority
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                ),
                PriorityBadge(priority: deadline.priority, compact: true),
              ],
            ),
            const SizedBox(height: 8),

            // Handwritten sticky note accent
            Text(
              deadline.isCompleted
                  ? "✓ you've got this!"
                  : (deadline.isPassed() ? "deadline passed!" : "don't forget this"),
              style: AppTypography.handwritten.copyWith(
                fontSize: 15,
                color: deadline.isCompleted ? AppColors.oliveGreen : AppColors.burntOrange,
              ),
            ),
            const SizedBox(height: 4),

            // Title
            Text(
              deadline.title,
              style: AppTypography.titleSmall.copyWith(
                decoration: deadline.isCompleted ? TextDecoration.lineThrough : null,
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const Spacer(),

            // Countdown in sticky note
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: CountdownDisplay(
                    targetDate: deadline.dueDateTime,
                    style: CountdownStyle.compact,
                    textColor: AppColors.ink,
                  ),
                ),
                InkWell(
                  onTap: onToggleComplete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: deadline.isCompleted ? AppColors.oliveGreen : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 1.2),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 14,
                      color: deadline.isCompleted ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Transform.rotate(
      angle: rotationAngle,
      child: card,
    );
  }
}
