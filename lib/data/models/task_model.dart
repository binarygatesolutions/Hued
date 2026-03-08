import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    required super.projectId,
    required super.title,
    required super.description,
    required super.status,
    required super.priority,
    required super.deadline,
    required super.createdAt,
    required super.creatorId,
    super.isApproved,
  });

  factory TaskModel.fromFirestore(Map<String, dynamic> json, String id) {
    return TaskModel(
      id: id,
      projectId: json['projectId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      deadline: (json['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creatorId: json['creatorId'] ?? 'Unknown',
      isApproved: json['isApproved'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': Timestamp.fromDate(createdAt),
      'creatorId': creatorId,
      'isApproved': isApproved,
    };
  }

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      projectId: entity.projectId,
      title: entity.title,
      description: entity.description,
      status: entity.status,
      priority: entity.priority,
      deadline: entity.deadline,
      createdAt: entity.createdAt,
      creatorId: entity.creatorId,
      isApproved: entity.isApproved,
    );
  }
}
