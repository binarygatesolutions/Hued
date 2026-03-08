class NotificationEntity {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationEntity.fromFirestore(
    Map<String, dynamic> json,
    String docId,
  ) {
    return NotificationEntity(
      id: docId,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'system',
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }
}
