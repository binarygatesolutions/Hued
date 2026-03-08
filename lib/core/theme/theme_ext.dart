import 'package:flutter/material.dart';

extension ThemeExt on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  Color get primary => colorScheme.primary;
  Color get onPrimary => colorScheme.onPrimary;
  Color get secondary => colorScheme.secondary;
  Color get onSecondary => colorScheme.onSecondary;
  Color get surface => colorScheme.surface;
  Color get onSurface => colorScheme.onSurface;
  Color get onSurfaceVariant => colorScheme.onSurfaceVariant;
  Color get background => colorScheme.background;
  Color get onBackground => colorScheme.onBackground;
  Color get error => colorScheme.error;
  Color get onError => colorScheme.onError;

  // Custom Color Helpers
  Color get cardColor => theme.cardTheme.color ?? surface;
  Color get dividerColor => theme.dividerColor;

  // Brand Colors
  Color get mintGreen => const Color(0xFF6EFE99);
  Color get limeYellow => const Color(0xFFE9E141);
  Color get purple => const Color(0xFF7B2CBF);
}
