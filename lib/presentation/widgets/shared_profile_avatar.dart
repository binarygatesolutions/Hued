import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/theme_ext.dart';

class SharedProfileAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final Widget? placeholder;
  final double radius;
  final bool showBorder;
  final Widget? overlay;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final File? profileImg;

  const SharedProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.placeholder,
    this.radius = 40,
    this.showBorder = true,
    this.overlay,
    this.backgroundColor,
    this.textStyle,
    this.profileImg,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        (imageUrl != null && imageUrl!.isNotEmpty) || profileImg != null;

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? context.primary.withOpacity(0.1),
      backgroundImage: hasImage
          ? profileImg != null
                ? FileImage(profileImg!)
                : CachedNetworkImageProvider(imageUrl!)
          : null,
      child: !hasImage
          ? (placeholder ??
                Icon(
                  Icons.person_rounded,
                  color: context.primary,
                  size: radius,
                ))
          : null,
    );

    if (!showBorder) {
      return _wrapWithOverlay(avatar);
    }

    return _wrapWithOverlay(
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.primary.withOpacity(0.2), width: 1),
        ),
        child: CircleAvatar(
          radius: radius + 3,
          backgroundColor: context.surface,
          child: avatar,
        ),
      ),
    );
  }

  Widget _wrapWithOverlay(Widget child) {
    if (overlay == null) return child;
    return Stack(
      children: [
        child,
        Positioned(bottom: 0, right: 0, child: overlay!),
      ],
    );
  }
}
