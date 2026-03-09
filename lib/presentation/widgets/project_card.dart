import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../core/theme/theme_ext.dart';
import '../../domain/entities/entities.dart';
import 'premium_card.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';

class ProjectCard extends StatelessWidget {
  final ProjectEntity project;
  final VoidCallback onTap;
  final Widget? trailing;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = project.status == ProjectStatus.finished
        ? Colors.green
        : project.status == ProjectStatus.canceled
        ? context.error
        : project.status == ProjectStatus.archived
        ? context.onSurface.withOpacity(0.4)
        : context.secondary;

    return PremiumCard(
      borderRadius: 32,
      padding: const EdgeInsets.all(28.0),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              project.title,
                              style: context.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (trailing != null) ...[
                            const SizedBox(width: 8),
                            trailing!,
                          ] else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                project.status == ProjectStatus.finished
                                    ? LangKeys.finished.tr()
                                    : project.status == ProjectStatus.canceled
                                    ? LangKeys.canceled.tr()
                                    : project.status == ProjectStatus.archived
                                    ? LangKeys.archived.tr()
                                    : LangKeys.active.tr(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: statusColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        project.description,
                        style: TextStyle(
                          color: context.onSurface.withOpacity(0.55),
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              FutureBuilder<AggregateQuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('projects')
                    .doc(project.id)
                    .collection('tasks')
                    .where('isApproved', isEqualTo: true)
                    .count()
                    .get(),
                builder: (context, snapshot) {
                  int count = snapshot.data?.count ?? 0;

                  return _buildStat(
                    context,
                    Ionicons.layers_outline,
                    '$count ${LangKeys.tasksLabel.tr()}',
                    context.purple,
                  );
                },
              ),
              const SizedBox(width: 24),
              _buildStat(
                context,
                Ionicons.people_outline,
                '${project.assignedUserIds.length} ${LangKeys.users.tr()}',
                context.mintGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: context.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
