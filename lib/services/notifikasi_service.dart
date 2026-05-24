import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notifikasi.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotifikasiService {
  final supabase = Supabase.instance.client;

  static const String emailServiceUrl = 'https://api.resend.com/emails';
  static const String emailApiKey = 're_Ezj6wNkf_8cqfPQcJQQbW6XGkKHMTnMiQ';

  // ============= AMBIL NOTIFIKASI =============

  /// Ambil semua notifikasi user
  Future<List<Notifikasi>> getNotifications() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await supabase
          .from('notifikasi')
          .select()
          .eq('user_uuid', user.id)
          .order('created_at', ascending: false);

      return response
          .map<Notifikasi>((json) => Notifikasi.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Hitung notifikasi yang belum dibaca
  Future<int> getUnreadCount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return 0;

    try {
      final response = await supabase
          .from('notifikasi')
          .select('id')
          .eq('user_uuid', user.id)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  // ============= TANDAI DIBACA =============

  /// Tandai notifikasi sebagai sudah dibaca
  Future<void> markAsRead(int id) async {
    try {
      await supabase.from('notifikasi').update({'is_read': true}).eq('id', id);
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  /// Tandai semua sebagai sudah dibaca
  Future<void> markAllAsRead() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('notifikasi')
          .update({'is_read': true})
          .eq('user_uuid', user.id)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  // ============= HAPUS NOTIFIKASI =============

  /// Hapus notifikasi
  Future<void> deleteNotification(int id) async {
    try {
      await supabase.from('notifikasi').delete().eq('id', id);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Hapus semua notifikasi user
  Future<void> deleteAllNotifications() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('notifikasi').delete().eq('user_uuid', user.id);
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }

  // ============= KIRIM NOTIFIKASI =============

  /// Kirim notifikasi lengkap (in-app + email)
  Future<void> sendNotificationWithEmail({
    required String userId,
    required String userEmail,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // 1. Simpan ke database
      await supabase.from('notifikasi').insert({
        'user_uuid': userId,
        'title': title,
        'isi': message,
        'type': type,
        'data': data,
      });

      // 2. Kirim email
      await _sendEmail(
        to: userEmail,
        subject: title,
        message: message,
        type: type,
      );

      print('✓ Notifikasi terkirim (in-app + email)');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  /// Kirim notifikasi hanya in-app (tanpa email)
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await supabase.from('notifikasi').insert({
        'user_uuid': userId,
        'title': title,
        'isi': message,
        'type': type,
        'data': data,
      });

      print('✓ Notifikasi terkirim (in-app)');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // ============= KIRIM EMAIL HELPER =============

  /// Fungsi internal untuk kirim email via Resend
  Future<void> _sendEmail({
    required String to,
    required String subject,
    required String message,
    required String type,
  }) async {
    try {
      final emailBody = _getEmailTemplate(subject, message, type);

      final response = await http.post(
        Uri.parse(emailServiceUrl),
        headers: {
          'Authorization': 'Bearer $emailApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'to': to,
          'from': 'Wiskuyy <no-reply@wiskuy.my.id>',
          'subject': subject,
          'html': emailBody,
        }),
      );

      if (response.statusCode == 200) {
        print('✓ Email terkirim ke $to');
      } else {
        print('✗ Gagal kirim email: ${response.body}');
      }
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  // ============= EMAIL TEMPLATE =============

  /// Buat template email berdasarkan tipe notifikasi
  String _getEmailTemplate(String subject, String message, String type) {
    final brandColor = '#1E7AC1';
    final accentColor = type == 'reminder_h1' ? '#FF6B6B' : '#5BB8F5';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background: #f4f6f9; }
    .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .header { background: linear-gradient(135deg, $brandColor 0%, $accentColor 100%); color: white; padding: 30px; text-align: center; }
    .header h1 { margin: 0; font-size: 24px; font-weight: 600; }
    .body { padding: 30px; }
    .body p { color: #333; line-height: 1.6; margin: 0 0 15px 0; }
    .body strong { color: $brandColor; }
    .cta-button { display: inline-block; background: $brandColor; color: white; padding: 12px 30px; border-radius: 8px; text-decoration: none; margin-top: 20px; font-weight: 600; }
    .footer { background: #f9fafb; padding: 20px; text-align: center; color: #999; font-size: 12px; border-top: 1px solid #eee; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>📬 $subject</h1>
    </div>
    <div class="body">
      <p>Halo Traveler,</p>
      <p>$message</p>
      <p style="color: #666; font-size: 14px; margin-top: 30px;">
        Buka aplikasi Wiskuyy untuk informasi lebih lengkap.
      </p>
    </div>
    <div class="footer">
      <p>&copy; 2025 Wiskuyy - Aplikasi Wisata Terpercaya</p>
      <p>Email ini dikirim otomatis, mohon jangan balas.</p>
    </div>
  </div>
</body>
</html>
    ''';
  }

  Future<void> sendPaymentSuccessNotification({
    required String userId,
    required String userEmail,
    required String namaDestinasi,
    required String nomorTiket,
    required int totalHarga,
  }) async {
    final title = '✓ Pembayaran Berhasil';
    final message =
        '''
Pembayaran untuk tiket wisata ke $namaDestinasi telah berhasil diproses!

Nomor Tiket: $nomorTiket
Total Bayar: Rp ${_formatRupiah(totalHarga)}

Silakan cek halaman "Tiket Saya" untuk detail lengkap.
    ''';

    await sendNotificationWithEmail(
      userId: userId,
      userEmail: userEmail,
      title: title,
      message: message,
      type: 'payment_success',
    );
  }

  /// Notifikasi reminder H-1 sebelum wisata
  Future<void> sendReminderH1Notification({
    required String userId,
    required String userEmail,
    required String namaDestinasi,
    required String tanggalWisata,
  }) async {
    final title = '⏰ Pengingat: Wisata Besok!';
    final message =
        '''
Halo! Jangan lupa bahwa kamu memiliki jadwal wisata ke $namaDestinasi besok ($tanggalWisata).

✓ Pastikan tiket sudah disiapkan
✓ Tiba di lokasi 15 menit lebih awal
✓ Bawa perlengkapan yang diperlukan

Kami tunggu kedatanganmu! Nikmati pengalaman wisata yang tak terlupakan bersama Wiskuyy.
    ''';

    await sendNotificationWithEmail(
      userId: userId,
      userEmail: userEmail,
      title: title,
      message: message,
      type: 'reminder_h1',
    );
  }

  // ============= HELPER =============

  /// Format rupiah
  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
