import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Screen size breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  // Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getScreenWidth(context) < mobileBreakpoint;
  }

  // Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  // Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getScreenWidth(context) >= tabletBreakpoint;
  }

  // Check if device is large mobile (bigger phones)
  static bool isLargeMobile(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= 400 && width < mobileBreakpoint;
  }

  // Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isLargeMobile(context) || isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else if (isDesktop(context)) {
      return const EdgeInsets.all(32.0);
    } else {
      return const EdgeInsets.all(16.0);
    }
  }

  // Get responsive grid count for stats
  static int getStatsGridCount(BuildContext context) {
    if (isLargeMobile(context)) {
      return 2; // 2 columns for large mobile
    } else if (isTablet(context)) {
      return 3; // 3 columns for tablet
    } else if (isDesktop(context)) {
      return 4; // 4 columns for desktop
    } else {
      return 2; // 2 columns for small mobile
    }
  }

  // Get responsive grid count for quick actions
  static int getQuickActionsGridCount(BuildContext context) {
    if (isLargeMobile(context)) {
      return 4; // 4 columns for large mobile (2x2 grid)
    } else if (isTablet(context)) {
      return 4; // 4 columns for tablet
    } else if (isDesktop(context)) {
      return 4; // 4 columns for desktop
    } else {
      return 2; // 2 columns for small mobile
    }
  }

  // Get responsive aspect ratio for cards
  static double getCardAspectRatio(BuildContext context) {
    if (isLargeMobile(context)) {
      return 1.4; // Slightly taller cards for large mobile
    } else if (isTablet(context)) {
      return 1.5;
    } else if (isDesktop(context)) {
      return 1.6;
    } else {
      return 1.3; // Compact for small mobile
    }
  }

  // Get responsive font size multiplier
  static double getFontSizeMultiplier(BuildContext context) {
    if (isLargeMobile(context)) {
      return 1.1; // Slightly larger text for large mobile
    } else if (isTablet(context)) {
      return 1.2;
    } else if (isDesktop(context)) {
      return 1.3;
    } else {
      return 1.0; // Normal size for small mobile
    }
  }

  // Get responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final multiplier = getFontSizeMultiplier(context);
    return baseSpacing * multiplier;
  }

  // Get responsive container max width
  static double getMaxContentWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (isLargeMobile(context)) {
      return screenWidth * 0.95; // Use 95% of screen width for large mobile
    } else if (isTablet(context)) {
      return 800; // Max width for tablet
    } else if (isDesktop(context)) {
      return 1200; // Max width for desktop
    } else {
      return screenWidth; // Full width for small mobile
    }
  }

  // Get responsive cross axis count for grid views
  static int getResponsiveCrossAxisCount(BuildContext context, {
    int mobile = 2,
    int largeMobile = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    if (isLargeMobile(context)) {
      return largeMobile;
    } else if (isTablet(context)) {
      return tablet;
    } else if (isDesktop(context)) {
      return desktop;
    } else {
      return mobile;
    }
  }

  // Get responsive child aspect ratio for grid views
  static double getResponsiveChildAspectRatio(BuildContext context, {
    double mobile = 1.3,
    double largeMobile = 1.4,
    double tablet = 1.5,
    double desktop = 1.6,
  }) {
    if (isLargeMobile(context)) {
      return largeMobile;
    } else if (isTablet(context)) {
      return tablet;
    } else if (isDesktop(context)) {
      return desktop;
    } else {
      return mobile;
    }
  }
}
