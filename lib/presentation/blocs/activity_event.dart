import 'package:equatable/equatable.dart';
import '../../domain/entities/activity_entity.dart';

abstract class ActivityEvent extends Equatable {
  const ActivityEvent();

  @override
  List<Object?> get props => [];
}

class MonitorActivities extends ActivityEvent {
  final String projectId;
  final String? taskId;

  const MonitorActivities({required this.projectId, this.taskId});

  @override
  List<Object?> get props => [projectId, taskId];
}

class ActivitiesUpdated extends ActivityEvent {
  final List<ActivityEntity> activities;

  const ActivitiesUpdated(this.activities);

  @override
  List<Object?> get props => [activities];
}
