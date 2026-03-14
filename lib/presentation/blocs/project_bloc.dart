import 'package:flutter_bloc/flutter_bloc.dart';
import 'project_event.dart';
import 'project_state.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import 'helpers/approval_logic_helper.dart';

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final ProjectRepository _projectRepository;

  ProjectBloc({
    required ProjectRepository projectRepository,
    required AuthRepository authRepository,
  }) : _projectRepository = projectRepository,
       super(ProjectInitial()) {
    on<CreateProject>(_onCreateProject);
    on<AddTask>(_onAddTask);
    on<UpdateTaskStatus>(_onUpdateTaskStatus);
    on<ApproveTask>(_onApproveTask);
    on<RejectTask>(_onRejectTask);
    on<UpdateTaskDeadline>(_onUpdateTaskDeadline);
    on<AddActivity>(_onAddActivity);
    on<AddAttachment>(_onAddAttachment);
    on<UpdateProjectUsers>(_onUpdateProjectUsers);
    on<UpdateProjectStatus>(_onUpdateProjectStatus);
    on<AssignWorkersToTask>(_onAssignWorkersToTask);
    on<LoadProjects>(_onLoadProjects);
    on<LoadMoreProjects>(_onLoadMoreProjects);
    on<CreateRequest>(_onCreateRequest);
    on<LoadPendingRequests>(_onLoadPendingRequests);
    on<UpdateRequestStatusEvent>(_onUpdateRequestStatus);
    on<RequestsUpdated>(_onRequestsUpdated);
  }

  void _onCreateProject(CreateProject event, Emitter<ProjectState> emit) async {
    emit(
      ProjectLoading(
        currentUserId: state.currentUserId,
        currentUserRole: state.currentUserRole,
        projects: state.projects,
        pendingRequests: state.pendingRequests,
        hasMore: state.hasMore,
        lastDoc: state.lastDoc,
      ),
    );
    try {
      final newProject = ProjectEntity(
        id: 'p_${DateTime.now().millisecondsSinceEpoch}',
        title: event.title,
        description: event.description,
        creatorId: event.creatorId,
        supervisorIds: [event.creatorId],
        managerIds: const [],
        clientIds: const [],
        workerIds: const [],
        assignedUserIds: [event.creatorId],
        status: ProjectStatus.inProgress,
        createdAt: DateTime.now(),
      );

      await _projectRepository.createProject(newProject);
      add(
        LoadProjects(userId: state.currentUserId, role: state.currentUserRole),
      );
    } catch (e) {
      emit(
        ProjectError(
          e.toString(),
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    }
  }

  void _onAddTask(AddTask event, Emitter<ProjectState> emit) async {
    emit(
      ProjectLoading(
        currentUserId: state.currentUserId,
        currentUserRole: state.currentUserRole,
        projects: state.projects,
        pendingRequests: state.pendingRequests,
        hasMore: state.hasMore,
        lastDoc: state.lastDoc,
      ),
    );
    try {
      final newTask = TaskEntity(
        id: 't_${DateTime.now().millisecondsSinceEpoch}',
        projectId: event.projectId,
        title: event.title,
        description: event.description,
        status: TaskStatus.pending,
        priority: TaskPriority.values.firstWhere(
          (e) => e.name == event.priority,
          orElse: () => TaskPriority.medium,
        ),
        deadline: event.deadline,
        createdAt: DateTime.now(),
        creatorId: event.creatorId,
        isApproved: event.isApproved,
        assignedWorkerIds: event.assignedWorkerIds,
      );

      await _projectRepository.addTask(event.projectId, newTask);
      emit(
        ProjectInitial(
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    } catch (e) {
      emit(
        ProjectError(
          e.toString(),
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    }
  }

  void _onUpdateTaskStatus(
    UpdateTaskStatus event,
    Emitter<ProjectState> emit,
  ) async {
    emit(
      ProjectLoading(
        currentUserId: state.currentUserId,
        currentUserRole: state.currentUserRole,
        projects: state.projects,
        pendingRequests: state.pendingRequests,
        hasMore: state.hasMore,
        lastDoc: state.lastDoc,
      ),
    );
    try {
      final status = TaskStatus.values.firstWhere(
        (e) => e.name == event.status,
        orElse: () => TaskStatus.pending,
      );

      // --- SEQUENTIAL APPROVAL LOGIC ---
      final role = state.currentUserRole;
      final isRequestableStatus =
          status == TaskStatus.completed || status == TaskStatus.cancelled;

      if (isRequestableStatus && role != UserRole.client) {
        final projects = await _projectRepository.getProjects();
        final project = projects.firstWhere((p) => p.id == event.projectId);

        final request = ApprovalLogicHelper.generateRequest(
          projectId: event.projectId,
          taskId: event.taskId,
          userId: event.userId,
          role: role!,
          type: RequestType.taskStatus,
          targetValue: event.status,
          project: project,
        );

        if (request != null) {
          await _projectRepository.createRequest(request);
          emit(ProjectInitial(
            currentUserId: state.currentUserId,
            currentUserRole: state.currentUserRole,
            projects: state.projects,
            pendingRequests: state.pendingRequests,
          ));
          return;
        }
      }
      // --- END LOGIC ---

      await _projectRepository.updateTaskStatus(
        event.projectId,
        event.taskId,
        status,
        userId: event.userId,
      );
      add(
        LoadProjects(userId: state.currentUserId, role: state.currentUserRole),
      );
    } catch (e) {
      emit(
        ProjectError(
          e.toString(),
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    }
  }

  void _onAddActivity(AddActivity event, Emitter<ProjectState> emit) async {
    emit(
      ProjectLoading(
        currentUserId: state.currentUserId,
        currentUserRole: state.currentUserRole,
        projects: state.projects,
        pendingRequests: state.pendingRequests,
        hasMore: state.hasMore,
        lastDoc: state.lastDoc,
      ),
    );
    try {
      final newActivity = ActivityEntity(
        id: 'activity_${DateTime.now().millisecondsSinceEpoch}',
        userId: event.userId,
        content: event.content,
        type: event.type,
        createdAt: DateTime.now(),
      );

      await _projectRepository.addActivity(
        event.projectId,
        event.taskId,
        newActivity,
      );
      emit(
        ProjectInitial(
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    } catch (e) {
      emit(
        ProjectError(
          e.toString(),
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    }
  }

  void _onApproveTask(ApproveTask event, Emitter<ProjectState> emit) async {
    emit(
      ProjectLoading(
        currentUserId: state.currentUserId,
        currentUserRole: state.currentUserRole,
        projects: state.projects,
        pendingRequests: state.pendingRequests,
        hasMore: state.hasMore,
        lastDoc: state.lastDoc,
      ),
    );
    try {
      await _projectRepository.approveTask(
        event.projectId,
        event.taskId,
        userId: event.userId,
      );
      emit(
        ProjectInitial(
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    } catch (e) {
      emit(
        ProjectError(
          e.toString(),
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    }
  }

  Future<void> _onRejectTask(
    RejectTask event,
    Emitter<ProjectState> emit,
  ) async {
    emit(
      ProjectLoading(
        currentUserId: state.currentUserId,
        currentUserRole: state.currentUserRole,
        projects: state.projects,
        pendingRequests: state.pendingRequests,
        hasMore: state.hasMore,
        lastDoc: state.lastDoc,
      ),
    );
    try {
      await _projectRepository.rejectTask(
        event.projectId,
        event.taskId,
        userId: event.userId,
      );
      emit(
        ProjectInitial(
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    } catch (e) {
      emit(
        ProjectError(
          e.toString(),
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    }
  }

  void _onUpdateTaskDeadline(
    UpdateTaskDeadline event,
    Emitter<ProjectState> emit,
  ) async {
    emit(
      ProjectLoading(
        currentUserId: state.currentUserId,
        currentUserRole: state.currentUserRole,
        projects: state.projects,
        pendingRequests: state.pendingRequests,
        hasMore: state.hasMore,
        lastDoc: state.lastDoc,
      ),
    );
    try {
      final role = state.currentUserRole;

      if (role != UserRole.client) {
        final projects = await _projectRepository.getProjects();
        final project = projects.firstWhere((p) => p.id == event.projectId);
        final tasks = await _projectRepository.getTasks(event.projectId);
        final task = tasks.firstWhere((t) => t.id == event.taskId);

        // ONLY require approval if the task is already approved
        if (task.isApproved) {
          final request = ApprovalLogicHelper.generateRequest(
            projectId: event.projectId,
            taskId: event.taskId,
            userId: event.userId,
            role: role!,
            type: RequestType.taskDeadline,
            targetValue: event.deadline.toIso8601String(),
            project: project,
          );

          if (request != null) {
            await _projectRepository.createRequest(request);
            emit(ProjectInitial(
              currentUserId: state.currentUserId,
              currentUserRole: state.currentUserRole,
              projects: state.projects,
              pendingRequests: state.pendingRequests,
            ));
            return;
          }
        }
      }

      await _projectRepository.updateTaskDeadline(
        event.projectId,
        event.taskId,
        event.deadline,
        userId: event.userId,
      );
      emit(
        ProjectInitial(
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    } catch (e) {
      emit(
        ProjectError(
          e.toString(),
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
        ),
      );
    }
  }

  void _onUpdateProjectUsers(
    UpdateProjectUsers event,
    Emitter<ProjectState> emit,
  ) async {
    emit(
      ProjectLoading(
        currentUserId: state.currentUserId,
        currentUserRole: state.currentUserRole,
        projects: state.projects,
        pendingRequests: state.pendingRequests,
        hasMore: state.hasMore,
        lastDoc: state.lastDoc,
      ),
    );
    try {
      await _projectRepository.updateProjectUsers(
        projectId: event.projectId,
        supervisorIds: event.supervisorIds,
        managerIds: event.managerIds,
        clientIds: event.clientIds,
        workerIds: event.workerIds,
        workerManagerMap: event.workerManagerMap,
      );
      add(
        LoadProjects(userId: state.currentUserId, role: state.currentUserRole),
      );
    } catch (e) {
      emit(
        ProjectError(
          e.toString(),
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    }
  }

  void _onAssignWorkersToTask(
    AssignWorkersToTask event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      await _projectRepository.assignWorkersToTask(
        event.projectId,
        event.taskId,
        event.workerIds,
      );
      emit(
        ProjectInitial(
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    } catch (e) {
      emit(
        ProjectError(
          e.toString(),
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    }
  }

  void _onAddAttachment(AddAttachment event, Emitter<ProjectState> emit) async {
    emit(
      ProjectLoading(
        currentUserId: state.currentUserId,
        currentUserRole: state.currentUserRole,
        projects: state.projects,
        pendingRequests: state.pendingRequests,
        hasMore: state.hasMore,
        lastDoc: state.lastDoc,
      ),
    );
    try {
      final url = await _projectRepository.uploadImage(
        event.projectId,
        event.taskId,
        event.file,
      );

      await _projectRepository.addAttachment(
        event.projectId,
        event.taskId,
        AttachmentEntity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          url: url,
          userId: event.userId,
          createdAt: DateTime.now(),
        ),
      );
      emit(
        ProjectInitial(
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    } catch (e) {
      emit(
        ProjectError(
          e.toString(),
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    }
  }

  void _onUpdateProjectStatus(
    UpdateProjectStatus event,
    Emitter<ProjectState> emit,
  ) async {
    emit(
      ProjectLoading(
        currentUserId: state.currentUserId,
        currentUserRole: state.currentUserRole,
        projects: state.projects,
        pendingRequests: state.pendingRequests,
        hasMore: state.hasMore,
        lastDoc: state.lastDoc,
      ),
    );
    try {
      // --- SEQUENTIAL APPROVAL LOGIC ---
      final role = state.currentUserRole;
      if (event.status == ProjectStatus.finished && role != UserRole.client) {
        final projects = await _projectRepository.getProjects();
        final project = projects.firstWhere((p) => p.id == event.projectId);

        final request = ApprovalLogicHelper.generateRequest(
          projectId: event.projectId,
          taskId: '', // No task for project status
          userId: event.userId,
          role: role!,
          type: RequestType.projectStatus,
          targetValue: event.status.name,
          project: project,
        );

        if (request != null) {
          await _projectRepository.createRequest(request);
          emit(ProjectInitial(
            currentUserId: state.currentUserId,
            currentUserRole: state.currentUserRole,
            projects: state.projects,
            pendingRequests: state.pendingRequests,
          ));
          return;
        }
      }
      // --- END LOGIC ---

      await _projectRepository.updateProjectStatus(
        event.projectId,
        event.status,
      );
      add(
        LoadProjects(userId: state.currentUserId, role: state.currentUserRole),
      );
    } catch (e) {
      emit(
        ProjectError(
          e.toString(),
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    }
  }

  Future<void> _onLoadProjects(
    LoadProjects event,
    Emitter<ProjectState> emit,
  ) async {
    final clearProjects =
        event.userId != null && event.userId != state.currentUserId;

    emit(
      ProjectLoading(
        currentUserId: event.userId ?? state.currentUserId,
        currentUserRole: event.role ?? state.currentUserRole,
        projects: clearProjects ? const [] : state.projects,
        pendingRequests: state.pendingRequests,
        hasMore: true,
        lastDoc: null,
        isInitialLoading: true,
      ),
    );

    try {
      final result = await _projectRepository.getPaginatedProjects(
        limit: event.limit,
        userId: event.userId ?? state.currentUserId,
        role: event.role ?? state.currentUserRole,
        status: event.status,
      );

      emit(
        ProjectInitial(
          currentUserId: event.userId ?? state.currentUserId,
          currentUserRole: event.role ?? state.currentUserRole,
          projects: result.projects,
          pendingRequests: state.pendingRequests,
          hasMore: result.hasMore,
          lastDoc: result.lastDoc,
          isInitialLoading: false,
        ),
      );
    } catch (e) {
      emit(
        ProjectError(
          e.toString(),
          currentUserId: event.userId ?? state.currentUserId,
          currentUserRole: event.role ?? state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    }
  }

  Future<void> _onLoadMoreProjects(
    LoadMoreProjects event,
    Emitter<ProjectState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore) return;

    emit(
      ProjectLoading(
        currentUserId: state.currentUserId,
        currentUserRole: state.currentUserRole,
        projects: state.projects,
        pendingRequests: state.pendingRequests,
        hasMore: state.hasMore,
        lastDoc: state.lastDoc,
        isLoadingMore: true,
      ),
    );

    try {
      final result = await _projectRepository.getPaginatedProjects(
        limit: event.limit,
        lastDocument: state.lastDoc,
        userId: event.userId ?? state.currentUserId,
        role: event.role ?? state.currentUserRole,
        status: event.status,
      );

      emit(
        ProjectInitial(
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: [...state.projects, ...result.projects],
          pendingRequests: state.pendingRequests,
          hasMore: result.hasMore,
          lastDoc: result.lastDoc,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(
        ProjectError(
          e.toString(),
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    }
  }

  void _onCreateRequest(CreateRequest event, Emitter<ProjectState> emit) async {
    try {
      await _projectRepository.createRequest(event.request);
    } catch (e) {
      emit(
        ProjectError(
          e.toString(),
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    }
  }

  void _onLoadPendingRequests(
    LoadPendingRequests event,
    Emitter<ProjectState> emit,
  ) {
    emit(state.copyWith(isRequestsLoading: true));
    _projectRepository.getPendingRequestsStream(event.userId).listen((
      requests,
    ) {
      add(RequestsUpdated(requests));
    });
  }

  void _onRequestsUpdated(RequestsUpdated event, Emitter<ProjectState> emit) {
    emit(state.copyWith(pendingRequests: event.requests, isRequestsLoading: false));
  }

  void _onUpdateRequestStatus(
    UpdateRequestStatusEvent event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      final updatedRequest = RequestEntity(
        id: event.request.id,
        projectId: event.request.projectId,
        taskId: event.request.taskId,
        initiatorId: event.request.initiatorId,
        initiatorRole: event.request.initiatorRole,
        type: event.request.type,
        targetStatus: event.request.targetStatus,
        currentStep: event.request.currentStep,
        status: event.approved
            ? RequestStatus.approved
            : RequestStatus.rejected,
        requiredApproverIds: event.request.requiredApproverIds,
        approvedBy: {
          ...event.request.approvedBy,
          if (event.approved) event.request.currentStep.name: event.userId,
        },
        createdAt: event.request.createdAt,
        rejectionReason: event.rejectionReason,
      );

      await _projectRepository.updateRequest(updatedRequest);
    } catch (e) {
      emit(
        ProjectError(
          e.toString(),
          currentUserId: state.currentUserId,
          currentUserRole: state.currentUserRole,
          projects: state.projects,
          pendingRequests: state.pendingRequests,
          hasMore: state.hasMore,
          lastDoc: state.lastDoc,
        ),
      );
    }
  }
}
