import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/entities.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<UpdateProfile>(_onUpdateProfile);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);
  }

  void _onUpdateProfile(UpdateProfile event, Emitter<AuthState> emit) async {
    final currentState = state;
    UserEntity? currentUser;
    if (currentState is Authenticated) {
      currentUser = currentState.user;
    }
    emit(AuthUpdatingProfile(user: currentUser));
    try {
      final user = await _authRepository.updateProfile(
        event.fullName,
        event.profileImg,
      );

      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('Authentication failed: ${e.toString()}'));
    }
  }

  void _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(event.email, event.password);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('Authentication failed: ${e.toString()}'));
    }
  }

  void _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.register(
        event.name,
        event.email,
        event.password,
        event.role,
        event.specialtyId,
        event.specialtyName,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('Registration failed: ${e.toString()}'));
    }
  }

  void _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Failed to send reset email: ${e.toString()}'));
    }
  }

  void _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(Unauthenticated());
  }

  void _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }
  void _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.deleteAccount(event.password);
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Failed to delete account: ${e.toString()}'));
    }
  }
}
