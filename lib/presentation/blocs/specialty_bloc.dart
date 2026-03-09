import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';

// Events
abstract class SpecialtyEvent extends Equatable {
  const SpecialtyEvent();
  @override
  List<Object?> get props => [];
}

class LoadSpecialties extends SpecialtyEvent {}

class AddSpecialty extends SpecialtyEvent {
  final String name;
  const AddSpecialty(this.name);
  @override
  List<Object?> get props => [name];
}

// State
class SpecialtyState extends Equatable {
  final List<SpecialtyEntity> specialties;
  final bool isLoading;
  final String? error;

  const SpecialtyState({
    this.specialties = const [],
    this.isLoading = false,
    this.error,
  });

  SpecialtyState copyWith({
    List<SpecialtyEntity>? specialties,
    bool? isLoading,
    String? error,
  }) {
    return SpecialtyState(
      specialties: specialties ?? this.specialties,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [specialties, isLoading, error];
}

// Bloc
class SpecialtyBloc extends Bloc<SpecialtyEvent, SpecialtyState> {
  final AuthRepository _authRepository;

  SpecialtyBloc(this._authRepository) : super(const SpecialtyState()) {
    on<LoadSpecialties>(_onLoadSpecialties);
    on<AddSpecialty>(_onAddSpecialty);
  }

  Future<void> _onLoadSpecialties(
    LoadSpecialties event,
    Emitter<SpecialtyState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final specialties = await _authRepository.getSpecialties();
      emit(state.copyWith(specialties: specialties, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onAddSpecialty(
    AddSpecialty event,
    Emitter<SpecialtyState> emit,
  ) async {
    try {
      await _authRepository.addSpecialty(event.name);
      add(LoadSpecialties()); // Reload list after adding
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
