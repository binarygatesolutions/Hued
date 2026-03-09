import 'package:equatable/equatable.dart';
export 'attachment_entity.dart';
export 'activity_entity.dart';
export 'request_entity.dart';

enum UserRole { admin, supervisor, projectManager, client, worker }

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
      case UserRole.worker:
        return 'Worker';
    }
  }
}

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? profile;
  final String? specialtyId;
  final String? specialtyName;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.profile,
    this.specialtyId,
    this.specialtyName,
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
      specialtyId: specialtyId ?? this.specialtyId,
      specialtyName: specialtyName ?? this.specialtyName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'profile': profile,
      'specialtyId': specialtyId,
      'specialtyName': specialtyName,
    };
  }

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      profile: json['profile'],
      specialtyId: json['specialtyId'],
      specialtyName: json['specialtyName'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    role,
    profile,
    specialtyId,
    specialtyName,
  ];
}

class SpecialtyEntity extends Equatable {
  final String id;
  final String name;

  const SpecialtyEntity({required this.id, required this.name});

  factory SpecialtyEntity.fromJson(Map<String, dynamic> json) {
    return SpecialtyEntity(id: json['id'] ?? '', name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  @override
  List<Object?> get props => [id, name];
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
  final List<String> assignedWorkerIds;
  final DateTime? completedAt;

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
    this.assignedWorkerIds = const [],
    this.completedAt,
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
    List<String>? assignedWorkerIds,
    DateTime? completedAt,
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
      assignedWorkerIds: assignedWorkerIds ?? this.assignedWorkerIds,
      completedAt: completedAt ?? this.completedAt,
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
      'assignedWorkerIds': assignedWorkerIds,
      'completedAt': completedAt?.toIso8601String(),
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
      assignedWorkerIds: List<String>.from(json['assignedWorkerIds'] ?? []),
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] is String
                ? DateTime.parse(json['completedAt'])
                : (json['completedAt'] as dynamic).toDate())
          : null,
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
    assignedWorkerIds,
    completedAt,
  ];
}

enum ProjectStatus { inProgress, canceled, finished, archived }

class ProjectEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final List<String> supervisorIds;
  final List<String> managerIds;
  final List<String> clientIds;
  final List<String> assignedUserIds;
  final List<String> workerIds;
  final Map<String, String> workerManagerMap;
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
    required this.workerIds,
    this.workerManagerMap = const {},
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
    List<String>? workerIds,
    Map<String, String>? workerManagerMap,
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
      workerIds: workerIds ?? this.workerIds,
      workerManagerMap: workerManagerMap ?? this.workerManagerMap,
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
      'workerIds': workerIds,
      'workerManagerMap': workerManagerMap,
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
      workerIds: List<String>.from(json['workerIds'] ?? []),
      workerManagerMap: Map<String, String>.from(
        json['workerManagerMap'] ?? {},
      ),
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
    workerIds,
    workerManagerMap,
    status,
    createdAt,
  ];
}
