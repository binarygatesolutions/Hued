import '../entities/entities.dart';

abstract class ProjectRepository {
  Future<List<ProjectEntity>> getProjects({String? userId, UserRole? role});
  Future<({List<ProjectEntity> projects, dynamic lastDoc, bool hasMore})>
  getPaginatedProjects({
    int limit = 10,
    dynamic lastDocument,
    String? userId,
    UserRole? role,
  });
  Future<void> createProject(ProjectEntity project);
  Future<void> addTask(String projectId, TaskEntity task);
  Future<void> updateTaskStatus(
    String projectId,
    String taskId,
    TaskStatus status, {
    String? userId,
  });
  Future<void> approveTask(String projectId, String taskId, {String? userId});
  Future<void> rejectTask(String projectId, String taskId, {String? userId});
  Future<void> updateTaskDeadline(
    String projectId,
    String taskId,
    DateTime deadline, {
    String? userId,
  });

  Future<void> addActivity(
    String projectId,
    String? taskId,
    ActivityEntity activity,
  );
  Future<void> addAttachment(
    String projectId,
    String taskId,
    AttachmentEntity attachment,
  );
  Future<String> uploadImage(String projectId, String taskId, dynamic file);
  Future<void> updateProjectUsers({
    required String projectId,
    required List<String> supervisorIds,
    required List<String> managerIds,
    required List<String> clientIds,
  });
  Future<void> updateProjectStatus(String projectId, ProjectStatus status);
  Future<List<TaskEntity>> getTasks(String projectId);

  // Scalability: On-demand fetching
  Future<({List<ActivityEntity> activities, dynamic lastDoc, bool hasMore})>
  getActivities(
    String projectId,
    String? taskId, {
    dynamic lastDoc,
    int limit = 50,
  });
  Future<List<AttachmentEntity>> getTaskAttachments(
    String projectId,
    String taskId,
  );

  Stream<List<ActivityEntity>> getActivitiesStream(
    String projectId,
    String? taskId, {
    int limit = 10,
  });

  Stream<ProjectEntity> getProjectStream(String projectId);
  Stream<TaskEntity> getTaskStream(String projectId, String taskId);
  Stream<List<TaskEntity>> getTasksStream(String projectId);
}
