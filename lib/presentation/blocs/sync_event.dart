import 'package:equatable/equatable.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class MonitorProject extends SyncEvent {
  final String projectId;
  const MonitorProject(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class MonitorTask extends SyncEvent {
  final String projectId;
  final String taskId;
  const MonitorTask(this.projectId, this.taskId);

  @override
  List<Object?> get props => [projectId, taskId];
}
