import 'package:flutter/material.dart';

/// Responsive layout utilities for DEADLINE
class ResponsiveUtils {
  ResponsiveUtils._();

  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1024;

  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > 800) {
      return 680;
    }
    return width;
  }

  static EdgeInsets screenPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) {
      return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);
    } else if (width > 600) {
      return const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0);
    }
    return const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0);
  }
}
