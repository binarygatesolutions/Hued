import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/project_repository.dart';

// Events
abstract class ArchiveEvent extends Equatable {
  const ArchiveEvent();
  @override
  List<Object?> get props => [];
}

class LoadArchivedProjects extends ArchiveEvent {
  final String? userId;
  final UserRole? role;
  final int limit;

  const LoadArchivedProjects({this.userId, this.role, this.limit = 10});

  @override
  List<Object?> get props => [userId, role, limit];
}

class LoadMoreArchivedProjects extends ArchiveEvent {
  final String? userId;
  final UserRole? role;
  final int limit;

  const LoadMoreArchivedProjects({this.userId, this.role, this.limit = 10});

  @override
  List<Object?> get props => [userId, role, limit];
}

class UnarchiveProject extends ArchiveEvent {
  final String projectId;

  const UnarchiveProject({required this.projectId});

  @override
  List<Object?> get props => [projectId];
}

// State
class ArchiveState extends Equatable {
  final List<ProjectEntity> projects;
  final bool hasMore;
  final dynamic lastDoc;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  const ArchiveState({
    this.projects = const [],
    this.hasMore = true,
    this.lastDoc,
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  factory ArchiveState.initial() => const ArchiveState();

  ArchiveState copyWith({
    List<ProjectEntity>? projects,
    bool? hasMore,
    dynamic lastDoc,
    bool? isInitialLoading,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return ArchiveState(
      projects: projects ?? this.projects,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    projects,
    hasMore,
    lastDoc,
    isInitialLoading,
    isLoadingMore,
    errorMessage,
  ];
}

// BLoC
class ArchiveBloc extends Bloc<ArchiveEvent, ArchiveState> {
  final ProjectRepository _projectRepository;

  ArchiveBloc({required ProjectRepository projectRepository})
    : _projectRepository = projectRepository,
      super(ArchiveState.initial()) {
    on<LoadArchivedProjects>(_onLoadArchivedProjects);
    on<LoadMoreArchivedProjects>(_onLoadMoreArchivedProjects);
    on<UnarchiveProject>(_onUnarchiveProject);
  }

  Future<void> _onLoadArchivedProjects(
    LoadArchivedProjects event,
    Emitter<ArchiveState> emit,
  ) async {
    emit(
      state.copyWith(
        isInitialLoading: true,
        projects: [],
        hasMore: true,
        lastDoc: null,
      ),
    );

    try {
      final result = await _projectRepository.getPaginatedProjects(
        limit: event.limit,
        userId: event.userId,
        role: event.role,
        status: ProjectStatus.archived,
      );

      emit(
        state.copyWith(
          projects: result.projects,
          hasMore: result.hasMore,
          lastDoc: result.lastDoc,
          isInitialLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isInitialLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadMoreArchivedProjects(
    LoadMoreArchivedProjects event,
    Emitter<ArchiveState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final result = await _projectRepository.getPaginatedProjects(
        limit: event.limit,
        lastDocument: state.lastDoc,
        userId: event.userId,
        role: event.role,
        status: ProjectStatus.archived,
      );

      emit(
        state.copyWith(
          projects: [...state.projects, ...result.projects],
          hasMore: result.hasMore,
          lastDoc: result.lastDoc,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onUnarchiveProject(
    UnarchiveProject event,
    Emitter<ArchiveState> emit,
  ) async {
    try {
      await _projectRepository.updateProjectStatus(
        event.projectId,
        ProjectStatus.inProgress, // Default status when unarchived
      );

      final updatedProjects = state.projects
          .where((p) => p.id != event.projectId)
          .toList();

      emit(state.copyWith(projects: updatedProjects));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
