import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../presentation/blocs/auth_bloc.dart';
import '../../presentation/blocs/auth_state.dart';
import '../localization/lang_keys.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/register_screen.dart';
import '../../presentation/screens/forgot_password_screen.dart';
import '../../presentation/screens/dashboard_screen.dart';
import '../../presentation/screens/admin_user_management_screen.dart';
import '../../presentation/screens/project_detail_screen.dart';
import '../../presentation/screens/add_task_screen.dart';
import '../../presentation/screens/statistics_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/update_profile_screen.dart';
import '../../presentation/screens/task_detail_screen.dart';
import '../../presentation/screens/notifications_screen.dart';
import '../../presentation/screens/add_project_screen.dart';
import '../../presentation/screens/manage_project_users_screen.dart';
import '../../presentation/screens/timeline_screen.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/archived_projects_screen.dart';
import '../../presentation/screens/project_tasks_screen.dart';
import '../../presentation/screens/manage_specialties_screen.dart';
import '../../presentation/widgets/main_shell.dart';
import '../../presentation/blocs/activity_bloc.dart';
import '../../presentation/blocs/specialty_bloc.dart';
import '../../presentation/blocs/sync_bloc.dart';
import '../../presentation/blocs/sync_event.dart';
import '../../core/utils/injection_container.dart';
import '../../domain/entities/entities.dart';

class AppRouter {
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';
  static const String dashboard = 'dashboard';
  static const String adminUsers = 'admin-users';
  static const String projectDetails = 'project-details';
  static const String addProject = 'addProject';
  static const String addTask = 'addTask';
  static const String statistics = 'statistics';
  static const String settings = 'settings';
  static const String aboutUs = 'about-us';
  static const String ourServices = 'our-services';
  static const String contactUs = 'contact-us';
  static const String updateProfile = 'updateProfile';
  static const String notifications = 'notifications';
  static const String manageUsers = 'manage-users';
  static const String archivedProjects = 'archived-projects';
  static const String manageSpecialties = 'manage-specialties';
  // static const String allProjects = 'all-projects';

  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: _GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final bool isSplash = state.uri.path == '/splash';
        final bool isAuthRoute =
            state.uri.path == '/' ||
            state.uri.path == '/register' ||
            state.uri.path == '/forgot-password';

        // 1. While determining auth status, stay on splash or auth pages
        if (authState is AuthInitial || authState is AuthLoading) {
          if (isSplash || isAuthRoute) return null;
          return null;
        }

        // 2. Not Authenticated
        if (authState is Unauthenticated || authState is AuthError) {
          if (isSplash) return '/'; // Go from splash to login
          return isAuthRoute ? null : '/';
        }

        // 3. Authenticated or Updating Profile
        if (authState is Authenticated || authState is AuthUpdatingProfile) {
          if (isSplash || isAuthRoute) {
            return '/dashboard';
          }
          return null;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/',
          name: login,
          builder: (context, state) => LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: register,
          builder: (context, state) => BlocProvider(
            create: (context) => sl<SpecialtyBloc>()..add(LoadSpecialties()),
            child: const RegisterScreen(),
          ),
        ),
        GoRoute(
          path: '/forgot-password',
          name: forgotPassword,
          builder: (context, state) => ForgotPasswordScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return BlocBuilder<AuthBloc, AuthState>(
              bloc: authBloc,
              builder: (context, authState) {
                UserEntity? userEntity;
                if (authState is Authenticated) {
                  userEntity = authState.user;
                }
                return MainShell(
                  navigationShell: navigationShell,
                  user: userEntity,
                );
              },
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard',
                  name: dashboard,
                  builder: (context, state) => const DashboardScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/statistics',
                  name: statistics,
                  builder: (context, state) => const StatisticsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/users',
                  name: adminUsers,
                  builder: (context, state) => BlocProvider(
                    create: (context) =>
                        sl<SpecialtyBloc>()..add(LoadSpecialties()),
                    child: const AdminUserManagementScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  name: settings,
                  builder: (context, state) => const SettingsScreen(),
                  routes: [
                    GoRoute(
                      path: 'profile',
                      name: updateProfile,
                      builder: (context, state) => const UpdateProfileScreen(),
                    ),
                    GoRoute(
                      path: 'archives',
                      name: archivedProjects,
                      builder: (context, state) =>
                          const ArchivedProjectsScreen(),
                    ),
                    GoRoute(
                      path: 'specialties',
                      name: manageSpecialties,
                      builder: (context, state) => BlocProvider(
                        create: (context) =>
                            sl<SpecialtyBloc>()..add(LoadSpecialties()),
                        child: const ManageSpecialtiesScreen(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/add-project',
          name: addProject,
          builder: (context, state) => const AddProjectScreen(),
        ),
        GoRoute(
          path: '/project/:id',
          name: projectDetails,
          builder: (context, state) {
            final project = state.extra as ProjectEntity;
            return MultiBlocProvider(
              providers: [
                BlocProvider<ActivityBloc>(
                  create: (context) => sl<ActivityBloc>(),
                ),
                BlocProvider<SyncBloc>(
                  create: (context) =>
                      sl<SyncBloc>()..add(MonitorProject(project.id)),
                ),
              ],
              child: ProjectDetailScreen(project: project),
            );
          },
          routes: [
            GoRoute(
              path: 'tasks',
              name: 'project-tasks',
              builder: (context, state) {
                final project = state.extra as ProjectEntity;
                return ProjectTasksScreen(project: project);
              },
            ),
            GoRoute(
              path: 'add-task',
              name: addTask,
              builder: (context, state) {
                final project = state.extra as ProjectEntity;
                return AddTaskScreen(project: project);
              },
            ),
            GoRoute(
              path: 'timeline',
              name: 'project-timeline',
              builder: (context, state) {
                final projectId = state.pathParameters['id']!;
                return TimelineScreen(projectId: projectId, title: LangKeys.project.tr());
              },
            ),
            GoRoute(
              path: 'task/:taskId',
              name: 'task-details',
              builder: (context, state) {
                final projectId = state.pathParameters['id']!;
                final taskId = state.pathParameters['taskId']!;

                return MultiBlocProvider(
                  providers: [
                    BlocProvider<ActivityBloc>(
                      create: (context) => sl<ActivityBloc>(),
                    ),
                    BlocProvider<SyncBloc>(
                      create: (context) =>
                          sl<SyncBloc>()..add(MonitorTask(projectId, taskId)),
                    ),
                  ],
                  child: TaskDetailScreen(projectId: projectId, taskId: taskId),
                );
              },
              routes: [
                GoRoute(
                  path: 'timeline',
                  name: 'task-timeline',
                  builder: (context, state) {
                    final projectId = state.pathParameters['id']!;
                    final taskId = state.pathParameters['taskId']!;
                    return TimelineScreen(
                      projectId: projectId,
                      taskId: taskId,
                      title: LangKeys.task.tr(),
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: 'manage-users',
              name: manageUsers,
              builder: (context, state) {
                final project = state.extra as ProjectEntity;
                return ManageProjectUsersScreen(project: project);
              },
            ),
          ],
        ),

        GoRoute(
          path: '/notifications',
          name: notifications,
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
    );
  }
}

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
