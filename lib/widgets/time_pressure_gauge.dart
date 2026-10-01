import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';

class TimePressureGauge extends StatelessWidget {
  final double score; // 0.0 to 100.0

  const TimePressureGauge({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0.0, 100.0);
    final ratio = clamped / 100.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String stage;
    final Color stageColor;
    if (clamped < 25) {
      stage = 'CALM';
      stageColor = AppColors.oliveGreen;
    } else if (clamped < 60) {
      stage = 'FOCUS';
      stageColor = AppColors.mustard;
    } else if (clamped < 85) {
      stage = 'URGENT';
      stageColor = AppColors.burntOrange;
    } else {
      stage = 'CRITICAL';
      stageColor = AppColors.danger;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TIME PRESSURE',
              style: AppTypography.badge.copyWith(
                fontSize: 10,
                color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                letterSpacing: 1.0,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: stageColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: stageColor, width: 1),
              ),
              child: Text(
                '$stage (${clamped.toInt()}%)',
                style: AppTypography.badge.copyWith(
                  color: stageColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Gauge track with segments: CALM, FOCUS, URGENT, CRITICAL
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final pointerPos = (w * ratio).clamp(6.0, w - 6.0);

            return Column(
              children: [
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Base multi-colored track
                    Container(
                      height: 8,
                      width: w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.ink,
                          width: 1.2,
                        ),
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.oliveGreen,
                            AppColors.mustard,
                            AppColors.burntOrange,
                            AppColors.danger,
                          ],
                          stops: [0.15, 0.45, 0.75, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Indicator caret positioned along the track
                SizedBox(
                  height: 16,
                  width: w,
                  child: Stack(
                    children: [
                      Positioned(
                        left: pointerPos - 5,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_drop_up_rounded,
                              size: 16,
                              color: isDark ? AppColors.darkInk : AppColors.ink,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Segment labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabel('CALM', isDark),
                    _buildLabel('FOCUS', isDark),
                    _buildLabel('URGENT', isDark),
                    _buildLabel('CRITICAL', isDark),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: AppTypography.badge.copyWith(
        fontSize: 8.5,
        color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
        letterSpacing: 0.5,
      ),
    );
  }
}
