import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../core/theme/theme_ext.dart';
import '../../domain/entities/entities.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';
import 'premium_card.dart';

class TaskCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onTap;
  final Map<String, UserEntity> users;
  final bool isMyWorkerAssigned;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.users,
    this.isMyWorkerAssigned = false,
  });

  String _getDeadlineDifference(DateTime deadline, DateTime? completedAt) {
    if (completedAt == null) return '';
    final diff = completedAt.difference(deadline);
    if (diff.inDays.abs() > 0) {
      return '${diff.inDays.abs()} ${LangKeys.days.tr()}';
    } else if (diff.inHours.abs() > 0) {
      return '${diff.inHours.abs()} ${LangKeys.hours.tr()}';
    } else {
      return '${diff.inMinutes.abs()} ${LangKeys.minutes.tr()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(task.status, context);
    final isCompleted = task.status == TaskStatus.completed;
    final isEarly =
        isCompleted &&
        task.completedAt != null &&
        task.completedAt!.isBefore(task.deadline);

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 16),
      borderRadius: 24,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Opacity(
        opacity: task.isApproved ? 1.0 : 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!task.isApproved)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            context.primary, // Using solid primary for contrast
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: context.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Ionicons.alert_circle,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            LangKeys.waitingApproval.tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _getStatusIcon(task.status),
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: context.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.onSurface.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '#${task.id.length > 6 ? task.id.substring(0, 6) : task.id}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                      color: context.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              task.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.onSurfaceVariant.withOpacity(
                                  0.8,
                                ),
                                height: 1.3,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: context.onSurface.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Ionicons.calendar_outline,
                              size: 14,
                              color: context.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat.yMMMd(
                                context.locale.toString(),
                              ).format(task.deadline),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: context.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildPriorityTag(task.priority, context),
                      const Spacer(),
                      if (isCompleted && task.completedAt != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isEarly
                                ? context.mintGreen.withOpacity(0.15)
                                : context.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isEarly
                                  ? context.mintGreen.withOpacity(0.3)
                                  : context.error.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isEarly
                                    ? Ionicons.checkmark_circle
                                    : Ionicons.warning,
                                color: isEarly
                                    ? context.mintGreen
                                    : context.error,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${isEarly ? LangKeys.early.tr() : LangKeys.late.tr()} ${_getDeadlineDifference(task.deadline, task.completedAt)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isEarly
                                      ? context.mintGreen
                                      : context.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: context.onSurface.withOpacity(0.05),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Stacked worker avatars
                      if (task.assignedWorkerIds.isNotEmpty)
                        _buildWorkerAvatars(context)
                      else
                        Text(
                          LangKeys.unknown.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: context.onSurface.withOpacity(0.4),
                          ),
                        ),
                      const Spacer(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerAvatars(BuildContext context) {
    const double radius = 12;
    const double overlap = 8;
    const int maxVisible = 4;

    final workerIds = task.assignedWorkerIds;
    final visibleCount = workerIds.length > maxVisible
        ? maxVisible
        : workerIds.length;
    final overflowCount = workerIds.length - visibleCount;

    // Palette for distinctly colored initials circles
    final palette = [
      context.primary,
      context.purple,
      context.mintGreen,
      context.secondary,
    ];

    final double totalWidth =
        (radius * 2) +
        (visibleCount - 1) * (radius * 2 - overlap) +
        (overflowCount > 0 ? (radius * 2 - overlap) : 0);

    return SizedBox(
      width: totalWidth,
      height: radius * 2,
      child: Stack(
        children: [
          for (int i = 0; i < visibleCount; i++)
            Builder(
              builder: (context) {
                final hasId = i < task.assignedWorkerIds.length;
                final workerId = hasId ? task.assignedWorkerIds[i] : null;
                final worker = workerId != null ? users[workerId] : null;
                final profileUrl = worker?.profile;
                final name = worker?.name ?? '';

                return Positioned(
                  left: i * (radius * 2 - overlap),
                  child: Container(
                    width: radius * 2,
                    height: radius * 2,
                    decoration: BoxDecoration(
                      color: palette[i % palette.length].withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: context.surface, width: 1.5),
                      image: profileUrl != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(profileUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: profileUrl == null
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: palette[i % palette.length],
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          if (overflowCount > 0)
            Positioned(
              left: visibleCount * (radius * 2 - overlap),
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  color: context.onSurface.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: context.surface, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$overflowCount',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: context.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return Ionicons.checkmark_done_outline;
      case TaskStatus.inProgress:
        return Ionicons.play_outline;
      case TaskStatus.cancelled:
        return Ionicons.close_outline;
      case TaskStatus.pending:
        return Ionicons.time_outline;
    }
  }

  Color _getStatusColor(TaskStatus status, BuildContext context) {
    switch (status) {
      case TaskStatus.completed:
        return Colors.green.shade800;
      case TaskStatus.inProgress:
        return context.primary;
      case TaskStatus.cancelled:
        return context.error;
      case TaskStatus.pending:
        return context.purple;
    }
  }

  Widget _buildPriorityTag(TaskPriority priority, BuildContext context) {
    final color = _getPriorityColor(priority, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15), // Increased opacity slightly
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        priority.name.tr().toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color, // Solid color for the text
          fontWeight: FontWeight.w800, // Thicker font
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority, BuildContext context) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.orange.shade800; // Darker orange for better contrast
      case TaskPriority.medium:
        return context.purple;
      case TaskPriority.low:
        return Colors.green.shade800;
      case TaskPriority.urgent:
        return context.error;
    }
  }
}
