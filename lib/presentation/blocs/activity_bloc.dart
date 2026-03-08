import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/project_repository.dart';
import 'activity_event.dart';
import 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ProjectRepository _projectRepository;
  StreamSubscription? _activitiesSubscription;

  ActivityBloc({required ProjectRepository projectRepository})
    : _projectRepository = projectRepository,
      super(ActivityInitial()) {
    on<MonitorActivities>(_onMonitorActivities);
    on<ActivitiesUpdated>(_onActivitiesUpdated);
  }

  Future<void> _onMonitorActivities(
    MonitorActivities event,
    Emitter<ActivityState> emit,
  ) async {
    emit(ActivityLoading());
    await _activitiesSubscription?.cancel();
    _activitiesSubscription = _projectRepository
        .getActivitiesStream(event.projectId, event.taskId)
        .listen((activities) => add(ActivitiesUpdated(activities)));
  }

  void _onActivitiesUpdated(
    ActivitiesUpdated event,
    Emitter<ActivityState> emit,
  ) {
    emit(ActivityLoaded(event.activities));
  }

  @override
  Future<void> close() {
    _activitiesSubscription?.cancel();
    return super.close();
  }
}
