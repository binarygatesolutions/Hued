import 'dart:io';
import '../../domain/entities/entities.dart';

abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register(
    String name,
    String email,
    String password,
    UserRole role,
    String? specialtyId,
    String? specialtyName,
  );
  Future<UserEntity> updateProfile(String? name, File? profileImg);
  Future<void> logout();
  Future<void> sendPasswordResetEmail(String email);
  Future<List<UserEntity>> getUsers({required List<String> userIds});
  Future<List<SpecialtyEntity>> getSpecialties();
  Future<void> addSpecialty(String name);
  Stream<UserEntity?> get onAuthStateChanged;
}
