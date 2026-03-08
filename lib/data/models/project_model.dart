import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

class ProjectModel extends ProjectEntity {
  const ProjectModel({
    required super.id,
    required super.title,
    required super.description,
    required super.supervisorIds,
    required super.managerIds,
    required super.clientIds,
    required super.assignedUserIds,
    required super.status,
    required super.creatorId,
    required super.createdAt,
  });

  factory ProjectModel.fromFirestore(Map<String, dynamic> json, String id) {
    final status = ProjectStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => ProjectStatus.inProgress,
    );

    return ProjectModel(
      id: id,
      creatorId: json['creatorId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      supervisorIds: List<String>.from(json['supervisorIds'] ?? []),
      managerIds: List<String>.from(json['managerIds'] ?? []),
      clientIds: List<String>.from(json['clientIds'] ?? []),
      assignedUserIds: List<String>.from(json['assignedUserIds'] ?? []),
      status: status,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'supervisorIds': supervisorIds,
      'managerIds': managerIds,
      'creatorId': creatorId,
      'clientIds': clientIds,
      'assignedUserIds': assignedUserIds,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ProjectModel.fromEntity(ProjectEntity entity) {
    return ProjectModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      supervisorIds: entity.supervisorIds,
      managerIds: entity.managerIds,
      clientIds: entity.clientIds,
      assignedUserIds: entity.assignedUserIds,
      status: entity.status,
      creatorId: entity.creatorId,
      createdAt: entity.createdAt,
    );
  }
}
