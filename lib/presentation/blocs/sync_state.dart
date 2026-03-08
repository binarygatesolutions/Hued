import 'package:equatable/equatable.dart';
import '../../domain/entities/entities.dart';

abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {}

class ProjectSynced extends SyncState {
  final ProjectEntity project;
  const ProjectSynced(this.project);

  @override
  List<Object?> get props => [project];
}

class TaskSynced extends SyncState {
  final TaskEntity task;
  const TaskSynced(this.task);

  @override
  List<Object?> get props => [task];
}

class SyncError extends SyncState {
  final String message;
  const SyncError(this.message);

  @override
  List<Object?> get props => [message];
}
