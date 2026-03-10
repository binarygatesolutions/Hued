import 'package:flutter/material.dart';
import 'package:hued/core/utils/font_helper.dart';
import '../../core/utils/animations.dart';
import '../../core/theme/theme_ext.dart';
import '../../domain/entities/entities.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';

class ProjectHeroSection extends StatelessWidget {
  final ProjectEntity project;
  final int completedTasks;
  final int totalApprovedTasks;
  final Map<String, UserEntity> users;

  const ProjectHeroSection({
    super.key,
    required this.project,
    required this.completedTasks,
    required this.totalApprovedTasks,
    required this.users,
  });

  String _getUserName(String id) => users[id]?.name ?? LangKeys.unknown.tr();

  @override
  Widget build(BuildContext context) {
    final progress = totalApprovedTasks > 0
        ? completedTasks / totalApprovedTasks
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (project.status == ProjectStatus.finished
                                  ? context.mintGreen
                                  : project.status == ProjectStatus.canceled
                                  ? context.error
                                  : context.secondary)
                              .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      project.status == ProjectStatus.finished
                          ? LangKeys.finished.tr().toUpperCase()
                          : project.status == ProjectStatus.canceled
                          ? LangKeys.canceled.tr().toUpperCase()
                          : LangKeys.active.tr().toUpperCase(),
                      style: TextStyle(
                        color: project.status == ProjectStatus.finished
                            ? Colors.green
                            : project.status == ProjectStatus.canceled
                            ? context.error
                            : context.secondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    project.title,
                    style: FontHelper.getTextStyle(
                      project.title,
                      style: FontHelper.getTextStyle(
                        project.title,
                        style: context.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.onSurface,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ).animateEntrance(),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${LangKeys.createdBy.tr()} ${_getUserName(project.creatorId)}',
                          style: TextStyle(
                            color: context.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '· ${DateFormat.yMMMd(context.locale.toString()).format(project.createdAt)}',
                        style: TextStyle(
                          color: context.onSurface.withOpacity(0.35),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ).animateEntrance(delayMs: 100),
                ],
              ),
            ),
            const SizedBox(width: 24),
            _buildProgressRing(context, progress).animateScale(delayMs: 200),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          project.description,
          style: FontHelper.getTextStyle(
            project.description,
            style: TextStyle(
              color: context.onSurface.withOpacity(0.6),
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ).animateEntrance(delayMs: 300),
      ],
    );
  }

  Widget _buildProgressRing(BuildContext context, double progress) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 8,
            color: context.onSurface.withOpacity(0.05),
            constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            strokeCap: StrokeCap.round,
            color: context.primary,
            constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: context.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
