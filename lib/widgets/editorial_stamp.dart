import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';

enum StampType {
  done,
  missed,
  urgent,
  dueSoon,
  onRadar;

  String get label {
    switch (this) {
      case StampType.done:
        return 'COMPLETED';
      case StampType.missed:
        return 'DEADLINE MISSED';
      case StampType.urgent:
        return 'TIME RUNNING OUT';
      case StampType.dueSoon:
        return 'DUE SOON';
      case StampType.onRadar:
        return 'ON YOUR RADAR';
    }
  }

  Color get color {
    switch (this) {
      case StampType.done:
        return AppColors.oliveGreen;
      case StampType.missed:
        return AppColors.danger;
      case StampType.urgent:
        return AppColors.burntOrange;
      case StampType.dueSoon:
        return AppColors.warning;
      case StampType.onRadar:
        return AppColors.petrolBlue;
    }
  }

  double get angle {
    switch (this) {
      case StampType.done:
        return -0.08;
      case StampType.missed:
        return 0.10;
      case StampType.urgent:
        return -0.05;
      case StampType.dueSoon:
        return 0.04;
      case StampType.onRadar:
        return -0.03;
    }
  }
}

class EditorialStamp extends StatelessWidget {
  final StampType type;
  final String? customText;

  const EditorialStamp({
    super.key,
    required this.type,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    final color = type.color;
    final text = customText ?? type.label;

    return Transform.rotate(
      angle: type.angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: AppTypography.stamp.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
