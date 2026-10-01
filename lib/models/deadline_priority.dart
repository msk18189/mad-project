import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum DeadlinePriority {
  low,
  medium,
  high;

  int get weight => DeadlinePriorityConfig.from(this).weight;
  String get label => DeadlinePriorityConfig.from(this).label;
  Color get color => DeadlinePriorityConfig.from(this).color;
  Color get textColor => DeadlinePriorityConfig.from(this).textColor;
  String get description => DeadlinePriorityConfig.from(this).description;

  static DeadlinePriority fromString(String? val) {
    if (val == null) return DeadlinePriority.medium;
    return DeadlinePriority.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => DeadlinePriority.medium,
    );
  }
}

class DeadlinePriorityConfig {
  final DeadlinePriority priority;
  final String label;
  final Color color;
  final Color textColor;
  final int weight;
  final String description;

  const DeadlinePriorityConfig({
    required this.priority,
    required this.label,
    required this.color,
    required this.textColor,
    required this.weight,
    required this.description,
  });

  static DeadlinePriorityConfig from(DeadlinePriority priority) {
    switch (priority) {
      case DeadlinePriority.low:
        return const DeadlinePriorityConfig(
          priority: DeadlinePriority.low,
          label: 'LOW',
          color: AppColors.priorityLow,
          textColor: Colors.white,
          weight: 1,
          description: 'Standard timeframe with low urgency.',
        );
      case DeadlinePriority.medium:
        return const DeadlinePriorityConfig(
          priority: DeadlinePriority.medium,
          label: 'MEDIUM',
          color: AppColors.priorityMedium,
          textColor: AppColors.ink,
          weight: 2,
          description: 'Moderate importance requiring timely progress.',
        );
      case DeadlinePriority.high:
        return const DeadlinePriorityConfig(
          priority: DeadlinePriority.high,
          label: 'HIGH',
          color: AppColors.priorityHigh,
          textColor: Colors.white,
          weight: 3,
          description: 'High stakes or imminent completion required.',
        );
    }
  }
}
