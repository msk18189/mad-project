import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_radius.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_typography.dart';

class EmptyStateView extends StatelessWidget {
  final String title;
  final String message;
  final String? subMessage;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.subMessage,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  factory EmptyStateView.nothingOnTheClock({VoidCallback? onAdd}) {
    return EmptyStateView.clearClock(onAdd: onAdd);
  }

  factory EmptyStateView.clearClock({VoidCallback? onAdd}) {
    return EmptyStateView(
      title: 'CLEAR CLOCK',
      message: 'Nothing is chasing you.\nFor now.',
      actionLabel: '+ ADD DEADLINE',
      onAction: onAdd,
      icon: Icons.timer_off_outlined,
    );
  }

  const EmptyStateView.loading({super.key})
      : title = 'CHECKING THE CLOCK...',
        message = 'Loading your stored deadlines from local vault.',
        subMessage = null,
        actionLabel = null,
        onAction = null,
        icon = Icons.hourglass_top_rounded;

  factory EmptyStateView.error({
    String message = "We couldn't load your deadlines.",
    VoidCallback? onRetry,
  }) {
    return EmptyStateView(
      title: 'Something went wrong.',
      message: message,
      actionLabel: onRetry != null ? 'Try Again' : null,
      onAction: onRetry,
      icon: Icons.error_outline_rounded,
    );
  }

  factory EmptyStateView.allClear({VoidCallback? onAdd}) {
    return EmptyStateView(
      title: 'ALL CLEAR',
      message: "You've cleared the board.\nEnjoy the quiet.",
      actionLabel: '+ ADD DEADLINE',
      onAction: onAdd,
      icon: Icons.check_circle_outline_rounded,
    );
  }

  factory EmptyStateView.missedOnly({required int count, VoidCallback? onAdd}) {
    return EmptyStateView(
      title: 'THE CLOCK WON',
      message: '$count ${count == 1 ? "deadline" : "deadlines"} passed.\nYou can still get the next one.',
      actionLabel: '+ ADD DEADLINE',
      onAction: onAdd,
      icon: Icons.history_toggle_off_rounded,
    );
  }

  factory EmptyStateView.noDeadlines({VoidCallback? onAdd}) {
    return EmptyStateView.clearClock(onAdd: onAdd);
  }

  factory EmptyStateView.noCompleted() {
    return const EmptyStateView(
      title: 'NOTHING COMPLETED YET',
      message: 'Finish your first deadline\nand it will appear here.',
      subMessage: 'Your first victory is waiting.',
      icon: Icons.military_tech_outlined,
    );
  }

  factory EmptyStateView.noMissed() {
    return const EmptyStateView(
      title: 'NO MISSED DEADLINES',
      message: 'Keep it that way.',
      subMessage: 'Flawless time management.',
      icon: Icons.verified_outlined,
    );
  }

  factory EmptyStateView.noSearchResults({String? query, VoidCallback? onClear}) {
    return EmptyStateView(
      title: 'NOTHING FOUND',
      message: query != null && query.isNotEmpty
          ? 'No deadlines match "$query".'
          : 'Try another search or reset filters.',
      subMessage: 'Try another search.',
      actionLabel: onClear != null ? 'CLEAR SEARCH' : null,
      onAction: onClear,
      icon: Icons.search_off_rounded,
    );
  }

  factory EmptyStateView.noFilterMatches({VoidCallback? onReset}) {
    return EmptyStateView(
      title: 'NO MATCHES',
      message: 'No deadlines match these filters.',
      subMessage: 'Try adjusting or clearing your filters.',
      actionLabel: onReset != null ? 'RESET FILTERS' : null,
      onAction: onReset,
      icon: Icons.filter_alt_off_outlined,
    );
  }

  factory EmptyStateView.noCalendarDeadlines() {
    return const EmptyStateView(
      title: 'NOTHING DUE',
      message: 'No deadlines on this date.',
      subMessage: 'Enjoy the breathing room.',
      icon: Icons.event_available_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: AppSpacing.edgeInsetsXxl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.softWhite,
            borderRadius: AppRadius.radiusLg,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.ink,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black54 : AppColors.ink,
                offset: const Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 48,
                  color: isDark ? AppColors.darkAccent : AppColors.burntOrange,
                ),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(
                  letterSpacing: 1.0,
                  color: isDark ? AppColors.darkInk : AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkMuted : AppColors.mutedGrey,
                ),
              ),
              if (subMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  subMessage!,
                  textAlign: TextAlign.center,
                  style: AppTypography.handwritten.copyWith(
                    fontSize: 18,
                    color: isDark ? AppColors.darkAccent : AppColors.burntOrange,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
