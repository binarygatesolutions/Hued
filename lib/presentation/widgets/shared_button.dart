import 'package:flutter/material.dart';
import '../../core/theme/theme_ext.dart';

class SharedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Widget? icon;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final double elevation;
  final TextStyle? textStyle;
  final bool isLoading;
  final bool showShadow;
  final EdgeInsetsGeometry? padding;
  final bool disabled;

  const SharedButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.width = double.infinity,
    this.height = 56,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.borderRadius = 16,
    this.elevation = 0,
    this.textStyle,
    this.isLoading = false,
    this.showShadow = false,
    this.disabled = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = disabled
        ? Colors.grey
        : (backgroundColor ?? context.primary);

    Widget button = ElevatedButton(
      onPressed: isLoading || disabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        enabledMouseCursor: SystemMouseCursors.click,
        backgroundColor: showShadow ? Colors.transparent : bgColor,
        shadowColor: showShadow
            ? Colors.transparent
            : (elevation == 0 ? Colors.transparent : null),
        elevation: showShadow ? 0 : elevation,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        disabledBackgroundColor: bgColor.withOpacity(0.5),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: width == double.infinity
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              children: [
                if (icon != null) ...[icon!, const SizedBox(width: 8)],
                Text(
                  text,
                  style:
                      textStyle ??
                      context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: textColor,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );

    if (showShadow) {
      button = Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: button,
      );
    } else {
      if (width == null) {
        button = SizedBox(height: height, child: button);
      } else {
        button = SizedBox(width: width, height: height, child: button);
      }
    }

    return button;
  }
}
