import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hued/presentation/blocs/project_event.dart';
import '../../core/localization/lang_keys.dart';
import 'package:hued/core/navigation/app_router.dart';
import 'package:ionicons/ionicons.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_state.dart';
import '../blocs/project_bloc.dart';
import '../blocs/project_state.dart';
import '../widgets/project_card.dart';
import '../widgets/custom_loading.dart';
import '../widgets/shared_profile_avatar.dart';
import '../widgets/shared_app_logo.dart';
import '../../domain/entities/entities.dart';
import '../../core/theme/theme_ext.dart';
import '../widgets/premium_card.dart';
import '../widgets/approval_request_card.dart';
import '../widgets/shared_smart_refresher.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:hued/core/utils/animations.dart';
import 'package:hued/core/utils/haptics_service.dart';
import '../widgets/project_section_header.dart';

int _activeProjects = 0;
int _finishedProjects = 0;
int _canceledProjects = 0;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) _loadInitialData(authState.user);
  }

  Future<void> _onLoading() async {
    final state = context.read<ProjectBloc>().state;
    if (!state.hasMore) {
      _refreshController.loadNoData();
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<ProjectBloc>().add(
        LoadMoreProjects(userId: authState.user.id, role: authState.user.role),
      );
      context.read<ProjectBloc>().add(LoadPendingRequests(authState.user.id));
    }
  }

  void _loadInitialData(UserEntity user) {
    getStatistics(user);
    context.read<ProjectBloc>().add(
      LoadProjects(userId: user.id, role: user.role),
    );
    context.read<ProjectBloc>().add(LoadPendingRequests(user.id));
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh(UserEntity user) async {
    _loadInitialData(user);
    await getStatistics(user);
  }

  Future<void> getStatistics(UserEntity user) async {
    final col = FirebaseFirestore.instance.collection('projects');

    // For non-admins, scope queries to projects they are assigned to.
    final bool isAdmin = user.role == UserRole.admin;

    Query<Map<String, dynamic>> base = col;
    if (!isAdmin) {
      base = col.where('assignedUserIds', arrayContains: user.id);
    }

    final results = await Future.wait([
      base
          .where('status', isEqualTo: ProjectStatus.finished.name)
          .count()
          .get(),
      base
          .where('status', isEqualTo: ProjectStatus.inProgress.name)
          .count()
          .get(),
      base
          .where('status', isEqualTo: ProjectStatus.canceled.name)
          .count()
          .get(),
    ]);

    setState(() {
      _finishedProjects = results[0].count ?? 0;
      _activeProjects = results[1].count ?? 0;
      _canceledProjects = results[2].count ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              _loadInitialData(state.user);
              context.read<ProjectBloc>().add(
                LoadPendingRequests(state.user.id),
              );
            }
          },
        ),
        BlocListener<ProjectBloc, ProjectState>(
          listener: (context, state) {
            if (!state.isInitialLoading) {
              _refreshController.refreshCompleted();
            }
            if (!state.isLoadingMore) {
              if (state.hasMore) {
                _refreshController.loadComplete();
              } else {
                _refreshController.loadNoData();
              }
            }
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            final user = state.user;

            return Scaffold(
              backgroundColor: context.background,
              floatingActionButton: user.role == UserRole.supervisor
                  ? FloatingActionButton.extended(
                      onPressed: () {
                        HapticsService.light();
                        context.pushNamed(AppRouter.addProject);
                      },
                      backgroundColor: context.primary,
                      icon: Icon(Ionicons.add, color: context.surface),
                      label: Text(
                        LangKeys.newProject.tr(),
                        style: TextStyle(
                          color: context.surface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ).animateScale(delayMs: 600)
                  : null,
              body: _buildRoleSpecificContent(context, user),
            );
          }
          return Scaffold(
            backgroundColor: context.background,
            body: CustomLoading(),
          );
        },
      ),
    );
  }

  Widget _buildRoleSpecificContent(BuildContext context, UserEntity user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(color: context.background),
      child: Stack(
        children: [
          // Multi-layered Mesh Gradient Blobs
          if (isDark) ...[
            Positioned(
              top: -100,
              right: -50,
              child:
                  Container(
                        width: 350,
                        height: 350,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              context.primary.withOpacity(0.12),
                              context.primary.withOpacity(0),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 1200.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        curve: Curves.easeOutCubic,
                      ),
            ),
            Positioned(
              top: 150,
              left: -100,
              child:
                  Container(
                        width: 450,
                        height: 450,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              context.purple.withOpacity(0.08),
                              context.purple.withOpacity(0),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 1500.ms, delay: 200.ms)
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        curve: Curves.easeOutCubic,
                      ),
            ),
            Positioned(
              bottom: 100,
              right: -150,
              child:
                  Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              context.primary.withOpacity(0.06),
                              context.primary.withOpacity(0),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .moveY(
                        begin: 0,
                        end: 30,
                        duration: 4.seconds,
                        curve: Curves.easeInOut,
                      ),
            ),
            // Glassmorphism Overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ],

          // Main Content
          Positioned.fill(
            child: SharedSmartRefresher(
              controller: _refreshController,
              enablePullUp: true,

              onRefresh: () => _onRefresh(user),
              onLoading: _onLoading,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        MediaQuery.of(context).viewPadding.top + 20,
                        24,
                        0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SharedAppLogo(height: 20),
                              const SizedBox(width: 7),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: context.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: context.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  LangKeys.getLocalizedRole(
                                    user.role,
                                  ).toUpperCase(),
                                  style: TextStyle(
                                    color: context.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          _buildNotificationIcon(context, user),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildPersonalizedHeader(context, user),
                  ),
                  SliverToBoxAdapter(
                    child: BlocBuilder<ProjectBloc, ProjectState>(
                      builder: (context, state) => Column(
                        children: [
                          _buildPendingApprovals(context, state),
                          _buildQuickStats(context, state),
                        ],
                      ),
                    ).animateEntrance(delayMs: 200),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(child: _buildProjectHeader(context)),
                  SliverToBoxAdapter(child: _buildProjectGrid(context, user)),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectGrid(BuildContext context, UserEntity user) {
    return BlocBuilder<ProjectBloc, ProjectState>(
      builder: (context, state) {
        if (state.isInitialLoading && state.projects.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: CustomLoading(),
          );
        }

        if (!state.isInitialLoading && state.projects.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: state.projects.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.projects.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final project = state.projects[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child:
                  ProjectCard(
                        project: project,
                        onTap: () => context.pushNamed(
                          AppRouter.projectDetails,
                          extra: project,
                          pathParameters: {'id': project.id},
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (500 + (index % 10 * 50)).ms)
                      .slideY(begin: 0.1, curve: Curves.easeOutCubic),
            );
          },
        );
      },
    );
  }

  Widget _buildProjectHeader(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ProjectSectionHeader(
        title: LangKeys.allProjects.tr(),
        color: context.primary,
        icon: Ionicons.grid_outline,
      ).animateEntrance(delayMs: 500),
    );
  }

  Widget _buildPersonalizedHeader(BuildContext context, UserEntity user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LangKeys.hello.tr(args: [user.name.split(' ').first]),
                      style: context.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        fontSize: 32,
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
                    const SizedBox(height: 6),
                    Text(
                          user.role == UserRole.admin
                              ? LangKeys.managingOrganizationalProjects.tr()
                              : LangKeys.exploreProjectsTasks.tr(),
                          style: TextStyle(
                            color: context.onSurface.withOpacity(0.45),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 100.ms)
                        .slideX(begin: -0.1),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => context.goNamed(AppRouter.settings),
                child: Hero(
                  tag: 'user_avatar',
                  child: SharedProfileAvatar(
                    name: user.name,
                    radius: 28,
                    imageUrl: user.profile,
                    showBorder: true,
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms).scale(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, ProjectState state) {
    return Container(
      height: 170,
      margin: const EdgeInsets.only(bottom: 32),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildStatTile(
            context,
            icon: Ionicons.rocket_outline,
            label: LangKeys.activeProjects.tr(),
            value: '$_activeProjects',
            color: context.primary,
            delayMs: 200,
          ),
          const SizedBox(width: 16),
          _buildStatTile(
            context,
            icon: Ionicons.checkmark_done_outline,
            label: LangKeys.finishedProjects.tr(),
            value: '$_finishedProjects',
            color: context.mintGreen,
            delayMs: 300,
          ),
          const SizedBox(width: 16),
          _buildStatTile(
            context,
            icon: Ionicons.close_circle_outline,
            label: LangKeys.canceledProjects.tr(),
            value: '$_canceledProjects',
            color: context.error.withOpacity(0.75),
            delayMs: 400,
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    int delayMs = 0,
  }) {
    return SizedBox(
          width: 160,
          child: PremiumCard(
            borderRadius: 32,
            padding: const EdgeInsets.all(16), // Reduced padding
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.15)),
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const SizedBox(height: 12), // Reduced spacing
                  Text(
                    value,
                    style: TextStyle(
                      color: context.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2), // Reduced spacing
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: context.onSurface.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: delayMs.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }

  Widget _buildNotificationIcon(BuildContext context, UserEntity user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.docs.length ?? 0;

        return InkWell(
          onTap: () => context.pushNamed(AppRouter.notifications),
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Ionicons.notifications_outline, size: 24),
              if (unreadCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.cube_outline,
              size: 60,
              color: context.onBackground.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Text(
              LangKeys.noProjectsFound.tr(),
              style: TextStyle(color: context.onBackground.withOpacity(0.3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovals(BuildContext context, ProjectState state) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = (authState is Authenticated) ? authState.user.id : '';

    // Filter requests to only show those that require the current user's approval
    final filteredRequests = state.pendingRequests
        .where((r) => r.requiredApproverIds.contains(currentUserId))
        .toList();

    if (filteredRequests.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ProjectSectionHeader(
              title: LangKeys.pendingApprovals.tr(),
              color: context.primary,
            ).animateEntrance(delayMs: 500),
          ),
          const SizedBox(height: 17),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: filteredRequests.map((request) {
                return ApprovalRequestCard(
                  request: request,
                  margin: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
