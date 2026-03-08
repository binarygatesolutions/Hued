import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static String getFontFamily(String languageCode) {
    if (languageCode == 'ar') {
      return GoogleFonts.cairo().fontFamily ?? 'Cairo';
    }
    return GoogleFonts.plusJakartaSans().fontFamily ?? 'Plus Jakarta Sans';
  }

  static ThemeData getDarkTheme(String languageCode) {
    final fontFamily = getFontFamily(languageCode);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      dividerColor: AppColors.dividerDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.mintGreen,
        tertiary: AppColors.purple,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        onSurfaceVariant: AppColors.textSecondaryDark,
        background: AppColors.backgroundDark,
        onBackground: AppColors.textPrimaryDark,
        error: AppColors.error,
      ),
      fontFamily: fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.getDisplayLarge(
          AppColors.textPrimaryDark,
          fontFamily,
        ),
        titleLarge: AppTextStyles.getTitleLarge(
          AppColors.textPrimaryDark,
          fontFamily,
        ),
        bodyLarge: AppTextStyles.getBodyLarge(
          AppColors.textPrimaryDark,
          fontFamily,
        ),
        bodyMedium: AppTextStyles.getBodyMedium(
          AppColors.textPrimaryDark,
          fontFamily,
        ),
        labelMedium: AppTextStyles.getLabelMedium(
          AppColors.textSecondaryDark,
          fontFamily,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.backgroundDark,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        AppColors.surfaceDark,
        AppColors.textSecondaryDark,
        true,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(),
    );
  }

  static ThemeData getLightTheme(String languageCode) {
    final fontFamily = getFontFamily(languageCode);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      dividerColor: AppColors.dividerLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.purple,
        tertiary: AppColors.mintGreen,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        onSurfaceVariant: AppColors.textSecondaryLight,
        background: AppColors.backgroundLight,
        onBackground: AppColors.textPrimaryLight,
        error: AppColors.error,
      ),
      fontFamily: fontFamily,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.getDisplayLarge(
          AppColors.textPrimaryLight,
          fontFamily,
        ),
        titleLarge: AppTextStyles.getTitleLarge(
          AppColors.textPrimaryLight,
          fontFamily,
        ),
        bodyLarge: AppTextStyles.getBodyLarge(
          AppColors.textPrimaryLight,
          fontFamily,
        ),
        bodyMedium: AppTextStyles.getBodyMedium(
          AppColors.textPrimaryLight,
          fontFamily,
        ),
        labelMedium: AppTextStyles.getLabelMedium(
          AppColors.textSecondaryLight,
          fontFamily,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.backgroundLight,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryLight,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.04),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        Colors.white,
        AppColors.textSecondaryLight,
        false,
      ),
      elevatedButtonTheme: _elevatedButtonTheme(),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(
    Color fillColor,
    Color textColor,
    bool isDark,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: isDark
            ? BorderSide(color: textColor.withOpacity(0.1))
            : BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: isDark
            ? BorderSide(color: textColor.withOpacity(0.1))
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: TextStyle(
        color: textColor.withOpacity(0.8),
        fontWeight: FontWeight.w400,
      ),
      hintStyle: TextStyle(
        color: textColor.withOpacity(0.4),
        fontWeight: FontWeight.w300,
      ),
      prefixIconColor: textColor.withOpacity(0.5),
      suffixIconColor: textColor.withOpacity(0.5),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 64),
        elevation: 10,
        shadowColor: AppColors.primary.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
      ),
    );
  }
}
