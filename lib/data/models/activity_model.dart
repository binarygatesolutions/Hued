import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/activity_entity.dart';

class ActivityModel extends ActivityEntity {
  const ActivityModel({
    required super.id,
    required super.userId,
    required super.content,
    required super.type,
    required super.createdAt,
  });

  factory ActivityModel.fromEntity(ActivityEntity entity) {
    return ActivityModel(
      id: entity.id,
      userId: entity.userId,
      content: entity.content,
      type: entity.type,
      createdAt: entity.createdAt,
    );
  }

  factory ActivityModel.fromFirestore(Map<String, dynamic> doc, String id) {
    return ActivityModel(
      id: id,
      userId: doc['userId'] ?? '',
      content: doc['content'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.toString().split('.').last == (doc['type'] ?? 'comment'),
        orElse: () => ActivityType.comment,
      ),
      createdAt: (doc['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'content': content,
      'type': type.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
