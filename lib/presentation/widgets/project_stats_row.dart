import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hued/domain/entities/entities.dart';
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
  final ProjectEntity project;

  const ProjectStatsRow({
    super.key,
    required this.totalTasks,
    required this.activeTasks,
    required this.doneTasks,
    required this.project,
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
    return InkWell(
      onTap: () => context.push('/project/${project.id}/tasks', extra: project),
      borderRadius: BorderRadius.circular(28),
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        borderRadius: 28,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: context.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                color: context.onSurface.withOpacity(0.4),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
