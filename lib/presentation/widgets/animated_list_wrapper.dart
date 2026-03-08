import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedListWrapper extends StatelessWidget {
  final int index;
  final Widget child;

  const AnimatedListWrapper({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Limits the delay so long lists don't take forever to show up
    final currentDelay = (50 * (index % 15)).ms;

    return child
        .animate(delay: currentDelay)
        .fade(duration: 400.ms, curve: Curves.easeOut)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
