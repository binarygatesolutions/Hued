import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/theme_ext.dart';

class ProjectDetailBackground extends StatelessWidget {
  const ProjectDetailBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primary;
    final secondaryColor = context
        .purple; // Using purple as secondary color logic from original Screen

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? Colors.black : const Color(0xFFFDFDFF),
      child: Stack(
        children: [
          Positioned(
                top: -100,
                right: -50,
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryColor.withOpacity(isDark ? 0.15 : 0.08),
                        primaryColor.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(-40, 60),
                duration: 10.seconds,
                curve: Curves.easeInOut,
              ),

          Positioned(
                bottom: 50,
                left: -100,
                child: Container(
                  width: 450,
                  height: 450,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        secondaryColor.withOpacity(isDark ? 0.12 : 0.05),
                        secondaryColor.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(60, -40),
                duration: 12.seconds,
                curve: Curves.easeInOut,
              ),

          Positioned(
                top: 200,
                left: 50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        context.mintGreen.withOpacity(isDark ? 0.05 : 0.03),
                        context.mintGreen.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(20, 20),
                duration: 15.seconds,
                curve: Curves.easeInOut,
              ),

          // Lowered sigma for performance (from 120 to 30)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }
}
