import 'package:flutter/material.dart';

/// Centralized responsive helpers for layout spacing and breakpoints.
class Responsive {
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isMobile(BuildContext context) {
    return screenWidth(context) < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= 600 && width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= 1200;
  }

  static double getResponsiveWidth(
    BuildContext context, {
    double mobile = 1.0,
    double tablet = 0.8,
    double desktop = 0.6,
  }) {
    if (isMobile(context)) {
      return screenWidth(context) * mobile;
    } else if (isTablet(context)) {
      return screenWidth(context) * tablet;
    } else {
      return screenWidth(context) * desktop;
    }
  }

  static double getPadding(BuildContext context) {
    if (isMobile(context)) {
      return 16.0;
    } else if (isTablet(context)) {
      return 24.0;
    } else {
      return 32.0;
    }
  }
}
