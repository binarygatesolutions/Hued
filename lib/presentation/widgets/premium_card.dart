import 'package:flutter/material.dart';
import '../../core/theme/theme_ext.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/haptics_service.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;
  final bool showShadow;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = 24,
    this.backgroundColor,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? context.surface : Colors.white),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          if (!isDark && showShadow)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
        ],
        border: isDark
            ? Border.all(color: context.onSurface.withOpacity(0.08), width: 1)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap != null
                ? () {
                    HapticsService.light();
                    onTap!();
                  }
                : null,
            highlightColor: context.primary.withOpacity(0.05),
            splashColor: context.primary.withOpacity(0.1),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(20),
              child: child,
            ),
          ),
        ),
      ),
    ).animate(target: onTap != null ? 1 : 0).scale(
          begin: const Offset(1, 1),
          end: const Offset(0.98, 0.98),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
        );

    if (margin != null) {
      return Padding(padding: margin!, child: cardContent);
    }
    return cardContent;
  }
}
