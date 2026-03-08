import 'package:flutter/material.dart';
import '../../core/theme/theme_ext.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double opacity;
  final double blur;
  final BoxBorder? border;
  final bool showShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 32,
    this.opacity = 0.75,
    this.blur = 12,
    this.border,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? context.surface.withOpacity(opacity) : Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (showShadow)
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.05 : 0.01),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: isDark
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border:
                      border ??
                      Border.all(
                        color: isDark
                            ? context.onSurface.withOpacity(0.06)
                            : Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (isDark ? context.onSurface : Colors.white).withOpacity(
                        isDark ? 0.05 : 0.3,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              )
            : Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}
