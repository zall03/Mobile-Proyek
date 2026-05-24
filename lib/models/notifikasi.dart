class Notifikasi {
  final int id;
  final String userUuid;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  final String? icon;

  Notifikasi({
    required this.id,
    required this.userUuid,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data,
    this.icon,
  });

  // Factory untuk create dari JSON Supabase
  factory Notifikasi.fromJson(Map<String, dynamic> json) {
    return Notifikasi(
      id: json['id'] ?? 0,
      userUuid: json['user_uuid'] ?? '',
      title: json['title'] ?? '',
      message: json['isi'] ?? json['message'] ?? '',
      type: json['type'] ?? 'info',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      data: json['data'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_uuid': userUuid,
      'title': title,
      'isi': message,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'data': data,
      'icon': icon,
    };
  }
}
