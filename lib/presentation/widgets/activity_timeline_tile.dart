import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/activity_entity.dart';
import '../../core/utils/activity_helper.dart';
import '../../core/theme/theme_ext.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import '../../domain/entities/entities.dart';
import 'user_profile_sheet.dart';

class ActivityTimelineTile extends StatelessWidget {
  final ActivityEntity activity;
  final String userName;
  final UserEntity? user;
  final bool isLast;

  const ActivityTimelineTile({
    super.key,
    required this.activity,
    required this.userName,
    this.user,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isComment = activity.type == ActivityType.comment;
    final formatted = ActivityHelper.formatActivity(
      activity: activity,
      isSystem: activity.userId == 'system' || activity.userId == 'Unknown',
      userName: userName,
    );

    final color = _getColor(context, activity.type);
    final icon = _getIcon(activity.type);

    return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTimelineIndicator(context, color, icon, isLast),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                        context,
                        formatted.title,
                        activity.createdAt,
                        user,
                      ),
                      const SizedBox(height: 6),
                      if (isComment)
                        _buildCommentCard(context, formatted.subtitle, color)
                      else
                        _buildSystemContent(context, formatted.subtitle, color),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, curve: Curves.easeOutCubic);
  }

  Widget _buildTimelineIndicator(
    BuildContext context,
    Color color,
    IconData icon,
    bool isLast,
  ) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: context.onSurface.withOpacity(0.04),
            shape: BoxShape.circle,
            border: Border.all(
              color: context.onSurface.withOpacity(0.08),
              width: 1.2,
            ),
          ),
          child: Center(child: Icon(icon, size: 15, color: color)),
        ),
        if (!isLast)
          Expanded(
            child: Container(
              width: 1.2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: context.onSurface.withOpacity(0.08),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String title,
    DateTime time,
    UserEntity? user,
  ) {
    final now = DateTime.now();
    String? formatedDateTime;
    if (time.day == now.day &&
        now.year == time.year &&
        now.month == time.month) {
      formatedDateTime = DateFormat('HH:mm').format(time);
    } else if (now.year == time.year) {
      formatedDateTime = DateFormat('dd/MM HH:mm').format(time);
    } else {
      formatedDateTime = DateFormat('dd/MM/yyyy HH:mm').format(time);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: user != null && activity.type == ActivityType.comment
                ? () => UserProfileSheet.show(context, user)
                : null,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: context.onSurface,
                decorationThickness: 1.5,
              ),
            ),
          ),
        ),
        Text(
          formatedDateTime,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: context.onSurface.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentCard(BuildContext context, String content, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.onSurface.withOpacity(0.04),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(
          color: context.onSurface.withOpacity(0.03),
          width: 1,
        ),
      ),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 14,
          color: context.onSurface.withOpacity(0.8),
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildSystemContent(
    BuildContext context,
    String content,
    Color color,
  ) {
    // onTap: user != null && activity.type == ActivityType.comment
    // ? () => UserProfileSheet.show(context, user)
    // : null,                decoration:
    //     user != null && activity.type == ActivityType.comment
    //     ? TextDecoration.underline
    //     : null,
    // decorationColor: context.onSurface,

    return InkWell(
      onTap: user != null ? () => UserProfileSheet.show(context, user!) : null,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.onSurface.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          content,
          style: TextStyle(
            fontSize: 12,
            color: context.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  IconData _getIcon(ActivityType type) {
    switch (type) {
      case ActivityType.comment:
        return Ionicons.chatbubble_outline;
      case ActivityType.projectCreated:
        return Ionicons.add_circle_outline;
      case ActivityType.taskCreated:
        return Ionicons.document_text_outline;
      case ActivityType.projectStatusChanged:
      case ActivityType.taskStatusChanged:
        return Ionicons.sync_outline;
      case ActivityType.projectMembersChanged:
        return Ionicons.people_outline;
      case ActivityType.taskDeadlineUpdated:
        return Ionicons.calendar_outline;
      case ActivityType.taskApproved:
        return Ionicons.checkmark_circle_outline;
      case ActivityType.taskRejected:
        return Ionicons.close_circle_outline;
      case ActivityType.requestCreated:
        return Ionicons.git_pull_request_outline;
      case ActivityType.requestApprovedStep:
        return Ionicons.checkmark_done_outline;
      case ActivityType.requestRejected:
        return Ionicons.close_circle_outline;
    }
  }

  Color _getColor(BuildContext context, ActivityType type) {
    switch (type) {
      case ActivityType.comment:
        return context.primary;
      case ActivityType.projectCreated:
      case ActivityType.taskCreated:
        return Colors.blue;
      case ActivityType.projectStatusChanged:
      case ActivityType.taskStatusChanged:
        return Colors.amber;
      case ActivityType.projectMembersChanged:
        return context.purple;
      case ActivityType.taskDeadlineUpdated:
        return Colors.deepOrange;
      case ActivityType.taskApproved:
        return Colors.green;
      case ActivityType.taskRejected:
        return Colors.blueGrey;
      case ActivityType.requestCreated:
        return Colors.blue;
      case ActivityType.requestApprovedStep:
        return Colors.green;
      case ActivityType.requestRejected:
        return Colors.red;
    }
  }
}
