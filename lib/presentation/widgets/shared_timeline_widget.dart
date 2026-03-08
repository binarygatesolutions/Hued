import 'package:flutter/material.dart';
import '../../domain/entities/entities.dart';
import '../../core/theme/theme_ext.dart';
import './activity_timeline_tile.dart';
import '../blocs/project_bloc.dart';
import '../blocs/project_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SharedTimelineWidget extends StatelessWidget {
  final List<ActivityEntity> activities;
  final VoidCallback onViewAll;
  final String title;
  final Color? color;
  final Map<String, UserEntity> users;

  const SharedTimelineWidget({
    super.key,
    required this.activities,
    required this.onViewAll,
    this.title = 'Timeline',
    this.color,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    final displayItems = activities.take(5).toList();
    if (displayItems.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: context.onSurface,
              ),
            ),
            if (activities.length > 5)
              TextButton.icon(
                onPressed: onViewAll,
                label: Row(
                  children: [
                    Text(
                      'VIEW ALL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 12),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 20),

        BlocBuilder<ProjectBloc, ProjectState>(
          builder: (context, state) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayItems.length,
              itemBuilder: (context, index) {
                final activity = displayItems[index];
                return ActivityTimelineTile(
                  activity: activity,
                  userName:
                      activity.userId == 'system' ||
                          activity.userId == 'Unknown'
                      ? 'System'
                      : users[activity.userId]?.name ??
                            'User #${activity.userId.length > 4 ? activity.userId.substring(0, 4) : activity.userId}',
                  user: users[activity.userId],
                  isLast: index == displayItems.length - 1,
                );
              },
            );
          },
        ),
      ],
    );
  }
}
