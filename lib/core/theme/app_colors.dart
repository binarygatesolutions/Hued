import 'package:flutter/material.dart';

class AppColors {
  // Brand identity from livehued.com
  static const Color primary = Color(0xFFEE2737);
  // Note: For dynamic mintGreen based on theme, use context.mintGreen.
  static const Color mintGreen = Color(0xFF6EFE99);
  static const Color mintGreenLight = Colors.green;
  static const Color limeYellow = Color(0xFFE9E141);
  static const Color purple = Color(0xFF7B2CBF);

  // Dark Mode - Deep & Premium
  static const Color backgroundDark = Color(0xFF030303);
  static const Color surfaceDark = Color(0xFF0F0F0F);
  static const Color cardDark = Color(0xFF141414);
  static const Color textPrimaryDark = Color(0xFFF2F2F2);
  static const Color textSecondaryDark = Color(0xFF8E8E93);
  static const Color dividerDark = Color(0xFF1C1C1E);
  static const Color glowDark = Color(0x4DEE2737);

  // Light Mode - Crisp & Clean
  static const Color backgroundLight = Color(0xFFF2F2F7);
  static const Color surfaceLight = Colors.white;
  static const Color cardLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondaryLight = Color(0xFF8E8E93);
  static const Color dividerLight = Color(0xFFE5E5EA);
  static const Color glowLight = Color(0x33EE2737);

  static const Color error = Color(0xFFFF453A);
}

class AppTextStyles {
  // We'll use these in the theme
  static TextStyle getDisplayLarge(Color color, String fontFamily) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.1,
    color: color,
  );

  static TextStyle getTitleLarge(Color color, String fontFamily) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: color,
  );

  static TextStyle getBodyLarge(Color color, String fontFamily) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle getBodyMedium(Color color, String fontFamily) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: color,
  );

  static TextStyle getLabelMedium(Color color, String fontFamily) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: color,
  );
}

class AppSpacing {
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;

  static const double radiusS = 12.0;
  static const double radiusM = 20.0;
  static const double radiusL = 28.0;
  static const double radiusXL = 40.0;
}
