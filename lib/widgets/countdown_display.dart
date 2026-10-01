import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/utils/countdown_engine.dart';
import '../providers/countdown_tick_provider.dart';

enum CountdownStyle {
  hero, // Large numbers for hero cards
  compact, // Single line for list cards
  detailed, // Segments with labeled boxes (DAYS, HRS, MIN, SEC)
}

class CountdownDisplay extends ConsumerWidget {
  final DateTime targetDate;
  final CountdownStyle style;
  final Color? textColor;

  const CountdownDisplay({
    super.key,
    required this.targetDate,
    this.style = CountdownStyle.hero,
    this.textColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watches the live 1-second tick stream
    final tickAsync = ref.watch(countdownTickProvider);
    final now = tickAsync.value ?? DateTime.now();
    final countdown = CountdownEngine.calculate(targetDate, now);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultColor = textColor ?? (isDark ? AppColors.darkInk : AppColors.ink);

    Widget content;

    if (countdown.isExpired) {
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.danger, width: 1.5),
        ),
        child: Text(
          'DEADLINE PASSED',
          style: AppTypography.badge.copyWith(
            color: AppColors.danger,
            fontWeight: FontWeight.w900,
            fontSize: style == CountdownStyle.hero ? 15 : 11,
          ),
        ),
      );
    } else if (countdown.isDue && countdown.totalSeconds == 0) {
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.danger, width: 1.5),
        ),
        child: Text(
          'DUE NOW',
          style: AppTypography.badge.copyWith(
            color: AppColors.danger,
            fontWeight: FontWeight.w900,
            fontSize: style == CountdownStyle.hero ? 16 : 11,
            letterSpacing: 1.0,
          ),
        ),
      );
    } else {
      switch (style) {
        case CountdownStyle.compact:
          content = Text(
            countdown.formatted,
            style: AppTypography.countdownSmall.copyWith(
              color: defaultColor,
              fontWeight: FontWeight.w800,
            ),
          );
          break;

        case CountdownStyle.hero:
          content = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (countdown.days > 0) ...[
                _buildSegment(countdown.days.toString().padLeft(2, '0'), 'DAYS', defaultColor),
                _buildColon(defaultColor),
              ],
              _buildSegment(countdown.hours.toString().padLeft(2, '0'), 'HOURS', defaultColor),
              _buildColon(defaultColor),
              _buildSegment(countdown.minutes.toString().padLeft(2, '0'), 'MIN', defaultColor),
              _buildColon(defaultColor),
              _buildSegment(countdown.seconds.toString().padLeft(2, '0'), 'SEC', defaultColor),
            ],
          );
          break;

        case CountdownStyle.detailed:
          content = Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBox(context, countdown.days.toString().padLeft(2, '0'), 'DAYS'),
              _buildBox(context, countdown.hours.toString().padLeft(2, '0'), 'HOURS'),
              _buildBox(context, countdown.minutes.toString().padLeft(2, '0'), 'MINUTES'),
              _buildBox(context, countdown.seconds.toString().padLeft(2, '0'), 'SECONDS'),
            ],
          );
          break;
      }
    }

    return Semantics(
      label: countdown.semanticLabel,
      child: content,
    );
  }

  Widget _buildColon(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        ':',
        style: AppTypography.countdownMedium.copyWith(
          color: color.withValues(alpha: 0.5),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSegment(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.countdownMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: AppTypography.badge.copyWith(
            fontSize: 9,
            color: color.withValues(alpha: 0.6),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildBox(BuildContext context, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.softWhite,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.ink,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : AppColors.ink,
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTypography.countdownMedium.copyWith(
              color: isDark ? AppColors.darkInk : AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.badge.copyWith(
              fontSize: 8,
              color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
