import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/utils/activity_helper.dart';
import '../../core/theme/theme_ext.dart';
import '../../core/utils/font_helper.dart';
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
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                        context,
                        formatted.title,
                        activity.createdAt,
                        user,
                      ),
                      const SizedBox(height: 10),
                      if (isComment)
                        _buildCommentCard(
                          context,
                          formatted.subtitle,
                          color,
                          user,
                        )
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
        .slideY(begin: 0.05, curve: Curves.easeOutCubic);
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
    String formatedDateTime;
    final locale = context.locale.toString();
    if (time.day == now.day &&
        now.year == time.year &&
        now.month == time.month) {
      formatedDateTime = DateFormat.Hm(locale).format(time);
    } else if (now.year == time.year) {
      formatedDateTime = DateFormat.MMMd(locale).add_Hm().format(time);
    } else {
      formatedDateTime = DateFormat.yMMMd(locale).add_Hm().format(time);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: InkWell(
            onTap: user != null && activity.type == ActivityType.comment
                ? () => UserProfileSheet.show(context, user)
                : null,
            borderRadius: BorderRadius.circular(4),
            child: Text(
              title,
              style: FontHelper.getTextStyle(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: context.onSurface,
                ),
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

  Widget _buildCommentCard(
    BuildContext context,
    String content,
    Color color,
    UserEntity? user,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: context.onSurface.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: context.onSurface.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: context.primary.withOpacity(0.1),
                    backgroundImage: user.profile != null
                        ? NetworkImage(user.profile!)
                        : null,
                    child: user.profile == null
                        ? Text(
                            user.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: context.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.name,
                    style: FontHelper.getTextStyle(
                      user.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: FontHelper.getTextStyle(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: context.onSurface.withOpacity(0.85),
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
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
          style: FontHelper.getTextStyle(
            content,
            style: TextStyle(
              fontSize: 12,
              color: context.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
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
