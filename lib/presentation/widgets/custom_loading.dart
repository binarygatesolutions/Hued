import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../core/theme/theme_ext.dart';

class CustomLoading extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;

  const CustomLoading({super.key, this.size = 40.0, this.color, this.message});

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? context.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // 1. Outer Soft Glow
              Container(
                    width: size * 1.5,
                    height: size * 1.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: baseColor.withOpacity(0.1),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.2, 1.2),
                    duration: 2.seconds,
                  ),

              // 2. The Animation (Staggered dots or bouncier animation)
              LoadingAnimationWidget.staggeredDotsWave(
                color: baseColor,
                size: size,
              ),

              // 3. Subtle Aura Ring
              Container(
                width: size * 1.2,
                height: size * 1.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: baseColor.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 3.seconds),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 32),
            Text(
                  message!.toUpperCase(),
                  style: TextStyle(
                    color: context.onSurface.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 1.seconds)
                .shimmer(duration: 2.seconds, color: baseColor),
          ],
        ],
      ),
    );
  }
}
