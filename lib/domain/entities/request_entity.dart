import 'package:equatable/equatable.dart';
import 'entities.dart';

enum RequestType { taskStatus, projectStatus }

enum RequestStatus { pending, approved, rejected }

enum ApprovalStep { pm, supervisor, client, executed }

class RequestEntity extends Equatable {
  final String id;
  final String projectId;
  final String? taskId;
  final String initiatorId;
  final UserRole initiatorRole;
  final RequestType type;
  final String targetStatus;
  final ApprovalStep currentStep;
  final RequestStatus status;
  final List<String> requiredApproverIds;
  final Map<String, String> approvedBy;
  final DateTime createdAt;
  final String? rejectionReason;

  const RequestEntity({
    required this.id,
    required this.projectId,
    this.taskId,
    required this.initiatorId,
    required this.initiatorRole,
    required this.type,
    required this.targetStatus,
    required this.currentStep,
    required this.status,
    required this.requiredApproverIds,
    this.approvedBy = const {},
    required this.createdAt,
    this.rejectionReason,
  });

  @override
  List<Object?> get props => [
    id,
    projectId,
    taskId,
    initiatorId,
    initiatorRole,
    type,
    targetStatus,
    currentStep,
    status,
    requiredApproverIds,
    approvedBy,
    createdAt,
    rejectionReason,
  ];

  factory RequestEntity.fromJson(Map<String, dynamic> json) {
    return RequestEntity(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      taskId: json['taskId'],
      initiatorId: json['initiatorId'] ?? '',
      initiatorRole: UserRole.values.firstWhere(
        (e) => e.name == json['initiatorRole'],
        orElse: () => UserRole.worker,
      ),
      type: RequestType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RequestType.taskStatus,
      ),
      targetStatus: json['targetStatus'] ?? '',
      currentStep: ApprovalStep.values.firstWhere(
        (e) => e.name == json['currentStep'],
        orElse: () => ApprovalStep.pm,
      ),
      status: RequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RequestStatus.pending,
      ),
      requiredApproverIds: List<String>.from(json['requiredApproverIds'] ?? []),
      approvedBy: Map<String, String>.from(json['approvedBy'] ?? {}),
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : (json['createdAt'] as dynamic).toDate(),
      rejectionReason: json['rejectionReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'taskId': taskId,
      'initiatorId': initiatorId,
      'initiatorRole': initiatorRole.name,
      'type': type.name,
      'targetStatus': targetStatus,
      'currentStep': currentStep.name,
      'status': status.name,
      'requiredApproverIds': requiredApproverIds,
      'approvedBy': approvedBy,
      'createdAt': createdAt.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }
}
