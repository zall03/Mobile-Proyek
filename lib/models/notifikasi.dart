class Notifikasi {
  final int id;
  final String userUuid;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  Notifikasi({
    required this.id,
    required this.userUuid,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.data,
    required this.createdAt,
  });

  factory Notifikasi.fromJson(Map<String, dynamic> json) {
    return Notifikasi(
      id: json['id'],
      userUuid: json['user_uuid'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      isRead: json['is_read'] ?? false,
      data: json['data'] is Map ? json['data'] : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_uuid': userUuid,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'data': data,
    };
  }
}
