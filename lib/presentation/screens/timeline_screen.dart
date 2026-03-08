import 'package:flutter/material.dart';
import 'package:firebase_pagination/firebase_pagination.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/activity_model.dart';
import '../blocs/project_bloc.dart';
import '../blocs/project_state.dart';
import '../widgets/activity_timeline_tile.dart';
import '../../core/theme/theme_ext.dart';
import '../../domain/entities/entities.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';

class TimelineScreen extends StatelessWidget {
  final String projectId;
  final String? taskId;
  final String? title;

  const TimelineScreen({
    Key? key,
    required this.projectId,
    this.taskId,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Query query = taskId != null
        ? FirebaseFirestore.instance
              .collection('projects')
              .doc(projectId)
              .collection('tasks')
              .doc(taskId)
              .collection('activities')
              .orderBy('createdAt', descending: true)
        : FirebaseFirestore.instance
              .collection('projects')
              .doc(projectId)
              .collection('activities')
              .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title ??
              (taskId != null
                  ? LangKeys.taskTimeline.tr()
                  : LangKeys.projectTimeline.tr()),
          style: TextStyle(
            color: context.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<ProjectBloc, ProjectState>(
        builder: (context, state) {
          final users = <String, UserEntity>{};

          return FirestorePagination(
            query: query,
            limit: 20,
            viewType: ViewType.list,
            padding: const EdgeInsets.all(24),
            itemBuilder: (context, documentSnapshots, index) {
              final snapshot =
                  documentSnapshots[index]
                      as DocumentSnapshot<Map<String, dynamic>>;
              final data = snapshot.data() ?? {};
              final activity = ActivityModel.fromFirestore(data, snapshot.id);

              return ActivityTimelineTile(
                activity: activity,
                userName:
                    activity.userId == 'Unknown' || activity.userId == 'system'
                    ? LangKeys.system.tr()
                    : users[activity.userId]?.name ??
                          'User #${activity.userId.substring(0, 4)}',
                user: users[activity.userId],
                isLast: index == documentSnapshots.length - 1,
              );
            },
          );
        },
      ),
    );
  }
}
