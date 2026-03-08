import 'package:equatable/equatable.dart';
export 'attachment_entity.dart';
export 'activity_entity.dart';

enum UserRole { admin, supervisor, projectManager, client }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.projectManager:
        return 'Project Manager';
      case UserRole.client:
        return 'Client';
    }
  }
}

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? profile;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.profile,
  });

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? profile,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      profile: profile ?? this.profile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'profile': profile,
    };
  }

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      profile: json['profile'],
    );
  }

  @override
  List<Object?> get props => [id, name, email, role];
}

enum TaskStatus { pending, inProgress, completed, cancelled }

enum TaskPriority { low, medium, high, urgent }

class TaskEntity extends Equatable {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime deadline;
  final DateTime createdAt;
  final String creatorId;
  final bool isApproved;

  const TaskEntity({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.deadline,
    required this.createdAt,
    required this.creatorId,
    this.isApproved = false,
  });

  TaskEntity copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? deadline,
    DateTime? createdAt,
    String? creatorId,
    bool? isApproved,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      creatorId: creatorId ?? this.creatorId,
      isApproved: isApproved ?? this.isApproved,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'deadline': deadline.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'creatorId': creatorId,
      'isApproved': isApproved,
    };
  }

  factory TaskEntity.fromJson(Map<String, dynamic> json) {
    return TaskEntity(
      id: json['id'] ?? '',
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
      deadline: json['deadline'] is String
          ? DateTime.parse(json['deadline'])
          : (json['deadline'] as dynamic).toDate(),
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : (json['createdAt'] as dynamic).toDate(),
      creatorId: json['creatorId'] ?? '',
      isApproved: json['isApproved'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    title,
    description,
    status,
    priority,
    deadline,
    createdAt,
    creatorId,
    isApproved,
  ];
}

enum ProjectStatus { inProgress, canceled, finished }

class ProjectEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final List<String> supervisorIds;
  final List<String> managerIds;
  final List<String> clientIds;
  final List<String> assignedUserIds;
  final ProjectStatus status;
  final DateTime createdAt;

  const ProjectEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.supervisorIds,
    required this.managerIds,
    required this.creatorId,
    required this.clientIds,
    required this.assignedUserIds,
    required this.status,
    required this.createdAt,
  });

  ProjectEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? creatorId,
    List<String>? supervisorIds,
    List<String>? managerIds,
    List<String>? clientIds,
    List<String>? assignedUserIds,
    ProjectStatus? status,
    DateTime? createdAt,
  }) {
    return ProjectEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      supervisorIds: supervisorIds ?? this.supervisorIds,
      managerIds: managerIds ?? this.managerIds,
      clientIds: clientIds ?? this.clientIds,
      assignedUserIds: assignedUserIds ?? this.assignedUserIds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'supervisorIds': supervisorIds,
      'managerIds': managerIds,
      'clientIds': clientIds,
      'assignedUserIds': assignedUserIds,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProjectEntity.fromJson(Map<String, dynamic> json) {
    return ProjectEntity(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      creatorId: json['creatorId'] ?? '',
      supervisorIds: List<String>.from(json['supervisorIds'] ?? []),
      managerIds: List<String>.from(json['managerIds'] ?? []),
      clientIds: List<String>.from(json['clientIds'] ?? []),
      assignedUserIds: List<String>.from(json['assignedUserIds'] ?? []),
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProjectStatus.inProgress,
      ),
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : (json['createdAt'] as dynamic).toDate(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    creatorId,
    supervisorIds,
    managerIds,
    clientIds,
    assignedUserIds,
    status,
    createdAt,
  ];
}
