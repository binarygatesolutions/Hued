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
      try {
        await _firestore.collection('users').doc(credential.user!.uid).update({
          'fcmToken': await FirebaseMessaging.instance.getToken(),
        });
      } catch (e) {
        debugPrint('Failed to update FCM token during login: $e');
      }
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
    String? specialtyId,
    String? specialtyName,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await credential.user!.updateDisplayName(name);

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('Failed to get FCM token during registration: $e');
      }

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email.trim(),
        'role': role.name,
        'specialtyId': specialtyId,
        'specialtyName': specialtyName,
        'createdAt': FieldValue.serverTimestamp(),
        'fcmToken': fcmToken,
      });

      return UserEntity(
        id: credential.user!.uid,
        name: name,
        email: email.trim(),
        role: role,
        profile: null,
        specialtyId: specialtyId,
        specialtyName: specialtyName,
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
    String? specialtyId;
    String? specialtyName;

    if (doc.exists) {
      final data = doc.data();
      final roleStr = data?['role'] as String?;
      role = UserRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => UserRole.client,
      );
      img = data?['profile'];
      specialtyId = data?['specialtyId'];
      specialtyName = data?['specialtyName'];
    }

    return UserEntity(
      id: user.uid,
      name: user.displayName ?? 'Hued User',
      email: user.email ?? '',
      role: role,
      profile: img,
      specialtyId: specialtyId,
      specialtyName: specialtyName,
    );
  }

  @override
  Future<List<SpecialtyEntity>> getSpecialties() async {
    final snapshot = await _firestore.collection('specialties').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return SpecialtyEntity.fromJson(data);
    }).toList();
  }

  @override
  Future<void> addSpecialty(String name) async {
    await _firestore.collection('specialties').add({'name': name});
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
  @override
  Future<void> deleteAccount(String password) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) return;

    final userId = user.uid;

    // 0. Re-authenticate
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);

    // 1. Find all projects where the user is assigned
    final projectsSnapshot = await _firestore
        .collection('projects')
        .where('assignedUserIds', arrayContains: userId)
        .get();

    for (final projectDoc in projectsSnapshot.docs) {
      final projectId = projectDoc.id;
      final projectData = projectDoc.data();

      // Update project document: remove from all ID lists
      final updates = <String, dynamic>{
        'assignedUserIds': FieldValue.arrayRemove([userId]),
        'supervisorIds': FieldValue.arrayRemove([userId]),
        'managerIds': FieldValue.arrayRemove([userId]),
        'clientIds': FieldValue.arrayRemove([userId]),
        'workerIds': FieldValue.arrayRemove([userId]),
      };

      // Handle workerManagerMap (it's a Map<String, String>)
      final workerManagerMap =
          projectData['workerManagerMap'] as Map<String, dynamic>?;
      if (workerManagerMap != null) {
        bool changed = false;
        final newMap = Map<String, dynamic>.from(workerManagerMap);
        
        // Remove if user is a worker (key)
        if (newMap.containsKey(userId)) {
          newMap.remove(userId);
          changed = true;
        }
        
        // Remove if user is a manager (value)
        newMap.removeWhere((key, value) => value == userId);
        if (newMap.length != workerManagerMap.length) {
          changed = true;
        }

        if (changed) {
          updates['workerManagerMap'] = newMap;
        }
      }

      await _firestore.collection('projects').doc(projectId).update(updates);

      // Clean up tasks in this project
      final tasksSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('tasks')
          .where('assignedWorkerIds', arrayContains: userId)
          .get();

      for (final taskDoc in tasksSnapshot.docs) {
        await taskDoc.reference.update({
          'assignedWorkerIds': FieldValue.arrayRemove([userId]),
        });
      }
    }

    // 2. Clean up requests where user is a required approver
    final requestsSnapshot = await _firestore
        .collection('requests')
        .where('requiredApproverIds', arrayContains: userId)
        .get();

    for (final requestDoc in requestsSnapshot.docs) {
      await requestDoc.reference.update({
        'requiredApproverIds': FieldValue.arrayRemove([userId]),
      });
    }

    // 3. Delete user document from Firestore
    await _firestore.collection('users').doc(userId).delete();

    // 4. Delete Firebase Auth user
    await user.delete();
  }
}
