import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ionicons/ionicons.dart';
import '../../core/localization/lang_keys.dart';
import '../../core/navigation/app_router.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_state.dart';
import '../blocs/archive_bloc.dart';
import '../widgets/project_card.dart';
import '../widgets/custom_loading.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/shared_smart_refresher.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../../core/theme/theme_ext.dart';

class ArchivedProjectsScreen extends StatefulWidget {
  const ArchivedProjectsScreen({super.key});

  @override
  State<ArchivedProjectsScreen> createState() => _ArchivedProjectsScreenState();
}

class _ArchivedProjectsScreenState extends State<ArchivedProjectsScreen> {
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    _loadArchived();
  }

  void _loadArchived() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<ArchiveBloc>().add(
        LoadArchivedProjects(
          userId: authState.user.id,
          role: authState.user.role,
        ),
      );
    }
  }

  Future<void> _onLoading() async {
    final state = context.read<ArchiveBloc>().state;
    if (!state.hasMore) {
      _refreshController.loadNoData();
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<ArchiveBloc>().add(
        LoadMoreArchivedProjects(
          userId: authState.user.id,
          role: authState.user.role,
        ),
      );
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ArchiveBloc, ArchiveState>(
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
      child: Scaffold(
        backgroundColor: context.background,
        appBar: SharedAppBar(
          title: LangKeys.archivedProjects.tr(),
          showBackButton: true,
        ),
        body: BlocBuilder<ArchiveBloc, ArchiveState>(
          builder: (context, state) {
            if (state.isInitialLoading && state.projects.isEmpty) {
              return const Center(child: CustomLoading());
            }

            if (state.projects.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Ionicons.archive_outline,
                      size: 60,
                      color: context.onBackground.withOpacity(0.1),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      LangKeys.noProjectsFound.tr(),
                      style: TextStyle(
                        color: context.onBackground.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width > 1000 ? 3 : (width > 600 ? 2 : 1);
                final horizontalPadding = width > 1200 ? (width - 1000) / 2 : 24.0;

                return SharedSmartRefresher(
                  controller: _refreshController,
                  onRefresh: () async => _loadArchived(),
                  onLoading: _onLoading,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 24,
                        ),
                        sliver: SliverMasonryGrid.count(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          itemBuilder: (context, index) {
                            if (index >= state.projects.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CustomLoading(size: 20),
                                ),
                              );
                            }

                            final project = state.projects[index];
                            return ProjectCard(
                              project: project,
                              onTap: () => context.pushNamed(
                                AppRouter.projectDetails,
                                pathParameters: {'id': project.id},
                                extra: project,
                              ),
                              trailing: IconButton(
                                onPressed: () {
                                  context.read<ArchiveBloc>().add(
                                        UnarchiveProject(projectId: project.id),
                                      );
                                },
                                icon: const Icon(Ionicons.refresh_outline, size: 20),
                                tooltip: LangKeys.unarchive.tr(),
                                style: IconButton.styleFrom(
                                  foregroundColor: context.primary,
                                  backgroundColor: context.primary.withOpacity(0.1),
                                ),
                              ),
                            ).animate().fadeIn(delay: (100 * (index % 6)).ms);
                          },
                          childCount: state.projects.length + (state.hasMore ? 1 : 0),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
