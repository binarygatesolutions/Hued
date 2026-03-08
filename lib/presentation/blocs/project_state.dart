import 'package:equatable/equatable.dart';
import '../../domain/entities/entities.dart';

abstract class ProjectState extends Equatable {
  final String? currentUserId;
  final UserRole? currentUserRole;

  const ProjectState({this.currentUserId, this.currentUserRole});

  @override
  List<Object?> get props => [currentUserId, currentUserRole];
}

class ProjectInitial extends ProjectState {
  const ProjectInitial({super.currentUserId, super.currentUserRole});
}

class ProjectLoading extends ProjectState {
  const ProjectLoading({super.currentUserId, super.currentUserRole});
}

class ProjectError extends ProjectState {
  final String message;
  const ProjectError(
    this.message, {
    super.currentUserId,
    super.currentUserRole,
  });

  @override
  List<Object?> get props => [...super.props, message];
}
