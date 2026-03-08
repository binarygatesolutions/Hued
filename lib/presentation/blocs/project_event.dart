import 'package:equatable/equatable.dart';
import '../../domain/entities/entities.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

class CreateProject extends ProjectEvent {
  final String title;
  final String description;
  final String creatorId;

  const CreateProject({
    required this.title,
    required this.description,
    required this.creatorId,
  });

  @override
  List<Object?> get props => [title, description, creatorId];
}

class AddTask extends ProjectEvent {
  final String projectId;
  final String title;
  final String description;
  final DateTime deadline;
  final String priority;
  final bool isApproved;
  final String creatorId;

  const AddTask({
    required this.projectId,
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    required this.isApproved,
    required this.creatorId,
  });
}

class UpdateTaskStatus extends ProjectEvent {
  final String projectId;
  final String taskId;
  final String status;
  final String userId;

  const UpdateTaskStatus({
    required this.projectId,
    required this.taskId,
    required this.status,
    required this.userId,
  });
}

class ApproveTask extends ProjectEvent {
  final String projectId;
  final String taskId;
  final String userId;

  const ApproveTask({
    required this.projectId,
    required this.taskId,
    required this.userId,
  });

  @override
  List<Object?> get props => [projectId, taskId, userId];
}

class RejectTask extends ProjectEvent {
  final String projectId;
  final String taskId;
  final String userId;

  const RejectTask({
    required this.projectId,
    required this.taskId,
    required this.userId,
  });

  @override
  List<Object?> get props => [projectId, taskId, userId];
}

class UpdateTaskDeadline extends ProjectEvent {
  final String projectId;
  final String taskId;
  final DateTime deadline;
  final String userId;

  const UpdateTaskDeadline({
    required this.projectId,
    required this.taskId,
    required this.deadline,
    required this.userId,
  });

  @override
  List<Object?> get props => [projectId, taskId, deadline, userId];
}

class AddActivity extends ProjectEvent {
  final String projectId;
  final String? taskId;
  final String userId;
  final String content;
  final ActivityType type;

  const AddActivity({
    required this.projectId,
    this.taskId,
    required this.userId,
    required this.content,
    required this.type,
  });

  @override
  List<Object?> get props => [projectId, taskId, userId, content, type];
}

class UpdateProjectUsers extends ProjectEvent {
  final String projectId;
  final List<String> supervisorIds;
  final List<String> managerIds;
  final List<String> clientIds;

  const UpdateProjectUsers({
    required this.projectId,
    required this.supervisorIds,
    required this.managerIds,
    required this.clientIds,
  });

  @override
  List<Object?> get props => [projectId, supervisorIds, managerIds, clientIds];
}

class AddAttachment extends ProjectEvent {
  final String projectId;
  final String taskId;
  final String userId;
  final dynamic file;

  const AddAttachment({
    required this.projectId,
    required this.taskId,
    required this.userId,
    required this.file,
  });

  @override
  List<Object?> get props => [projectId, taskId, userId, file];
}

class UpdateProjectStatus extends ProjectEvent {
  final String projectId;
  final ProjectStatus status;
  final String userId;

  const UpdateProjectStatus({
    required this.projectId,
    required this.status,
    required this.userId,
  });

  @override
  List<Object?> get props => [projectId, status, userId];
}

class LoadTaskActivity extends ProjectEvent {
  final String projectId;
  final String taskId;
  final dynamic lastDocument;
  final bool isLoadMore;
  final int limit;

  const LoadTaskActivity({
    required this.projectId,
    required this.taskId,
    this.lastDocument,
    this.isLoadMore = false,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [
    projectId,
    taskId,
    lastDocument,
    isLoadMore,
    limit,
  ];
}

class LoadTasks extends ProjectEvent {
  final String projectId;

  const LoadTasks({required this.projectId});

  @override
  List<Object?> get props => [projectId];
}

class LoadProjectActivity extends ProjectEvent {
  final String projectId;
  final dynamic lastDocument;
  final bool isLoadMore;
  final int limit;

  const LoadProjectActivity({
    required this.projectId,
    this.lastDocument,
    this.isLoadMore = false,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [projectId, lastDocument, isLoadMore, limit];
}

class LoadProjectUsers extends ProjectEvent {
  final List<String> userIds;

  const LoadProjectUsers({required this.userIds});

  @override
  List<Object?> get props => [userIds];
}
