import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_radius.dart';
import '../core/constants/app_typography.dart';
import '../models/category.dart';

class CategoryBadge extends StatelessWidget {
  final DeadlineCategory category;
  final bool compact;

  const CategoryBadge({
    super.key,
    required this.category,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.softWhite,
        borderRadius: AppRadius.radiusSm,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.ink.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.emoji, style: TextStyle(fontSize: compact ? 11 : 13)),
          const SizedBox(width: 4),
          Text(
            category.label.toUpperCase(),
            style: AppTypography.badge.copyWith(
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkInk : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
