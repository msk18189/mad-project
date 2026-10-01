import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../models/subtask.dart';

class SubtaskItemTile extends StatelessWidget {
  final int index;
  final Subtask subtask;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final bool showDragHandle;

  const SubtaskItemTile({
    super.key,
    this.index = 0,
    required this.subtask,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
    this.showDragHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.softWhite,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: subtask.isCompleted
              ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              : (isDark ? AppColors.darkBorder : AppColors.ink.withValues(alpha: 0.3)),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Section 8: Editorial numbering
          Text(
            '${index + 1}.',
            style: AppTypography.monoSmall.copyWith(
              color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),

          // Custom tactile checkbox (Section 8 & 10)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: subtask.isCompleted ? AppColors.oliveGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: subtask.isCompleted ? AppColors.oliveGreen : AppColors.ink,
                  width: 1.5,
                ),
              ),
              child: subtask.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Subtask Title & optional Description (Section 7 & 8)
          Expanded(
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    subtask.title,
                    style: AppTypography.bodyMedium.copyWith(
                      decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                      color: subtask.isCompleted
                          ? (isDark ? AppColors.darkMuted : AppColors.mutedGrey)
                          : (isDark ? AppColors.darkInk : AppColors.ink),
                      fontWeight: subtask.isCompleted ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                  if (subtask.description != null && subtask.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtask.description!,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                      ),
                    ),
                  ],
                  if (subtask.isCompleted && subtask.completedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Done ${DateFormat('MMM d, h:mm a').format(subtask.completedAt!)}',
                      style: AppTypography.monoSmall.copyWith(
                        fontSize: 9.5,
                        color: AppColors.oliveGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Edit button
          if (onEdit != null)
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 16,
                color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(),
              tooltip: 'Edit Task',
              onPressed: onEdit,
            ),

          // Delete action
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
            tooltip: 'Delete Task',
            onPressed: onDelete,
          ),

          // Reorder handle (Section 16)
          if (showDragHandle) ...[
            const SizedBox(width: 4),
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 20,
                color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
