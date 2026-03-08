import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'sync_event.dart';
import 'sync_state.dart';
import '../../domain/repositories/project_repository.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final ProjectRepository _projectRepository;
  StreamSubscription? _subscription;

  SyncBloc({required ProjectRepository projectRepository})
    : _projectRepository = projectRepository,
      super(SyncInitial()) {
    on<MonitorProject>(_onMonitorProject);
    on<MonitorTask>(_onMonitorTask);
    on<_UpdateProject>(_onUpdateProject);
    on<_UpdateTask>(_onUpdateTask);
  }

  Future<void> _onMonitorProject(
    MonitorProject event,
    Emitter<SyncState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _projectRepository
        .getProjectStream(event.projectId)
        .listen((project) => add(_UpdateProject(project)));
  }

  Future<void> _onMonitorTask(
    MonitorTask event,
    Emitter<SyncState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _projectRepository
        .getTaskStream(event.projectId, event.taskId)
        .listen((task) => add(_UpdateTask(task)));
  }

  // Internal events to handle stream updates
  void _onUpdateProject(_UpdateProject event, Emitter<SyncState> emit) {
    emit(ProjectSynced(event.project));
  }

  void _onUpdateTask(_UpdateTask event, Emitter<SyncState> emit) {
    emit(TaskSynced(event.task));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

class _UpdateProject extends SyncEvent {
  final dynamic project; // Using dynamic because of entities
  const _UpdateProject(this.project);
  @override
  List<Object?> get props => [project];
}

class _UpdateTask extends SyncEvent {
  final dynamic task;
  const _UpdateTask(this.task);
  @override
  List<Object?> get props => [task];
}
