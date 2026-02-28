import 'package:flutter/material.dart';

class Responsive {
  // Breakpoints
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1200;

  // Get screen width
  static double getWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  // Get screen height
  static double getHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Check device type
  static bool isMobile(BuildContext context) =>
      getWidth(context) < mobileMaxWidth;

  static bool isTablet(BuildContext context) =>
      getWidth(context) >= mobileMaxWidth && getWidth(context) < tabletMaxWidth;

  static bool isDesktop(BuildContext context) =>
      getWidth(context) >= tabletMaxWidth;

  // Responsive padding
  static double getPadding(BuildContext context) =>
      isMobile(context) ? 16 : 24;

  // Responsive font size
  static double getFontSize(BuildContext context, double mobileSize) =>
      isMobile(context) ? mobileSize : mobileSize * 1.2;

  // Responsive button height
  static double getButtonHeight(BuildContext context) =>
      isMobile(context) ? 50 : 60;

  // QR Frame size based on screen
  static double getQrFrameSize(BuildContext context) {
    final width = getWidth(context);
    final height = getHeight(context);
    final shorterSide = width < height ? width : height;
    return (shorterSide * 0.65).clamp(200.0, 350.0);
  }

  // Card border radius
  static double getBorderRadius(BuildContext context) =>
      isMobile(context) ? 20 : 28;
}