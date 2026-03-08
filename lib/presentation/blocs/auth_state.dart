import 'package:equatable/equatable.dart';
import '../../domain/entities/entities.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthUpdatingProfile extends AuthState {
  final UserEntity? user;
  AuthUpdatingProfile({this.user});

  @override
  List<Object?> get props => [user];
}

class Authenticated extends AuthState {
  final UserEntity user;

  Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
