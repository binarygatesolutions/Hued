import 'package:flutter/material.dart';
import '../../core/theme/theme_ext.dart';

class ProjectSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Color color;
  final IconData? icon;
  final Widget? trailing;

  const ProjectSectionHeader({
    super.key,
    required this.title,
    this.count,
    required this.color,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        if (icon != null) const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: context.onSurface,
          ),
        ),
        const SizedBox(width: 12),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}
