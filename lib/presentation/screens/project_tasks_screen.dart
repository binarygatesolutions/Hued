import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/lang_keys.dart';
import '../../core/theme/theme_ext.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_state.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/project_section_header.dart';
import '../widgets/empty_tasks_message.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_dropdown.dart';
import '../widgets/custom_loading.dart';
import '../widgets/project_detail_background.dart';
import '../widgets/shared_smart_refresher.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class ProjectTasksScreen extends StatefulWidget {
  final ProjectEntity project;

  const ProjectTasksScreen({super.key, required this.project});

  @override
  State<ProjectTasksScreen> createState() => _ProjectTasksScreenState();
}

class _ProjectTasksScreenState extends State<ProjectTasksScreen> {
  final RefreshController _refreshController = RefreshController();
  List<TaskEntity> _tasks = [];
  Map<String, UserEntity> _users = {};
  TaskStatus? _selectedStatus;
  bool _isLoading = false;
  bool _hasMore = true;
  dynamic _lastDoc;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _tasks = [];
      _lastDoc = null;
      _hasMore = true;
    });

    try {
      final repo = context.read<ProjectRepository>();
      final authState = context.read<AuthBloc>().state;
      final currentUser = authState is Authenticated ? authState.user : null;

      final result = await repo.getPaginatedTasks(
        widget.project.id,
        status: _selectedStatus,
        userId: currentUser?.id,
        role: currentUser?.role,
      );

      final users = await _fetchUsers(context, result.tasks);

      setState(() {
        _tasks = result.tasks;
        _users = users;
        _lastDoc = result.lastDoc;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
      _refreshController.refreshCompleted();
      if (!_hasMore) _refreshController.loadNoData();
    } catch (e) {
      setState(() => _isLoading = false);
      _refreshController.refreshFailed();
    }
  }

  Future<void> _onLoading() async {
    if (!_hasMore) {
      _refreshController.loadNoData();
      return;
    }

    try {
      final repo = context.read<ProjectRepository>();
      final authState = context.read<AuthBloc>().state;
      final currentUser = authState is Authenticated ? authState.user : null;

      final result = await repo.getPaginatedTasks(
        widget.project.id,
        lastDocument: _lastDoc,
        status: _selectedStatus,
        userId: currentUser?.id,
        role: currentUser?.role,
      );

      final newUsers = await _fetchUsers(context, result.tasks);

      setState(() {
        _tasks.addAll(result.tasks);
        _users.addAll(newUsers);
        _lastDoc = result.lastDoc;
        _hasMore = result.hasMore;
      });

      if (_hasMore) {
        _refreshController.loadComplete();
      } else {
        _refreshController.loadNoData();
      }
    } catch (e) {
      _refreshController.loadFailed();
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: SharedAppBar(title: widget.project.title, showBackButton: true),
      body: Stack(
        children: [
          const ProjectDetailBackground(),
          SafeArea(
            child: _isLoading
                ? const Center(child: CustomLoading())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: ProjectSectionHeader(
            title: LangKeys.allTasks.tr().toUpperCase(),
            count: _tasks.length,
            color: context.primary,
            icon: Ionicons.layers_outline,
            trailing: TaskFilterDropdown(
              selectedStatus: _selectedStatus,
              onStatusSelected: (status) {
                setState(() => _selectedStatus = status);
                _loadInitial();
              },
            ),
          ),
        ),
        Expanded(
          child: _tasks.isEmpty
              ? const EmptyTasksMessage()
              : SharedSmartRefresher(
                  controller: _refreshController,
                  onRefresh: _loadInitial,
                  onLoading: _onLoading,
                  enablePullUp: true,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 50),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      final authState = context.read<AuthBloc>().state;
                      final currentUser = authState is Authenticated
                          ? authState.user
                          : null;

                      final isMyWorkerAssigned =
                          currentUser?.role == UserRole.projectManager &&
                          task.assignedWorkerIds.any(
                            (workerId) =>
                                widget.project.workerManagerMap[workerId] ==
                                currentUser!.id,
                          );

                      return TaskCard(
                        task: task,
                        users: _users,
                        isMyWorkerAssigned: isMyWorkerAssigned,
                        onTap: () => context.push(
                          '/project/${widget.project.id}/task/${task.id}',
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<Map<String, UserEntity>> _fetchUsers(
    BuildContext context,
    List<TaskEntity> tasks,
  ) async {
    final userIds = tasks.map((t) => t.creatorId).toSet().toList();
    if (userIds.isEmpty) return {};

    try {
      final users = await context.read<AuthRepository>().getUsers(
        userIds: userIds,
      );
      return {for (var u in users) u.id: u};
    } catch (e) {
      return {};
    }
  }
}
