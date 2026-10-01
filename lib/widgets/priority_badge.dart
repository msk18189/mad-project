import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_radius.dart';
import '../core/constants/app_typography.dart';
import '../models/priority.dart';

class PriorityBadge extends StatelessWidget {
  final DeadlinePriority priority;
  final bool compact;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: priority.color,
        borderRadius: AppRadius.radiusSm,
        border: Border.all(color: AppColors.ink, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.ink,
            offset: Offset(1.5, 1.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        priority.label,
        style: AppTypography.badge.copyWith(
          color: priority.textColor,
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
