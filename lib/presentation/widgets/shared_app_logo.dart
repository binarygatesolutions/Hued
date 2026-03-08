import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/theme_ext.dart';

class SharedAppLogo extends StatelessWidget {
  final double height;
  final Color? color;
  final String? heroTag;

  const SharedAppLogo({super.key, this.height = 40, this.color, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final logo = SvgPicture.asset(
      'assets/brand/full-logo.svg',
      height: height,
      colorFilter: ColorFilter.mode(color ?? context.primary, BlendMode.srcIn),
    );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: logo);
    }

    return logo;
  }
}
