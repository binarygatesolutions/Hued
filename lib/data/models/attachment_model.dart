import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attachment_entity.dart';

class AttachmentModel extends AttachmentEntity {
  const AttachmentModel({
    required super.id,
    required super.url,
    required super.userId,
    required super.createdAt,
  });

  factory AttachmentModel.fromFirestore(Map<String, dynamic> json, String id) {
    return AttachmentModel(
      id: id,
      url: json['url'] as String,
      userId: json['userId'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'url': url,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AttachmentModel.fromEntity(AttachmentEntity entity) {
    return AttachmentModel(
      id: entity.id,
      url: entity.url,
      userId: entity.userId,
      createdAt: entity.createdAt,
    );
  }
}
