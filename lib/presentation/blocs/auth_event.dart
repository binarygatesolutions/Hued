import 'dart:io';

import 'package:equatable/equatable.dart';
import '../../domain/entities/entities.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class UpdateProfile extends AuthEvent {
  final String? fullName;
  final File? profileImg;

  UpdateProfile({this.fullName, this.profileImg});
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final UserRole role;
  final String? specialtyId;
  final String? specialtyName;

  RegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.specialtyId,
    this.specialtyName,
  });

  @override
  List<Object?> get props => [
    email,
    password,
    name,
    role,
    specialtyId,
    specialtyName,
  ];
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;

  ForgotPasswordRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}
