/// Data class đại diện cho một thông báo từ backend.
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  /// Parse từ JSON response của backend.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Tạo bản sao với trạng thái đã đọc.
  NotificationModel copyWithRead() {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      isRead: true,
      createdAt: createdAt,
    );
  }
}
