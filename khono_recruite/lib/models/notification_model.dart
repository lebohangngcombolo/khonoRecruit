class NotificationModel {
  final int? id;
  final int userId;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    this.id,
    required this.userId,
    required this.message,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      message: json['message'],
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'message': message,
      'is_read': isRead,
    };
  }
}
