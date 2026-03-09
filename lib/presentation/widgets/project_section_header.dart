import 'package:flutter/material.dart';
import '../../core/theme/theme_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';

class ProjectSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Color color;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onViewAll;

  const ProjectSectionHeader({
    super.key,
    required this.title,
    this.count,
    required this.color,
    this.icon,
    this.trailing,
    this.onViewAll,
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
        if (onViewAll != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                LangKeys.viewAll.tr(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
