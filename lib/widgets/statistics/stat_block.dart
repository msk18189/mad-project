import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_typography.dart';
import '../animations/press_scale.dart';

/// Standardized tactile StatBlock widget (Phase 7 Section 25 & Phase 8 Section 44)
class StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color? accentColor;
  final VoidCallback? onTap;
  final double rotationAngle;

  const StatBlock({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.accentColor,
    this.onTap,
    this.rotationAngle = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? (isDark ? AppColors.darkInk : AppColors.ink);

    Widget card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            offset: const Offset(2.5, 2.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.stamp.copyWith(
              color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
              fontSize: 10,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.displayMedium.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.0,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 10,
                color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    if (rotationAngle != 0.0) {
      card = Transform.rotate(
        angle: rotationAngle,
        child: card,
      );
    }

    if (onTap != null) {
      return PressScale(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
