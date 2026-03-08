import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../core/utils/animations.dart';
import '../../core/theme/theme_ext.dart';
import 'premium_card.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';

class ProjectStatsRow extends StatelessWidget {
  final int totalTasks;
  final int activeTasks;
  final int doneTasks;

  const ProjectStatsRow({
    super.key,
    required this.totalTasks,
    required this.activeTasks,
    required this.doneTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatMiniCard(
            context,
            LangKeys.totalTasks.tr(),
            '$totalTasks',
            Ionicons.layers_outline,
            context.primary,
          ).animateScale(delayMs: 400),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatMiniCard(
            context,
            LangKeys.active.tr(),
            '$activeTasks',
            Ionicons.time_outline,
            context.purple,
          ).animateScale(delayMs: 500),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatMiniCard(
            context,
            LangKeys.done.tr(),
            '$doneTasks',
            Ionicons.checkmark_circle_outline,
            context.mintGreen,
          ).animateScale(delayMs: 600),
        ),
      ],
    );
  }

  Widget _buildStatMiniCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: context.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: context.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
