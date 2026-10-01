import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../models/reminder_type.dart';

class ReminderOptionTile extends StatelessWidget {
  final ReminderType type;
  final bool isSelected;
  final bool isAvailable;
  final ValueChanged<bool>? onChanged;

  const ReminderOptionTile({
    super.key,
    required this.type,
    required this.isSelected,
    this.isAvailable = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = !isAvailable
        ? (isDark ? const Color(0xFF1E201E) : const Color(0xFFECE7DE))
        : isSelected
            ? (isDark ? const Color(0xFF2E241E) : const Color(0xFFFDF5EE))
            : (isDark ? AppColors.darkCard : AppColors.softWhite);

    final borderColor = !isAvailable
        ? Colors.transparent
        : isSelected
            ? AppColors.burntOrange
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    final textOpacity = isAvailable ? 1.0 : 0.45;

    final semanticsLabel =
        '${type.label} reminder, ${isSelected ? "enabled" : "disabled"}${!isAvailable ? ", unavailable for this deadline" : ""}';

    return Semantics(
      label: semanticsLabel,
      button: isAvailable,
      enabled: isAvailable,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: isAvailable && onChanged != null
                ? () => onChanged!(!isSelected)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Icon badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected && isAvailable
                          ? AppColors.burntOrange.withValues(alpha: 0.12)
                          : (isDark
                              ? const Color(0xFF282828)
                              : const Color(0xFFEBE6DC)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      type.iconEmoji,
                      style: TextStyle(
                        fontSize: 18,
                        color: isAvailable ? null : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Label and editorial description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              type.label.toUpperCase(),
                              style: AppTypography.monoMedium.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: (isDark
                                        ? AppColors.darkInk
                                        : AppColors.ink)
                                    .withValues(alpha: textOpacity),
                              ),
                            ),
                            if (!isAvailable) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'TOO CLOSE',
                                  style: AppTypography.monoSmall.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          type.description,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12,
                            color: (isDark
                                    ? AppColors.darkMuted
                                    : AppColors.mutedGrey)
                                .withValues(alpha: textOpacity),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Editorial toggle indicator
                  Switch.adaptive(
                    value: isSelected && isAvailable,
                    activeThumbColor: AppColors.burntOrange,
                    onChanged: isAvailable && onChanged != null
                        ? (val) => onChanged!(val)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
