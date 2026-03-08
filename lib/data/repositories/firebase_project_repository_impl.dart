import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/activity_entity.dart';
import '../../domain/entities/attachment_entity.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/project_repository.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../models/activity_model.dart';
import '../models/attachment_model.dart';

class FirebaseProjectRepositoryImpl implements ProjectRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<ProjectEntity>> getProjects({
    String? userId,
    UserRole? role,
  }) async {
    Query query = _projectsCollection.orderBy('createdAt', descending: true);

    if (role != null && role != UserRole.admin && userId != null) {
      query = query.where('assignedUserIds', arrayContains: userId);
    }

    final snapshot = await query.limit(300).get();
    return snapshot.docs.map((doc) {
      final projectData = doc.data() as Map<String, dynamic>;
      return ProjectModel.fromFirestore(projectData, doc.id);
    }).toList();
  }

  @override
  Future<List<TaskEntity>> getTasks(String projectId) async {
    final snapshot = await _tasksCollection(projectId).get();
    return snapshot.docs.map((doc) {
      final userData = doc.data() as Map<String, dynamic>;
      userData['id'] = doc.id;

      return TaskModel.fromFirestore(userData, doc.id);
    }).toList();
  }

  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _projectsCollection =>
      _firestore.collection('projects');

  CollectionReference _tasksCollection(String projectId) =>
      _projectsCollection.doc(projectId).collection('tasks');

  CollectionReference _activitiesCollection(String projectId, String? taskId) {
    if (taskId != null) {
      return _tasksCollection(projectId).doc(taskId).collection('activities');
    }
    return _projectsCollection.doc(projectId).collection('activities');
  }

  CollectionReference _attachmentsCollection(String projectId, String taskId) =>
      _tasksCollection(projectId).doc(taskId).collection('attachments');

  @override
  Future<({List<ProjectEntity> projects, dynamic lastDoc, bool hasMore})>
  getPaginatedProjects({
    int limit = 10,
    dynamic lastDocument,
    String? userId,
    UserRole? role,
  }) async {
    Query query = _projectsCollection.orderBy('createdAt', descending: true);

    if (role != null && role != UserRole.admin && userId != null) {
      query = query.where('assignedUserIds', arrayContains: userId);
    }

    query = query.limit(limit + 1);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument as DocumentSnapshot);
    }

    final snapshot = await query.get();
    final allDocs = snapshot.docs;
    final hasMore = allDocs.length > limit;
    final docsToReturn = hasMore ? allDocs.take(limit).toList() : allDocs;

    final projects = <ProjectEntity>[];
    for (var doc in docsToReturn) {
      final projectData = doc.data() as Map<String, dynamic>;
      projects.add(ProjectModel.fromFirestore(projectData, doc.id));
    }

    final lastDoc = docsToReturn.isNotEmpty ? docsToReturn.last : null;

    return (projects: projects, lastDoc: lastDoc, hasMore: hasMore);
  }

  @override
  Future<void> createProject(ProjectEntity project) async {
    final model = ProjectModel.fromEntity(project);
    await _projectsCollection.add(model.toFirestore());
  }

  @override
  Future<void> addTask(String projectId, TaskEntity task) async {
    final model = TaskModel.fromEntity(task);
    await _tasksCollection(projectId).doc(model.id).set(model.toFirestore());
  }

  @override
  Future<void> updateTaskStatus(
    String projectId,
    String taskId,
    TaskStatus status, {
    String? userId,
  }) async {
    await _tasksCollection(projectId).doc(taskId).update({
      'status': status.name,
      'lastUpdatedBy': userId ?? 'system',
    });
  }

  @override
  Future<void> approveTask(
    String projectId,
    String taskId, {
    String? userId,
  }) async {
    await _tasksCollection(projectId).doc(taskId).update({
      'isApproved': true,
      'lastUpdatedBy': userId ?? 'system',
    });
  }

  @override
  Future<void> rejectTask(
    String projectId,
    String taskId, {
    String? userId,
  }) async {
    await _tasksCollection(projectId).doc(taskId).update({
      'status': TaskStatus.cancelled.name,
      'lastUpdatedBy': userId ?? 'system',
    });
  }

  @override
  Future<void> updateTaskDeadline(
    String projectId,
    String taskId,
    DateTime deadline, {
    String? userId,
  }) async {
    await _tasksCollection(projectId).doc(taskId).update({
      'deadline': Timestamp.fromDate(deadline),
      'lastUpdatedBy': userId ?? 'system',
    });
  }

  @override
  Future<void> addActivity(
    String projectId,
    String? taskId,
    ActivityEntity activity,
  ) async {
    final model = ActivityModel.fromEntity(activity);
    await _activitiesCollection(
      projectId,
      taskId,
    ).doc(model.id).set(model.toFirestore());
  }

  @override
  Future<void> addAttachment(
    String projectId,
    String taskId,
    AttachmentEntity attachment,
  ) async {
    final model = AttachmentModel.fromEntity(attachment);
    await _attachmentsCollection(
      projectId,
      taskId,
    ).doc(model.id).set(model.toFirestore());
  }

  @override
  Future<String> uploadImage(
    String projectId,
    String taskId,
    dynamic file,
  ) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final ref = _storage
        .ref()
        .child('projects')
        .child(projectId)
        .child('tasks')
        .child(taskId)
        .child(fileName);

    if (kIsWeb) {
      await ref.putData(file as Uint8List);
    } else {
      await ref.putFile(file as File);
    }

    return await ref.getDownloadURL();
  }

  @override
  Future<void> updateProjectUsers({
    required String projectId,
    required List<String> supervisorIds,
    required List<String> managerIds,
    required List<String> clientIds,
  }) async {
    // Combine all IDs for easier querying
    final assignedUserIds = {
      ...supervisorIds,
      ...managerIds,
      ...clientIds,
    }.toList();

    await _projectsCollection.doc(projectId).update({
      'supervisorIds': supervisorIds,
      'managerIds': managerIds,
      'clientIds': clientIds,
      'assignedUserIds': assignedUserIds,
    });
  }

  @override
  Future<void> updateProjectStatus(
    String projectId,
    ProjectStatus status,
  ) async {
    await _projectsCollection.doc(projectId).update({'status': status.name});
  }

  @override
  Future<({List<ActivityEntity> activities, dynamic lastDoc, bool hasMore})>
  getActivities(
    String projectId,
    String? taskId, {
    dynamic lastDoc,
    int limit = 50,
  }) async {
    Query query = _activitiesCollection(
      projectId,
      taskId,
    ).orderBy('createdAt', descending: true).limit(limit + 1);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc as DocumentSnapshot);
    }

    final snapshot = await query.get();
    final allDocs = snapshot.docs;
    final hasMore = allDocs.length > limit;
    final docsToReturn = hasMore ? allDocs.take(limit).toList() : allDocs;

    final activities = docsToReturn.map((doc) {
      return ActivityModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();

    final lastDocument = docsToReturn.isNotEmpty ? docsToReturn.last : null;

    return (activities: activities, lastDoc: lastDocument, hasMore: hasMore);
  }

  @override
  Future<List<AttachmentEntity>> getTaskAttachments(
    String projectId,
    String taskId,
  ) async {
    final snapshot = await _attachmentsCollection(
      projectId,
      taskId,
    ).orderBy('createdAt', descending: true).get();

    return snapshot.docs.map((doc) {
      return AttachmentModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  @override
  Stream<List<ActivityEntity>> getActivitiesStream(
    String projectId,
    String? taskId, {
    int limit = 10,
  }) {
    return _activitiesCollection(projectId, taskId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ActivityModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }

  @override
  Stream<ProjectEntity> getProjectStream(String projectId) {
    return _projectsCollection.doc(projectId).snapshots().map((doc) {
      return ProjectModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    });
  }

  @override
  Stream<TaskEntity> getTaskStream(String projectId, String taskId) {
    return _tasksCollection(projectId).doc(taskId).snapshots().map((doc) {
      return TaskModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    });
  }

  @override
  Stream<List<TaskEntity>> getTasksStream(String projectId) {
    return _tasksCollection(projectId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TaskModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }
}
