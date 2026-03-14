import '../../../domain/entities/entities.dart';

class ApprovalLogicHelper {
  static RequestEntity? generateRequest({
    required String projectId,
    required String taskId,
    required String userId,
    required UserRole role,
    required RequestType type,
    required String targetValue,
    required ProjectEntity project,
  }) {
    if (role == UserRole.client) return null;

    final List<String> requiredApproverIds = [];
    ApprovalStep initialStep = ApprovalStep.pm;

    switch (role) {
      case UserRole.worker:
        final managerId = project.workerManagerMap[userId];
        if (managerId != null) {
          requiredApproverIds.add(managerId);
        } else {
          requiredApproverIds.addAll(project.managerIds);
        }
        initialStep = ApprovalStep.pm;
        break;
      case UserRole.projectManager:
        requiredApproverIds.addAll(project.supervisorIds);
        initialStep = ApprovalStep.supervisor;
        break;
      case UserRole.supervisor:
      case UserRole.admin:
        requiredApproverIds.addAll(project.clientIds);
        initialStep = ApprovalStep.client;
        break;
      default:
        return null;
    }

    if (requiredApproverIds.isEmpty) return null;

    return RequestEntity(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      projectId: projectId,
      taskId: taskId,
      initiatorId: userId,
      initiatorRole: role,
      type: type,
      targetStatus: targetValue,
      currentStep: initialStep,
      status: RequestStatus.pending,
      requiredApproverIds: requiredApproverIds,
      createdAt: DateTime.now(),
    );
  }
}
