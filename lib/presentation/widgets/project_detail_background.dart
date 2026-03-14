import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/theme_ext.dart';
import '../../core/utils/responsive_layout.dart';

class ProjectDetailBackground extends StatelessWidget {
  const ProjectDetailBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primary;
    final secondaryColor = context
        .purple; // Using purple as secondary color logic from original Screen

    final isLarge = ResponsiveLayout.isLargeScreen(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? Colors.black : const Color(0xFFFDFDFF),
      child: Stack(
        children: [
          Positioned(
                top: isLarge ? -150 : -100,
                right: isLarge ? -100 : -50,
                child: Container(
                  width: isLarge ? 600 : 380,
                  height: isLarge ? 600 : 380,
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
                end: Offset(isLarge ? -80 : -40, isLarge ? 100 : 60),
                duration: 10.seconds,
                curve: Curves.easeInOut,
              ),

          Positioned(
                bottom: isLarge ? -100 : 50,
                left: isLarge ? -150 : -100,
                child: Container(
                  width: isLarge ? 700 : 450,
                  height: isLarge ? 700 : 450,
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
                end: Offset(isLarge ? 100 : 60, isLarge ? -80 : -40),
                duration: 12.seconds,
                curve: Curves.easeInOut,
              ),

          Positioned(
                top: isLarge ? 300 : 200,
                left: isLarge ? 150 : 50,
                child: Container(
                  width: isLarge ? 500 : 300,
                  height: isLarge ? 500 : 300,
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
            filter: ImageFilter.blur(
              sigmaX: isLarge ? 60 : 30,
              sigmaY: isLarge ? 60 : 30,
            ),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }
}
