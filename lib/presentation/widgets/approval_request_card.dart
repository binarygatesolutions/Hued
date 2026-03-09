import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/localization/lang_keys.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/project_repository.dart';
import '../blocs/project_bloc.dart';
import '../blocs/project_event.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_state.dart';
import '../widgets/shared_profile_avatar.dart';
import 'premium_card.dart';
import '../../core/theme/theme_ext.dart';
import '../../core/utils/haptics_service.dart';

class ApprovalRequestCard extends StatelessWidget {
  final RequestEntity request;
  final bool isCompact;
  final double? width;
  final EdgeInsets? margin;

  const ApprovalRequestCard({
    super.key,
    required this.request,
    this.isCompact = false,
    this.width = 320,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final projectRepo = context.read<ProjectRepository>();
    final authRepo = context.read<AuthRepository>();
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = (authState is Authenticated) ? authState.user.id : '';

    // Only allow approval if current user is in the required approvers list
    final bool canApprove = request.requiredApproverIds.contains(currentUserId);

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDetails(projectRepo, authRepo),
      builder: (context, snapshot) {
        final details = snapshot.data;
        final initiator = details?['initiator'] as UserEntity?;
        final projectName = details?['projectName'] as String? ?? '...';
        final taskName = details?['taskName'] as String?;

        return Container(
          width: isCompact ? double.infinity : width,
          margin:
              margin ??
              (isCompact
                  ? const EdgeInsets.only(bottom: 16)
                  : const EdgeInsets.only(right: 16)),

          child: PremiumCard(
            borderRadius: 24,
            padding: const EdgeInsets.all(20),
            onTap: () => _handleOnTap(context, canApprove, details),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premium Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (canApprove ? Colors.amber : context.primary)
                            .withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (canApprove ? Colors.amber : context.primary)
                              .withOpacity(0.15),
                        ),
                      ),
                      child: Icon(
                        request.type == RequestType.taskStatus
                            ? Ionicons.list_outline
                            : request.type == RequestType.taskDeadline
                            ? Ionicons.calendar_outline
                            : Ionicons.rocket_outline,
                        size: 20,
                        color: canApprove ? Colors.amber[800] : context.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            projectName.toUpperCase(),
                            style: TextStyle(
                              color: context.onSurface.withOpacity(0.4),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            taskName ?? LangKeys.projectStatus.tr(),
                            style: TextStyle(
                              color: context.onSurface,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Transition Status Area
                _buildStatusTransition(context, details),

                const SizedBox(height: 24),

                // Footer Area: Progress & Initiator
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  decoration: BoxDecoration(
                    color: context.onSurface.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      SharedProfileAvatar(
                        imageUrl: initiator?.profile,
                        name: initiator?.name ?? '',
                        radius: 12,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              initiator?.name ?? request.initiatorId,
                              style: TextStyle(
                                color: context.onSurface,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              DateFormat(
                                'h:mm a',
                                context.locale.toString(),
                              ).format(request.createdAt),
                              style: TextStyle(
                                color: context.onSurface.withOpacity(0.4),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildSmallProgressDots(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusTransition(
    BuildContext context,
    Map<String, dynamic>? details,
  ) {
    final task = details?['task'] as TaskEntity?;
    String fromValue = request.currentStep.name;

    if (request.type == RequestType.taskStatus && task != null) {
      fromValue = task.status.name.tr();
    } else if (request.type == RequestType.taskDeadline && task != null) {
      fromValue = DateFormat(
        'MMM dd',
        context.locale.toString(),
      ).format(task.deadline);
    }

    final String toValue = request.type == RequestType.taskDeadline
        ? DateFormat(
            'MMM dd',
            context.locale.toString(),
          ).format(DateTime.parse(request.targetStatus))
        : request.targetStatus.tr();

    return Row(
      children: [
        Expanded(child: _buildTransitionChip(context, fromValue, false)),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.onSurface.withOpacity(0.05),
                context.primary.withOpacity(0.2),
              ],
            ),
          ),
        ),
        Icon(
          Ionicons.chevron_forward,
          size: 14,
          color: context.primary.withOpacity(0.3),
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildTransitionChip(context, toValue, true)),
      ],
    );
  }

  Widget _buildTransitionChip(
    BuildContext context,
    String text,
    bool isHighlight,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isHighlight
            ? context.primary.withOpacity(0.08)
            : context.onSurface.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlight
              ? context.primary.withOpacity(0.12)
              : context.onSurface.withOpacity(0.06),
        ),
      ),
      child: Center(
        child: Text(
          text.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isHighlight ? context.primary : context.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallProgressDots(BuildContext context) {
    final List<ApprovalStep> allSteps = [
      ApprovalStep.pm,
      ApprovalStep.supervisor,
      ApprovalStep.client,
    ];

    int startIndex = 0;
    if (request.initiatorRole == UserRole.projectManager) startIndex = 1;
    if (request.initiatorRole == UserRole.supervisor ||
        request.initiatorRole == UserRole.admin)
      startIndex = 2;

    final relevantSteps = allSteps.sublist(startIndex);
    final currentStepIndex = relevantSteps.indexOf(request.currentStep);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(relevantSteps.length, (index) {
        final bool isDone =
            index < currentStepIndex ||
            (index == currentStepIndex &&
                request.status == RequestStatus.approved);
        final bool isCurrent =
            index == currentStepIndex &&
            request.status == RequestStatus.pending;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(left: 4),
          width: isCurrent ? 14 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isDone
                ? context.primary
                : isCurrent
                ? Colors.amber
                : context.onSurface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  // --- REUSED REDESIGNED BOTTOM SHEET FROM PREVIOUS STEP WITH MINOR POLISH ---

  Future<Map<String, dynamic>> _fetchDetails(
    ProjectRepository projectRepo,
    AuthRepository authRepo,
  ) async {
    final Map<String, dynamic> results = {};
    try {
      final initiators = await authRepo.getUsers(
        userIds: [request.initiatorId],
      );
      if (initiators.isNotEmpty) results['initiator'] = initiators.first;

      final projects = await projectRepo.getProjects();
      final project = projects
          .where((p) => p.id == request.projectId)
          .firstOrNull;
      results['projectName'] = project?.title ?? LangKeys.unknown.tr();

      if (request.taskId != null) {
        final tasks = await projectRepo.getTasks(request.projectId);
        final task = tasks.where((t) => t.id == request.taskId).firstOrNull;
        results['taskName'] = task?.title;
        results['task'] = task;
      }

      if (request.approvedBy.isNotEmpty) {
        final approverIds = request.approvedBy.values.toSet().toList();
        final approvers = await authRepo.getUsers(userIds: approverIds);
        results['approvers'] = {for (var u in approvers) u.id: u};
      }
    } catch (e) {
      debugPrint('Error fetching approval card details: $e');
    }
    return results;
  }

  void _handleOnTap(
    BuildContext context,
    bool canApprove,
    Map<String, dynamic>? details,
  ) {
    _showApprovalBottomSheet(context, request, details);
  }

  void _showApprovalBottomSheet(
    BuildContext context,
    RequestEntity request,
    Map<String, dynamic>? details,
  ) {
    final reasonController = TextEditingController();
    final initiator = details?['initiator'] as UserEntity?;
    final approversData = details?['approvers'] as Map<String, UserEntity>?;
    final projectName = details?['projectName'] as String? ?? '...';
    final taskName = details?['taskName'] as String?;
    final authState = context.read<AuthBloc>().state;
    final currentUserId = (authState is Authenticated) ? authState.user.id : '';
    final bool canApprove = request.requiredApproverIds.contains(currentUserId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Header with Role & Type
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        request.type == RequestType.taskStatus
                            ? LangKeys.taskStatus.tr().toUpperCase()
                            : request.type == RequestType.taskDeadline
                            ? LangKeys.deadlineLabel.tr().toUpperCase()
                            : LangKeys.projectStatus.tr().toUpperCase(),
                        style: TextStyle(
                          color: context.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LangKeys.approveRequest.tr(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      taskName != null
                          ? '$projectName > $taskName'
                          : projectName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.onSurface.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Status Bridge Visualization
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.onSurface.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: context.onSurface.withOpacity(0.06),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusNode(
                        context,
                        LangKeys.currentStatus.tr(),
                        request.type == RequestType.taskStatus
                            ? ((details?['task'] as TaskEntity?)?.status.name ??
                                      '...')
                                  .tr()
                            : request.type == RequestType.taskDeadline
                            ? DateFormat.MMMd(context.locale.toString()).format(
                                (details?['task'] as TaskEntity?)?.deadline ??
                                    DateTime.now(),
                              )
                            : request.currentStep.name.tr(),
                        false,
                      ),
                      Container(
                        width: 40,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.onSurface.withOpacity(0.1),
                              context.primary.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                      _buildStatusNode(
                        context,
                        LangKeys.targetStatus.tr(),
                        request.type == RequestType.taskDeadline
                            ? DateFormat.MMMd(
                                context.locale.toString(),
                              ).format(DateTime.parse(request.targetStatus))
                            : request.targetStatus.tr(),
                        true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Requester Details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    SharedProfileAvatar(
                      imageUrl: initiator?.profile,
                      name: initiator?.name ?? '',
                      radius: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LangKeys.requestedBy.tr().toUpperCase(),
                            style: TextStyle(
                              color: context.onSurface.withOpacity(0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            initiator?.name ?? request.initiatorId,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildInitiatorRoleTag(context, request.initiatorRole),
                  ],
                ),
              ),

              if (request.approvedBy.isNotEmpty) ...[
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildApprovalTimeline(
                    context,
                    request,
                    approversData,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Input & Actions
              if (canApprove)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: context.onSurface.withOpacity(0.04),
                          hintText: LangKeys.rejectionReason.tr(),
                          hintStyle: TextStyle(
                            color: context.onSurface.withOpacity(0.3),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              label: LangKeys.reject.tr(),
                              color: Colors.redAccent,
                              isOutlined: true,
                              onPressed: () {
                                HapticsService.medium();
                                if (reasonController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        LangKeys.reasonRequired.tr(),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final state = context.read<AuthBloc>().state;
                                if (state is Authenticated) {
                                  context.read<ProjectBloc>().add(
                                    UpdateRequestStatusEvent(
                                      request: request,
                                      approved: false,
                                      userId: state.user.id,
                                      rejectionReason: reasonController.text,
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _buildActionButton(
                              context: context,
                              label: LangKeys.approve.tr(),
                              color: context.primary,
                              onPressed: () {
                                HapticsService.heavy();
                                final state = context.read<AuthBloc>().state;
                                if (state is Authenticated) {
                                  context.read<ProjectBloc>().add(
                                    UpdateRequestStatusEvent(
                                      request: request,
                                      approved: true,
                                      userId: state.user.id,
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Ionicons.lock_closed,
                          color: context.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            LangKeys.waitingFor.tr(
                              args: [request.currentStep.name.toUpperCase()],
                            ),
                            style: TextStyle(
                              color: context.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusNode(
    BuildContext context,
    String label,
    String value,
    bool isTarget,
  ) {
    return Column(
      crossAxisAlignment: isTarget
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: context.onSurface.withOpacity(0.4),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toUpperCase(),
          style: TextStyle(
            color: isTarget ? context.primary : context.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildInitiatorRoleTag(BuildContext context, UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: context.primary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.name.toUpperCase(),
        style: TextStyle(
          color: context.primary.withOpacity(0.7),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildApprovalTimeline(
    BuildContext context,
    RequestEntity request,
    Map<String, UserEntity>? approvers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Ionicons.git_merge_outline,
              size: 14,
              color: context.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 8),
            Text(
              LangKeys.approvalHistory.tr().toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: context.onSurface.withOpacity(0.4),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...request.approvedBy.entries.map((e) {
          final approver = approvers?[e.value];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SharedProfileAvatar(
                      imageUrl: approver?.profile,
                      name: approver?.name ?? '',
                      radius: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        approver?.name ?? e.value,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        e.key.toUpperCase(),
                        style: TextStyle(
                          color: context.onSurface.withOpacity(0.4),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Ionicons.checkmark_circle,
                  size: 18,
                  color: Colors.greenAccent[700],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required Color color,
    bool isOutlined = false,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.transparent : color,
        foregroundColor: isOutlined ? color : Colors.white,
        elevation: isOutlined ? 0 : 4,
        shadowColor: color.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isOutlined
              ? BorderSide(color: color, width: 2)
              : BorderSide.none,
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
