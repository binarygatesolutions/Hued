import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_pagination/firebase_pagination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
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
import 'package:hued/core/utils/animations.dart';

int _activeProjects = 0;
int _finishedProjects = 0;
int _canceledProjects = 0;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Key _paginationKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      getStatistics();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onRefresh(UserEntity user) async {
    setState(() {
      _paginationKey = UniqueKey();
    });
    await getStatistics();
  }

  Future<void> getStatistics() async {
    final projectsCollection = FirebaseFirestore.instance.collection(
      'projects',
    );

    final results = await Future.wait([
      projectsCollection
          .where('status', isEqualTo: ProjectStatus.finished.name)
          .count()
          .get(),
      projectsCollection
          .where('status', isEqualTo: ProjectStatus.inProgress.name)
          .count()
          .get(),
      projectsCollection
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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          getStatistics();
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            final user = state.user;

            return Scaffold(
              backgroundColor: context.background,
              floatingActionButton:
                  (user.role == UserRole.admin ||
                      user.role == UserRole.supervisor)
                  ? FloatingActionButton.extended(
                      onPressed: () => context.pushNamed(AppRouter.addProject),
                      backgroundColor: context.primary,
                      icon: Icon(Ionicons.add, color: context.surface),
                      label: Text(
                        LangKeys.newProject.tr(),
                        style: TextStyle(
                          color: context.surface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ).animateScale(delayMs: 400)
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
          // Mesh Gradient Blobs
          if (isDark)
            Positioned(
              top: -150,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  color: context.primary.withOpacity(isDark ? 0.08 : 0.04),
                  shape: BoxShape.circle,
                ),
              ).animateFade(),
            ),
          if (isDark)
            Positioned(
              top: 200,
              left: -150,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  color: context.purple.withOpacity(isDark ? 0.05 : 0.03),
                  shape: BoxShape.circle,
                ),
              ).animateFade(),
            ),
          // Blur layer for mesh blobs
          if (isDark)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),

          // Main Content
          Positioned.fill(
            child: BlocBuilder<ProjectBloc, ProjectState>(
              builder: (context, state) {
                return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _onRefresh(user),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  24,
                                  MediaQuery.of(context).viewPadding.top + 20,
                                  24,
                                  0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        SharedAppLogo(height: 20),
                                        SizedBox(width: 7),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: context.primary.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: context.primary
                                                  .withOpacity(0.2),
                                            ),
                                          ),
                                          child: Text(
                                            user.role.name.toUpperCase(),
                                            style: TextStyle(
                                              color: context.primary,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    _buildNotificationIcon(context, user),
                                  ],
                                ),
                              ),
                              _buildPersonalizedHeader(context, user),
                              _buildQuickStats(context, state),
                              const SizedBox(height: 16),
                              _buildProjectHeader(context),
                              _buildProjectGrid(context, user),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectGrid(BuildContext context, UserEntity user) {
    Query query = FirebaseFirestore.instance
        .collection('projects')
        .orderBy('createdAt', descending: true);

    if (user.role != UserRole.admin) {
      query = query.where('assignedUserIds', arrayContains: user.id);
    }

    return FirestorePagination(
      key: _paginationKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      query: query,
      itemBuilder: (context, snapshots, index) {
        final data = snapshots[index].data() as Map<String, dynamic>;
        data['id'] = snapshots[index].id;
        final project = ProjectEntity.fromJson(data);

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
                  .fadeIn(delay: (index % 10 * 50).ms)
                  .slideY(begin: 0.1, curve: Curves.easeOutCubic),
        );
      },
      initialLoader: const CustomLoading(),
      bottomLoader: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      onEmpty: _buildEmptyState(context),
    );
  }

  Widget _buildProjectHeader(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return const SizedBox.shrink();
    final user = authState.user;

    Query countQuery = FirebaseFirestore.instance.collection('projects');
    if (user.role != UserRole.admin) {
      countQuery = countQuery.where('assignedUserIds', arrayContains: user.id);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FutureBuilder<AggregateQuerySnapshot>(
        future: countQuery.count().get(),
        builder: (context, snapshot) {
          final count = snapshot.data?.count ?? 0;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    LangKeys.allProjects.tr(),
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: context.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPersonalizedHeader(BuildContext context, UserEntity user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LangKeys.hello.tr(args: [user.name.split(' ').first]),
                  style: context.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ).animateEntrance(),
                const SizedBox(height: 8),
                Text(
                  user.role == UserRole.admin
                      ? LangKeys.managingOrganizationalProjects.tr()
                      : LangKeys.exploreProjectsTasks.tr(),
                  style: TextStyle(
                    color: context.onSurface.withOpacity(0.5),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ).animateEntrance(delayMs: 100),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => context.goNamed(AppRouter.settings),
            child: SharedProfileAvatar(
              name: user.name,
              radius: 24,
              imageUrl: user.profile,
              showBorder: true,
            ).animateScale(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, ProjectState state) {
    return Container(
      height: 156,
      margin: const EdgeInsets.only(bottom: 24),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildStatTile(
            context,
            icon: Ionicons.rocket_outline,
            label: LangKeys.activeProjects.tr(),
            value: '$_activeProjects',
            color: context.primary,
          ),
          const SizedBox(width: 16),
          _buildStatTile(
            context,
            icon: Ionicons.checkmark_done_outline,
            label: LangKeys.finishedProjects.tr(),
            value: '$_finishedProjects',
            color: context.mintGreen,
          ),
          const SizedBox(width: 16),
          _buildStatTile(
            context,
            icon: Ionicons.close_circle_outline,
            label: LangKeys.canceledProjects.tr(),
            value: '$_canceledProjects',
            color: context.error.withOpacity(0.75),
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
  }) {
    return SizedBox(
      width: 156,
      child: PremiumCard(
        borderRadius: 28,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                color: context.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: context.onSurface.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animateScale();
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
}
