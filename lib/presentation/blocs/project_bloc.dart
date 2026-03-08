import 'package:flutter_bloc/flutter_bloc.dart';
import 'project_event.dart';
import 'project_state.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/repositories/auth_repository.dart';

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
  }

  void _onCreateProject(CreateProject event, Emitter<ProjectState> emit) async {
    final newProject = ProjectEntity(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      title: event.title,
      description: event.description,
      creatorId: event.creatorId,
      supervisorIds: const [],
      managerIds: const [],
      clientIds: const [],
      assignedUserIds: [event.creatorId], // Creator is always assigned
      status: ProjectStatus.inProgress,
      createdAt: DateTime.now(),
    );

    await _projectRepository.createProject(newProject);
  }

  void _onAddTask(AddTask event, Emitter<ProjectState> emit) async {
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
    );

    await _projectRepository.addTask(event.projectId, newTask);
  }

  void _onUpdateTaskStatus(
    UpdateTaskStatus event,
    Emitter<ProjectState> emit,
  ) async {
    final status = TaskStatus.values.firstWhere(
      (e) => e.name == event.status,
      orElse: () => TaskStatus.pending,
    );

    await _projectRepository.updateTaskStatus(
      event.projectId,
      event.taskId,
      status,
      userId: event.userId,
    );
  }

  void _onAddActivity(AddActivity event, Emitter<ProjectState> emit) async {
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
  }

  void _onApproveTask(ApproveTask event, Emitter<ProjectState> emit) async {
    await _projectRepository.approveTask(
      event.projectId,
      event.taskId,
      userId: event.userId,
    );
  }

  Future<void> _onRejectTask(
    RejectTask event,
    Emitter<ProjectState> emit,
  ) async {
    try {
      await _projectRepository.rejectTask(
        event.projectId,
        event.taskId,
        userId: event.userId,
      );
    } catch (_) {}
  }

  void _onUpdateTaskDeadline(
    UpdateTaskDeadline event,
    Emitter<ProjectState> emit,
  ) async {
    await _projectRepository.updateTaskDeadline(
      event.projectId,
      event.taskId,
      event.deadline,
      userId: event.userId,
    );
  }

  void _onUpdateProjectUsers(
    UpdateProjectUsers event,
    Emitter<ProjectState> emit,
  ) async {
    await _projectRepository.updateProjectUsers(
      projectId: event.projectId,
      supervisorIds: event.supervisorIds,
      managerIds: event.managerIds,
      clientIds: event.clientIds,
    );
  }

  void _onAddAttachment(AddAttachment event, Emitter<ProjectState> emit) async {
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
    } catch (e) {
      // Handle error
    }
  }

  void _onUpdateProjectStatus(
    UpdateProjectStatus event,
    Emitter<ProjectState> emit,
  ) async {
    await _projectRepository.updateProjectStatus(event.projectId, event.status);
  }
}
