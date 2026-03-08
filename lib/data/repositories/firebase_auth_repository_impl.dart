import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<UserEntity?> get onAuthStateChanged =>
      _firebaseAuth.authStateChanges().asyncMap((user) async {
        if (user == null) return null;
        return await _getUserWithRole(user);
      });

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return await _getUserWithRole(user);
  }

  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await _firestore.collection('users').doc(credential.user!.uid).update({
        'fcmToken': await FirebaseMessaging.instance.getToken(),
      });
      return await _getUserWithRole(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during login.';
    }
  }

  @override
  Future<UserEntity> register(
    String name,
    String email,
    String password,
    UserRole role,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await credential.user!.updateDisplayName(name);

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email.trim(),
        'role': role.name,
        'createdAt': FieldValue.serverTimestamp(),
        'fcmToken': await FirebaseMessaging.instance.getToken(),
      });

      return UserEntity(
        id: credential.user!.uid,
        name: name,
        email: email.trim(),
        role: role,
        profile: null,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during registration.';
    }
  }

  @override
  Future<void> logout() => _firebaseAuth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred while sending the reset email.';
    }
  }

  @override
  Future<List<UserEntity>> getUsers({required List<String> userIds}) async {
    if (userIds.isEmpty) return [];

    final uniqueIds = userIds.toSet().toList();
    List<UserEntity> users = [];

    // Firestore `whereIn` supports a maximum of 10 elements.
    for (var i = 0; i < uniqueIds.length; i += 10) {
      final chunk = uniqueIds.sublist(
        i,
        i + 10 > uniqueIds.length ? uniqueIds.length : i + 10,
      );

      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var doc in querySnapshot.docs) {
          final userData = doc.data();
          userData['id'] = doc.id;
          users.add(UserEntity.fromJson(userData));
        }
      } catch (e) {
        debugPrint('Error fetching users chunk: $e');
      }
    }

    return users;
  }

  Future<UserEntity> _getUserWithRole(User user) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    UserRole role = UserRole.client;
    String? img;
    if (doc.exists) {
      final data = doc.data();
      final roleStr = data?['role'] as String?;
      role = UserRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => UserRole.client,
      );
      img = data?['profile'];
    }

    return UserEntity(
      id: user.uid,
      name: user.displayName ?? 'Hued User',
      email: user.email ?? '',
      role: role,
      profile: img,
    );
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  Future<UserEntity> updateProfile(String? name, File? profileImg) async {
    Map<String, dynamic> newUserData = {};
    if (name != null) {
      _firebaseAuth.currentUser?.updateDisplayName(name);
      newUserData['name'] = name;
    }
    if (profileImg != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile')
          .child('${_firebaseAuth.currentUser!.uid}.png');

      if (kIsWeb) {
        await ref.putData(profileImg as Uint8List);
      } else {
        await ref.putFile(profileImg);
      }

      final url = await ref.getDownloadURL();
      _firebaseAuth.currentUser?.updatePhotoURL(url);
      newUserData['profile'] = url;
    }

    await _firestore
        .collection('users')
        .doc(_firebaseAuth.currentUser!.uid)
        .update(newUserData);

    final newDoc = await _firestore
        .collection('users')
        .doc(_firebaseAuth.currentUser!.uid)
        .get();

    final userJson = newDoc.data() as Map<String, dynamic>;
    userJson['id'] = newDoc.id;

    return UserEntity.fromJson(userJson);
  }
}
