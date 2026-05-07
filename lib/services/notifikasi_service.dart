import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notifikasi.dart';

class NotifikasiService {
  final supabase = Supabase.instance.client;

  // Ambil semua notifikasi user
  Future<List<Notifikasi>> getNotifications() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('notifikasi')
        .select()
        .eq('user_uuid', user.id)
        .order('created_at', ascending: false);

    return response
        .map<Notifikasi>((json) => Notifikasi.fromJson(json))
        .toList();
  }

  // Tandai notifikasi sebagai sudah dibaca
  Future<void> markAsRead(int id) async {
    await supabase.from('notifikasi').update({'is_read': true}).eq('id', id);
  }

  // Tandai semua sebagai sudah dibaca
  Future<void> markAllAsRead() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('notifikasi')
        .update({'is_read': true})
        .eq('user_uuid', user.id)
        .eq('is_read', false);
  }

  // Kirim notifikasi (dipanggil dari backend atau setelah event)
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await supabase.from('notifikasi').insert({
      'user_uuid': userId,
      'title': title,
      'isi': message,
      'type': type,
      'data': data,
    });
  }

  // Hapus notifikasi
  Future<void> deleteNotification(int id) async {
    await supabase.from('notifikasi').delete().eq('id', id);
  }

  // Hapus semua notifikasi user
  Future<void> deleteAllNotifications() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('notifikasi').delete().eq('user_uuid', user.id);
  }

  // Hitung notifikasi yang belum dibaca
  Future<int> getUnreadCount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return 0;

    final response = await supabase
        .from('notifikasi')
        .select('id')
        .eq('user_uuid', user.id)
        .eq('is_read', false);

    return response.length;
  }
}
