import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_radius.dart';
import '../core/constants/app_typography.dart';

class TactileProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color? color;
  final String? label;
  final bool showPercentage;
  final double height;

  const TactileProgressBar({
    super.key,
    required this.value,
    this.color,
    this.label,
    this.showPercentage = true,
    this.height = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final percentInt = (clamped * 100).toInt();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fillColor = color ??
        (clamped > 0.85
            ? AppColors.danger
            : clamped > 0.6
                ? AppColors.burntOrange
                : clamped > 0.3
                    ? AppColors.mustard
                    : AppColors.oliveGreen);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!.toUpperCase(),
                    style: AppTypography.badge.copyWith(
                      fontSize: 10,
                      color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                      letterSpacing: 1.0,
                    ),
                  ),
                if (showPercentage)
                  Text(
                    '$percentInt%',
                    style: AppTypography.badge.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkInk : AppColors.ink,
                    ),
                  ),
              ],
            ),
          ),
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkPaper : AppColors.softWhite,
            borderRadius: AppRadius.radiusSm,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.ink,
              width: 1.5,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * clamped,
                    height: height,
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
