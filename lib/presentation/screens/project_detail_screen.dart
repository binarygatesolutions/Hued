import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';
import '../../core/utils/animations.dart';
import '../../core/theme/theme_ext.dart';
import '../../domain/entities/entities.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_state.dart';
import '../blocs/project_bloc.dart';
import '../blocs/project_event.dart';
import '../blocs/activity_bloc.dart';
import '../blocs/activity_event.dart';
import '../blocs/activity_state.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/project_section_header.dart';
import '../widgets/empty_tasks_message.dart';
import '../widgets/project_hero_section.dart';
import '../widgets/project_stats_row.dart';
import '../widgets/project_stakeholder_card.dart';
import '../widgets/task_card.dart';
import '../widgets/animated_list_wrapper.dart';
import '../widgets/task_filter_dropdown.dart';
import '../widgets/custom_loading.dart';
import '../widgets/shared_smart_refresher.dart';
import '../widgets/shared_timeline_widget.dart';
import '../widgets/project_detail_background.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../../core/services/pdf_service.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ProjectEntity project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  TaskStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    context.read<ActivityBloc>().add(
      MonitorActivities(projectId: widget.project.id),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    _refreshController.refreshCompleted();
  }

  void _navigateToManageUsers(
    BuildContext context,
    ProjectEntity currentProject,
  ) {
    context.push(
      '/project/${currentProject.id}/manage-users',
      extra: currentProject,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! Authenticated) {
          return const Scaffold(body: CustomLoading());
        }

        final user = authState.user;

        return StreamBuilder<ProjectEntity>(
          stream: context.read<ProjectRepository>().getProjectStream(
            widget.project.id,
          ),
          builder: (context, projectSnapshot) {
            if (projectSnapshot.connectionState == ConnectionState.waiting &&
                !projectSnapshot.hasData) {
              return Scaffold(
                appBar: SharedAppBar(
                  title: widget.project.title,
                  showBackButton: true,
                ),
                body: const Center(child: CustomLoading()),
              );
            }

            final currentProject = projectSnapshot.data ?? widget.project;

            return StreamBuilder<List<TaskEntity>>(
              stream: context.read<ProjectRepository>().getTasksStream(
                currentProject.id,
              ),
              builder: (context, tasksSnapshot) {
                final tasks = tasksSnapshot.data ?? [];

                return FutureBuilder<Map<String, UserEntity>>(
                  future: _fetchUsers(context, [
                    ...currentProject.assignedUserIds,
                    currentProject.creatorId,
                  ]),
                  builder: (context, usersSnapshot) {
                    final users = usersSnapshot.data ?? {};

                    return Scaffold(
                      extendBodyBehindAppBar: true,
                      appBar: _buildAppBar(
                        context,
                        user,
                        currentProject,
                        tasks,
                        users,
                      ),
                      body: Stack(
                        children: [
                          const ProjectDetailBackground(),
                          SafeArea(
                            child: _buildScrollableContent(
                              context,
                              user,
                              currentProject,
                              tasks,
                              users,
                            ),
                          ),
                        ],
                      ),
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

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    UserEntity user,
    ProjectEntity currentProject,
    List<TaskEntity> tasks,
    Map<String, UserEntity> users,
  ) {
    return SharedAppBar(
      title: currentProject.title,
      showBackButton: true,
      actions: [
        if (user.role == UserRole.admin &&
            (currentProject.creatorId ==
                FirebaseAuth.instance.currentUser?.uid) &&
            currentProject.status != ProjectStatus.finished)
          IconButton(
            icon: const Icon(Ionicons.people_outline),
            onPressed: () => _navigateToManageUsers(context, currentProject),
            tooltip: LangKeys.manageTeam.tr(),
          ),

        if (currentProject.status == ProjectStatus.inProgress &&
            (user.role == UserRole.admin || user.role == UserRole.supervisor))
          IconButton(
            icon: const Icon(Ionicons.flag_outline),
            tooltip: LangKeys.finishProject.tr(),
            onPressed: () =>
                _showFinishProjectDialog(context, currentProject, user),
          ),

        if (currentProject.status != ProjectStatus.finished)
          IconButton(
            icon: const Icon(Ionicons.add_circle_outline),
            tooltip: LangKeys.addTask.tr(),
            onPressed: () =>
                context.push('/project/${currentProject.id}/add-task'),
          ),

        IconButton(
          icon: const Icon(Ionicons.document_text_outline),
          tooltip: LangKeys.exportReport.tr(),
          onPressed: () => _handleExportReport(currentProject, tasks, users),
        ),
      ],
    );
  }

  Future<void> _handleExportReport(
    ProjectEntity project,
    List<TaskEntity> tasks,
    Map<String, UserEntity> users,
  ) async {
    final Map<String, dynamic>?
    result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        ),
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LangKeys.smartExport.tr(),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                      ),
                      Text(
                        LangKeys.generateInsights.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context, {
                      'isDetailed': true,
                      'shouldPrint': true,
                    }),
                    icon: const Icon(Icons.print_outlined),
                    label: Text(LangKeys.print.tr()),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, {
                        'isDetailed': true,
                        'shouldPrint': false,
                      }),
                      icon: const Icon(Icons.rocket_launch_outlined),
                      label: Text(LangKeys.extractPdf.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CustomLoading()),
    );

    try {
      await PdfService.generateProjectReport(
        project: project,
        tasks: tasks,
        users: users,
        shouldPrint: result['shouldPrint'],
      );
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _buildScrollableContent(
    BuildContext context,
    UserEntity user,
    ProjectEntity currentProject,
    List<TaskEntity> tasks,
    Map<String, UserEntity> users,
  ) {
    return BlocBuilder<ActivityBloc, ActivityState>(
      builder: (context, activityState) {
        final activities = (activityState is ActivityLoaded)
            ? activityState.activities
            : <ActivityEntity>[];

        final approvedTasks = tasks.where((t) => t.isApproved).toList();

        return SharedSmartRefresher(
          controller: _refreshController,
          enablePullUp: false,
          onRefresh: _onRefresh,
          onLoading: null,
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
                      ProjectHeroSection(
                        project: currentProject,
                        completedTasks: approvedTasks
                            .where((t) => t.status == TaskStatus.completed)
                            .length,
                        totalApprovedTasks: approvedTasks.length,
                        users: users,
                      ),
                      const SizedBox(height: 24),
                      ProjectStatsRow(
                        totalTasks: approvedTasks.length,
                        activeTasks: approvedTasks
                            .where((t) => t.status != TaskStatus.completed)
                            .length,
                        doneTasks: approvedTasks
                            .where((t) => t.status == TaskStatus.completed)
                            .length,
                      ),
                      const SizedBox(height: 32),
                      ProjectStakeholderCard(
                        project: currentProject,
                        users: users,
                      ),
                      const SizedBox(height: 48),
                      ProjectSectionHeader(
                        title: LangKeys.tasks.tr().toUpperCase(),
                        count: tasks.length,
                        color: context.primary,
                        icon: Ionicons.layers_outline,
                        trailing: TaskFilterDropdown(
                          selectedStatus: _selectedStatus,
                          onStatusSelected: (status) {
                            setState(() => _selectedStatus = status);
                          },
                        ),
                      ).animateEntrance(delayMs: 400),
                      const SizedBox(height: 24),
                      if (tasks.isEmpty)
                        const EmptyTasksMessage()
                      else
                        ..._buildFilteredTasks(
                          context,
                          currentProject,
                          tasks,
                          users,
                        ),
                      const SizedBox(height: 40),
                      SharedTimelineWidget(
                        activities: activities,
                        title: LangKeys.projectActivities.tr(),
                        onViewAll: () => context.push(
                          '/project/${currentProject.id}/timeline',
                        ),
                        color: context.primary,
                        users: users,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildFilteredTasks(
    BuildContext context,
    ProjectEntity project,
    List<TaskEntity> allTasks,
    Map<String, UserEntity> users,
  ) {
    var filtered = allTasks;
    if (_selectedStatus != null) {
      filtered = allTasks.where((t) => t.status == _selectedStatus).toList();
    }

    if (filtered.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              LangKeys.noTasksStatus.tr(),
              style: TextStyle(
                color: context.onSurface.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ];
    }

    // Grouping by status
    final Map<TaskStatus, List<TaskEntity>> grouped = {};
    for (var t in filtered) {
      grouped.putIfAbsent(t.status, () => []).add(t);
    }

    final List<Widget> items = [];
    final statuses = _selectedStatus != null
        ? [_selectedStatus!]
        : TaskStatus.values.where((s) => grouped.containsKey(s)).toList();

    for (var status in statuses) {
      final statusTasks = grouped[status] ?? [];
      if (statusTasks.isEmpty) continue;

      if (_selectedStatus == null) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 8),
            child: Text(
              status.name.tr().toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: _getStatusColor(status, context).withOpacity(0.8),
              ),
            ),
          ),
        );
      }

      for (var i = 0; i < statusTasks.length; i++) {
        items.add(_buildTaskCard(context, project, statusTasks[i], users, i));
      }
      items.add(const SizedBox(height: 16));
    }

    return items;
  }

  Widget _buildTaskCard(
    BuildContext context,
    ProjectEntity project,
    TaskEntity task,
    Map<String, UserEntity> users,
    int index,
  ) {
    return AnimatedListWrapper(
      index: index,
      child: TaskCard(
        task: task,
        users: users,
        onTap: () => context.push(
          '/project/${project.id}/task/${task.id}',
          extra: project,
        ),
      ),
    );
  }

  Color _getStatusColor(TaskStatus status, BuildContext context) {
    switch (status) {
      case TaskStatus.completed:
        return Colors.green.shade800;
      case TaskStatus.inProgress:
        return context.primary;
      case TaskStatus.cancelled:
        return context.error;
      case TaskStatus.pending:
        return context.purple;
    }
  }

  void _showFinishProjectDialog(
    BuildContext context,
    ProjectEntity project,
    UserEntity user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LangKeys.finishProject.tr()),
        content: Text(LangKeys.confirmFinishProject.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LangKeys.cancel.tr()),
          ),
          TextButton(
            onPressed: () {
              context.read<ProjectBloc>().add(
                UpdateProjectStatus(
                  projectId: project.id,
                  status: ProjectStatus.finished,
                  userId: user.id,
                ),
              );
              Navigator.pop(context);
            },
            child: Text(
              LangKeys.finishProject.tr(),
              style: TextStyle(color: context.primary),
            ),
          ),
        ],
      ),
    );
  }
}
