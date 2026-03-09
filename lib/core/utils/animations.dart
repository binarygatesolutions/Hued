import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Centralized animation constants and presets for a premium feel.
class AppAnimations {
  // Durations
  static const Duration fast = Duration(milliseconds: 300);
  static const Duration normal = Duration(milliseconds: 600);
  static const Duration slow = Duration(milliseconds: 900);

  // Curves
  static const Curve primaryCurve = Curves.easeOutCubic;
  static const Curve entranceCurve = Curves.easeOutBack;
  static const Curve smoothCurve = Curves.easeOutExpo;

  // Stagger constants
  static const Duration staggerDelay = Duration(milliseconds: 50);
}

extension AppAnimationExtensions on Widget {
  /// Standard entrance animation for screens and major components.
  /// Smoothly fades in and slides up slightly with a back-out elastic effect.
  Widget animateEntrance({int delayMs = 0}) {
    return this
        .animate(delay: delayMs.ms)
        .fadeIn(
          duration: AppAnimations.normal,
          curve: AppAnimations.smoothCurve,
        )
        .slideY(
          begin: 0.1,
          end: 0,
          duration: AppAnimations.normal,
          curve: AppAnimations.entranceCurve,
        );
  }

  /// Subtle scale and fade for cards and buttons.
  Widget animateScale({int delayMs = 0}) {
    return this
        .animate(delay: delayMs.ms)
        .fadeIn(duration: AppAnimations.fast)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: AppAnimations.fast,
          curve: AppAnimations.entranceCurve,
        );
  }

  /// Staggered entrance for list items.
  Widget animateListStep({required int index, int baseDelayMs = 0}) {
    // Limits the delay so long lists don't take forever to show up
    final effectiveDelay = baseDelayMs + (50 * (index % 12));

    return this
        .animate(delay: effectiveDelay.ms)
        .fadeIn(
          duration: AppAnimations.normal,
          curve: AppAnimations.smoothCurve,
        )
        .slideY(
          begin: 0.05,
          end: 0,
          duration: AppAnimations.normal,
          curve: AppAnimations.primaryCurve,
        );
  }

  /// Premium fade animation.
  Widget animateFade({int delayMs = 0}) {
    return this
        .animate(delay: delayMs.ms)
        .fadeIn(
          duration: AppAnimations.normal,
          curve: AppAnimations.smoothCurve,
        );
  }
}
