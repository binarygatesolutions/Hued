import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/entities.dart';

class RequestModel extends RequestEntity {
  const RequestModel({
    required super.id,
    required super.projectId,
    super.taskId,
    required super.initiatorId,
    required super.initiatorRole,
    required super.type,
    required super.targetStatus,
    required super.currentStep,
    required super.status,
    required super.requiredApproverIds,
    super.approvedBy = const {},
    required super.createdAt,
    super.rejectionReason,
  });

  factory RequestModel.fromFirestore(Map<String, dynamic> json, String id) {
    return RequestModel(
      id: id,
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
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rejectionReason: json['rejectionReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
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
      'createdAt': Timestamp.fromDate(createdAt),
      'rejectionReason': rejectionReason,
    };
  }

  factory RequestModel.fromEntity(RequestEntity entity) {
    return RequestModel(
      id: entity.id,
      projectId: entity.projectId,
      taskId: entity.taskId,
      initiatorId: entity.initiatorId,
      initiatorRole: entity.initiatorRole,
      type: entity.type,
      targetStatus: entity.targetStatus,
      currentStep: entity.currentStep,
      status: entity.status,
      requiredApproverIds: entity.requiredApproverIds,
      approvedBy: entity.approvedBy,
      createdAt: entity.createdAt,
      rejectionReason: entity.rejectionReason,
    );
  }
}
