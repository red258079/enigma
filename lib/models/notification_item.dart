class NotificationItem {
  final String id;
  final String? userId;
  final String type;
  final String title;
  final String body;
  final bool isSent;
  final bool isRead;
  final DateTime? sentAt;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.isSent = false,
    this.isRead = false,
    this.sentAt,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      userId: json['user_id'],
      type: json['type'] ?? 'system',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      isSent: json['is_sent'] ?? false,
      isRead: json['is_read'] ?? false,
      sentAt: json['sent_at'] != null ? DateTime.tryParse(json['sent_at']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      isSent: isSent,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt,
      createdAt: createdAt,
    );
  }
}
