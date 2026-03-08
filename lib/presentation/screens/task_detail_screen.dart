import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';
import 'package:hued/presentation/widgets/shared_app_bar.dart';
import 'package:ionicons/ionicons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/animations.dart';
import '../../core/theme/theme_ext.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/activity_entity.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_state.dart';
import '../blocs/project_bloc.dart';
import '../blocs/project_event.dart';
import '../blocs/project_state.dart';
import '../widgets/custom_loading.dart';
import '../widgets/premium_card.dart';
import '../widgets/shared_smart_refresher.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../blocs/activity_bloc.dart';
import '../blocs/activity_event.dart';
import '../blocs/activity_state.dart';
import '../widgets/shared_timeline_widget.dart';
import '../blocs/sync_bloc.dart';
import '../blocs/sync_state.dart';
import '../widgets/project_detail_background.dart';

class TaskDetailScreen extends StatefulWidget {
  final String projectId;
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.projectId,
    required this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TextEditingController commentController = TextEditingController();
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  bool _isUploadingAttachment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityBloc>().add(
        MonitorActivities(projectId: widget.projectId, taskId: widget.taskId),
      );
    });
  }

  @override
  void dispose() {
    commentController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _refreshController.refreshCompleted();
  }

  Future<void> _onLoading() async {
    _refreshController.loadComplete();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return const Scaffold(body: CustomLoading());
    }
    final user = authState.user;

    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, syncState) {
        final syncedTask = (syncState is TaskSynced) ? syncState.task : null;

        return StreamBuilder<ProjectEntity>(
          stream: context.read<ProjectRepository>().getProjectStream(
            widget.projectId,
          ),
          builder: (context, projectSnapshot) {
            if (projectSnapshot.connectionState == ConnectionState.waiting &&
                !projectSnapshot.hasData) {
              return const Scaffold(body: CustomLoading());
            }
            final project = projectSnapshot.data;
            if (project == null) {
              return Scaffold(
                body: Center(child: Text(LangKeys.projectNotFound.tr())),
              );
            }

            return StreamBuilder<TaskEntity>(
              stream: context.read<ProjectRepository>().getTaskStream(
                widget.projectId,
                widget.taskId,
              ),
              builder: (context, taskSnapshot) {
                if (taskSnapshot.connectionState == ConnectionState.waiting &&
                    !taskSnapshot.hasData) {
                  return const Scaffold(body: CustomLoading());
                }

                final task = syncedTask ?? taskSnapshot.data;

                if (task == null) {
                  return Scaffold(
                    body: Center(child: Text(LangKeys.taskNotFound.tr())),
                  );
                }

                return FutureBuilder<Map<String, UserEntity>>(
                  future: _fetchUsers(context, [
                    ...project.assignedUserIds,
                    project.creatorId,
                  ]),
                  builder: (context, usersSnapshot) {
                    final users = usersSnapshot.data ?? {};

                    return BlocBuilder<ActivityBloc, ActivityState>(
                      builder: (context, activityState) {
                        final taskActivities = (activityState is ActivityLoaded)
                            ? activityState.activities
                            : <ActivityEntity>[];

                        return FutureBuilder<List<AttachmentEntity>>(
                          future: context
                              .read<ProjectRepository>()
                              .getTaskAttachments(
                                widget.projectId,
                                widget.taskId,
                              ),
                          builder: (context, attachmentSnapshot) {
                            final taskAttachments =
                                attachmentSnapshot.data ?? [];

                            return _buildScaffold(
                              context: context,
                              task: task,
                              activities: taskActivities,
                              attachments: taskAttachments,
                              user: user,
                              projectId: project.id,
                              users: users,
                              controller: commentController,
                              enablePullUp: false,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<Map<String, UserEntity>> _fetchUsers(
    BuildContext context,
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};
    final users = await context.read<AuthRepository>().getUsers(
      userIds: userIds,
    );
    return {for (var u in users) u.id: u};
  }

  Widget _buildScaffold({
    required BuildContext context,
    required TaskEntity task,
    required List<ActivityEntity> activities,
    required List<AttachmentEntity> attachments,
    required UserEntity user,
    required String projectId,
    required Map<String, UserEntity> users,
    required TextEditingController controller,
    required bool enablePullUp,
  }) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: SharedAppBar(
        title: task.title,
        actions: [
          if (_canEditDeadline(task, user))
            IconButton(
              icon: Icon(Ionicons.calendar_outline, color: context.onSurface),
              onPressed: () => _selectDate(context, projectId, task),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const ProjectDetailBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SharedSmartRefresher(
                    controller: _refreshController,
                    enablePullUp: enablePullUp,
                    onRefresh: _onRefresh,
                    onLoading: _onLoading,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                _buildHeader(
                                  context,
                                  task,
                                  user,
                                  projectId,
                                ).animateEntrance(),
                                const SizedBox(height: 40),
                                _buildDescription(
                                  context,
                                  task,
                                ).animateEntrance(delayMs: 200),

                                if (task.isApproved)
                                  _buildStatusControl(
                                    context,
                                    projectId,
                                    task,
                                    user,
                                  ).animateEntrance(delayMs: 300),

                                _buildAttachments(context, attachments, users),
                                const SizedBox(height: 48),
                                _buildActivitySection(
                                  context,
                                  task,
                                  activities,
                                  user,
                                  users,
                                ).animateEntrance(delayMs: 400),
                                const SizedBox(height: 160),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildCommentInput(
                  context,
                  projectId,
                  task.id,
                  user,
                  controller,
                  task.isApproved,
                ),
              ],
            ),
          ),
          // Admin/Supervisor Approval (for Client-created tasks or overall management)
          if (!task.isApproved &&
              (user.role == UserRole.admin || user.role == UserRole.supervisor))
            _buildApprovalFooter(
              context,
              projectId,
              task.id,
              title: LangKeys.approveTaskRequest.tr(),
              onApprove: () => context.read<ProjectBloc>().add(
                ApproveTask(
                  projectId: projectId,
                  taskId: task.id,
                  userId: user.id,
                ),
              ),
              onReject: () => context.read<ProjectBloc>().add(
                RejectTask(
                  projectId: projectId,
                  taskId: task.id,
                  userId: user.id,
                ),
              ),
            ).animateScale(),

          // PM Approval (for tasks created by Client)
          if (!task.isApproved && user.role == UserRole.projectManager)
            _buildApprovalFooter(
              context,
              projectId,
              task.id,
              title: LangKeys.reviewClientTask.tr(),
              onApprove: () => context.read<ProjectBloc>().add(
                ApproveTask(
                  projectId: projectId,
                  taskId: task.id,
                  userId: user.id,
                ),
              ),
              onReject: () => context.read<ProjectBloc>().add(
                RejectTask(
                  projectId: projectId,
                  taskId: task.id,
                  userId: user.id,
                ),
              ),
            ).animateScale(),

          // Client Approval (for completed tasks)
          if (task.status == TaskStatus.completed &&
              task.isApproved && // Already approved initial creation
              user.role == UserRole.client)
            _buildApprovalFooter(
              context,
              projectId,
              task.id,
              title: LangKeys.acceptWorkResult.tr(),
              onApprove: () => context.read<ProjectBloc>().add(
                UpdateTaskStatus(
                  projectId: projectId,
                  taskId: task.id,
                  status: TaskStatus.completed.name,
                  userId: user.id,
                ),
              ), // This is simplified
              onReject: () => context.read<ProjectBloc>().add(
                UpdateTaskStatus(
                  projectId: projectId,
                  taskId: task.id,
                  status: TaskStatus.inProgress.name,
                  userId: user.id,
                ),
              ),
            ).animateScale(),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    TaskEntity task,
    UserEntity user,
    String projectId,
  ) {
    return PremiumCard(
      padding: const EdgeInsets.all(28),
      borderRadius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPriorityBadge(context, task.priority),
              if (!task.isApproved) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: context.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Ionicons.alert_circle,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        LangKeys.waitingApproval.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '#${task.id.length > 6 ? task.id.substring(0, 6) : task.id}',
                style: TextStyle(
                  color: context.onSurface.withOpacity(0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            task.title,
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.onSurface,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              _buildMetaItem(
                context,
                Ionicons.time_outline,
                LangKeys.createdLabel.tr(),
                DateFormat('MMM dd, yyyy').format(task.createdAt),
                context.onSurface.withOpacity(0.4),
              ),
              _buildMetaItem(
                context,
                Ionicons.calendar_outline,
                LangKeys.deadlineLabel.tr(),
                DateFormat('MMM dd, yyyy').format(task.deadline),
                context.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Ionicons.time_outline, size: 12, color: color),
        SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: context.onSurface.withOpacity(0.3),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(BuildContext context, TaskPriority priority) {
    final color = _getPriorityColor(priority, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        priority.name.tr().toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context, TaskEntity task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LangKeys.description.tr(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: context.onSurface.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          task.description,
          style: TextStyle(
            color: context.onSurface.withOpacity(0.9),
            fontSize: 16,
            height: 1.7,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection(
    BuildContext context,
    TaskEntity task,
    List<ActivityEntity> activities,
    UserEntity user,
    Map<String, UserEntity> users,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LangKeys.timelineAndActivity.tr(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: context.onSurface.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 32),
        SharedTimelineWidget(
          activities: activities,
          title: LangKeys.taskActivity.tr(),
          color: context.primary,
          users: users,
          onViewAll: () => context.push(
            '/project/${task.projectId}/task/${task.id}/timeline',
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput(
    BuildContext context,
    String projectId,
    String taskId,
    UserEntity user,
    TextEditingController controller,
    bool isApproved,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(
          top: BorderSide(color: context.onSurface.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: context.onSurface),
              decoration: InputDecoration(
                hintText: LangKeys.addAComment.tr(),
                hintStyle: TextStyle(
                  color: context.onSurface.withOpacity(0.3),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: context.onSurface.withOpacity(0.03),
                prefixIcon: IconButton(
                  icon: _isUploadingAttachment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Ionicons.attach_outline, color: context.primary),
                  onPressed: _isUploadingAttachment
                      ? null
                      : () => _showAttachmentPicker(
                          context,
                          projectId,
                          taskId,
                          user,
                        ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          BlocBuilder<ProjectBloc, ProjectState>(
            builder: (context, state) {
              final isLoading = state is ProjectLoading;
              return IconButton.filled(
                onPressed: isLoading
                    ? null
                    : () {
                        if (controller.text.isNotEmpty) {
                          context.read<ProjectBloc>().add(
                            AddActivity(
                              projectId: projectId,
                              taskId: taskId,
                              userId: user.id,
                              content: controller.text.trim(),
                              type: ActivityType.comment,
                            ),
                          );
                          controller.clear();
                        }
                      },
                iconSize: 24,
                style: IconButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(54, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Ionicons.send),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalFooter(
    BuildContext context,
    String projectId,
    String taskId, {
    required String title,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return Positioned(
      bottom: 120,
      left: 24,
      right: 24,
      child: PremiumCard(
        padding: const EdgeInsets.all(24),
        borderRadius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: context.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      onReject();
                      Navigator.pop(context); // Optional extra safety
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: context.error,
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: context.error.withOpacity(0.2)),
                      ),
                    ),
                    child: Text(
                      LangKeys.reject.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onApprove();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      LangKeys.approve.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusControl(
    BuildContext context,
    String projectId,
    TaskEntity task,
    UserEntity user,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LangKeys.updateStatus.tr(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: context.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: TaskStatus.values.map((status) {
              final isSelected = task.status == status;
              final color = isSelected
                  ? context.primary
                  : context.onSurface.withOpacity(0.05);
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (task.status == TaskStatus.completed) return;
                    if (status == TaskStatus.cancelled) return;
                    context.read<ProjectBloc>().add(
                      UpdateTaskStatus(
                        projectId: projectId,
                        taskId: task.id,
                        status: status.name,
                        userId: user.id,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.1) : color,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: color, width: 2)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isSelected
                              ? Ionicons.checkmark_circle
                              : Ionicons.ellipse_outline,
                          size: 16,
                          color: isSelected
                              ? color
                              : context.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: isSelected
                                ? color
                                : context.onSurface.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _showAttachmentPicker(
    BuildContext context,
    String projectId,
    String taskId,
    UserEntity user,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      if (!context.mounted) return;

      setState(() {
        _isUploadingAttachment = true;
      });

      final file = kIsWeb
          ? result.files.single.bytes
          : File(result.files.single.path!);

      // Dispatch event
      context.read<ProjectBloc>().add(
        AddAttachment(
          projectId: projectId,
          taskId: taskId,
          userId: user.id, // Using the user's ID
          file: file,
        ),
      );

      // Add a simple timeout to reset state, the bloc will trigger a refresh anyway
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _isUploadingAttachment = false;
          });
        }
      });
    }
  }

  bool _canEditDeadline(TaskEntity task, UserEntity user) {
    if (task.isApproved) return false;

    return user.role == UserRole.admin ||
        user.role == UserRole.supervisor ||
        user.role == UserRole.projectManager ||
        user.role == UserRole.client;
  }

  Future<void> _selectDate(
    BuildContext context,
    String projectId,
    TaskEntity task,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: task.deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        context.read<ProjectBloc>().add(
          UpdateTaskDeadline(
            projectId: projectId,
            taskId: task.id,
            deadline: picked,
            userId: authState.user.id,
          ),
        );
      }
    }
  }

  Color _getPriorityColor(TaskPriority priority, BuildContext context) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green.shade800;
      case TaskPriority.medium:
        return context.purple;
      case TaskPriority.high:
        return const Color(0xFFFF9800); // Amber
      case TaskPriority.urgent:
        return context.error;
    }
  }

  Widget _buildAttachments(
    BuildContext context,
    List<AttachmentEntity> attachments,
    Map<String, UserEntity> users,
  ) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        Text(
          LangKeys.attachments.tr(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: context.onSurface.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 24),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: attachments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final attachment = attachments[index];
            return PremiumCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Ionicons.document_outline,
                      color: context.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachment.url.split('/').last,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: context.onSurface,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${LangKeys.by.tr()} ${users[attachment.userId]?.name ?? LangKeys.unknown.tr()} • ${DateFormat('MMM dd').format(attachment.createdAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Ionicons.download_outline,
                      size: 20,
                      color: context.onSurface.withOpacity(0.6),
                    ),
                    onPressed: () => launchUrl(Uri.parse(attachment.url)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
