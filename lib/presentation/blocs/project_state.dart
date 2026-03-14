import 'package:equatable/equatable.dart';
import '../../domain/entities/entities.dart';

abstract class ProjectState extends Equatable {
  final String? currentUserId;
  final UserRole? currentUserRole;
  final List<ProjectEntity> projects;
  final List<RequestEntity> pendingRequests;
  final bool hasMore;
  final dynamic lastDoc;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool isRequestsLoading;

  const ProjectState({
    this.currentUserId,
    this.currentUserRole,
    this.projects = const [],
    this.pendingRequests = const [],
    this.hasMore = true,
    this.lastDoc,
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.isRequestsLoading = false,
  });

  ProjectState copyWith({
    String? currentUserId,
    UserRole? currentUserRole,
    List<ProjectEntity>? projects,
    List<RequestEntity>? pendingRequests,
    bool? hasMore,
    dynamic lastDoc,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? isRequestsLoading,
  }) {
    return ProjectStateInstance(
      currentUserId: currentUserId ?? this.currentUserId,
      currentUserRole: currentUserRole ?? this.currentUserRole,
      projects: projects ?? this.projects,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: lastDoc ?? this.lastDoc,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRequestsLoading: isRequestsLoading ?? this.isRequestsLoading,
    );
  }

  @override
  List<Object?> get props => [
    currentUserId,
    currentUserRole,
    projects,
    pendingRequests,
    hasMore,
    lastDoc,
    isInitialLoading,
    isLoadingMore,
    isRequestsLoading,
  ];
}

class ProjectStateInstance extends ProjectState {
  const ProjectStateInstance({
    super.currentUserId,
    super.currentUserRole,
    super.projects,
    super.pendingRequests,
    super.hasMore,
    super.lastDoc,
    super.isInitialLoading,
    super.isLoadingMore,
    super.isRequestsLoading,
  });
}

class ProjectInitial extends ProjectState {
  const ProjectInitial({
    super.currentUserId,
    super.currentUserRole,
    super.projects,
    super.pendingRequests,
    super.hasMore,
    super.lastDoc,
    super.isInitialLoading,
    super.isLoadingMore,
    super.isRequestsLoading,
  });
}

class ProjectLoading extends ProjectState {
  const ProjectLoading({
    super.currentUserId,
    super.currentUserRole,
    super.projects,
    super.pendingRequests,
    super.hasMore,
    super.lastDoc,
    super.isInitialLoading,
    super.isLoadingMore,
    super.isRequestsLoading,
  });
}

class ProjectError extends ProjectState {
  final String message;
  const ProjectError(
    this.message, {
    super.currentUserId,
    super.currentUserRole,
    super.projects,
    super.pendingRequests,
    super.hasMore,
    super.lastDoc,
    super.isInitialLoading,
    super.isLoadingMore,
    super.isRequestsLoading,
  });

  @override
  List<Object?> get props => [...super.props, message];
}
