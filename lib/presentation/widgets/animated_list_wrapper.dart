import 'package:flutter/material.dart';
import '../../core/utils/animations.dart';

class AnimatedListWrapper extends StatelessWidget {
  final int index;
  final Widget child;
  final int baseDelayMs;

  const AnimatedListWrapper({
    super.key,
    required this.index,
    required this.child,
    this.baseDelayMs = 0,
  });

  @override
  Widget build(BuildContext context) {
    return child.animateListStep(index: index, baseDelayMs: baseDelayMs);
  }
}
