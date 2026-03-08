import 'package:equatable/equatable.dart';

class AttachmentEntity extends Equatable {
  final String id;
  final String url;
  final String userId;
  final DateTime createdAt;

  const AttachmentEntity({
    required this.id,
    required this.url,
    required this.userId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, url, userId, createdAt];
}
