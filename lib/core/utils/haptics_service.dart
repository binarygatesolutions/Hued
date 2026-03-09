import 'package:flutter/services.dart';

/// Centralized service for haptic feedback to provide a premium tactile feel.
class HapticsService {
  /// Light tap for subtle feedback (e.g., small button press)
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium tap for standard actions (e.g., menu items)
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy tap for important actions (e.g., successful submission)
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Double tap pattern for alerts or errors
  static Future<void> alert() async {
    await HapticFeedback.vibrate();
  }

  /// Selection change feedback (e.g., picker scroll)
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }
}
