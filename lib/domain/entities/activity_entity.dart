import 'package:equatable/equatable.dart';

enum ActivityType {
  comment,
  projectCreated,
  projectStatusChanged,
  projectMembersChanged,
  taskCreated,
  taskStatusChanged,
  taskDeadlineUpdated,
  taskApproved,
  taskRejected,
  requestCreated,
  requestApprovedStep,
  requestRejected,
}

class ActivityEntity extends Equatable {
  final String id;
  final String userId;
  final String content;
  final ActivityType type;
  final DateTime createdAt;

  const ActivityEntity({
    required this.id,
    required this.userId,
    required this.content,
    required this.type,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, content, type, createdAt];
}
