import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notifikasi.dart';

class NotifikasiService {
  final supabase = Supabase.instance.client;

  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  // ─── Init push notification ───────────────────────────────────────────────
  static Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotif.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _isInitialized = true;
  }

  // ─── Tampilkan popup notifikasi di HP ─────────────────────────────────────
  Future<void> _showPushNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'wiskuyy_channel',
      'Wiskuyy Notifikasi',
      channelDescription: 'Notifikasi pemesanan tiket wisata',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotif.show(id, title, body, details);
  }

  // ─── Kirim email via Supabase Edge Function ───────────────────────────────
  Future<void> _sendEmailNotification({
    required String email,
    required String title,
    required String message,
  }) async {
    try {
      await supabase.functions.invoke(
        'send-notification-email',
        body: {'email': email, 'title': title, 'message': message},
      );
    } catch (e) {
      debugPrint('Email notif error: $e');
    }
  }

  // ─── Kirim notifikasi lengkap (in-app + push + email) ────────────────────
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
    bool withPush = true,
    bool withEmail = false,
    String? userEmail,
  }) async {
    // 1. Simpan ke database (in-app)
    await supabase.from('notifikasi').insert({
      'user_uuid': userId,
      'title': title,
      'message': message,
      'isi': message,
      'type': type,
      'data': data,
      'is_read': false,
    });

    // 2. Push notification (popup HP)
    if (withPush) {
      await _showPushNotification(
        title: title,
        body: message,
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    }

    // 3. Email notification
    if (withEmail && userEmail != null) {
      await _sendEmailNotification(
        email: userEmail,
        title: title,
        message: message,
      );
    }
  }

  // ─── Notifikasi pembayaran berhasil ───────────────────────────────────────
  Future<void> sendPaymentSuccessNotification({
    required String userId,
    required String userEmail,
    required String namaDestinasi,
    required String orderId,
    required String tanggalBerangkat,
    required int jumlahTiket,
    required int totalHarga,
  }) async {
    await sendNotification(
      userId: userId,
      title: '🎫 Pembayaran Berhasil!',
      message:
          'Pemesanan tiket $namaDestinasi berhasil. '
          '$jumlahTiket tiket untuk $tanggalBerangkat. '
          'Kode: $orderId',
      type: 'order',
      data: {
        'order_id': orderId,
        'destinasi': namaDestinasi,
        'tanggal': tanggalBerangkat,
      },
      withPush: true,
      withEmail: true,
      userEmail: userEmail,
    );
  }

  // ─── Notifikasi reminder H-1 (dipanggil dari Edge Function) ──────────────
  Future<void> sendReminderNotification({
    required String userId,
    required String userEmail,
    required String namaDestinasi,
    required String tanggalBerangkat,
  }) async {
    await sendNotification(
      userId: userId,
      title: '⏰ Besok Kamu Berangkat!',
      message:
          'Jangan lupa! Wisata ke $namaDestinasi '
          'jadwal berangkat besok, $tanggalBerangkat. '
          'Siapkan tiket dan perlengkapanmu!',
      type: 'reminder',
      data: {'destinasi': namaDestinasi, 'tanggal': tanggalBerangkat},
      withPush: true,
      withEmail: true,
      userEmail: userEmail,
    );
  }

  // ─── CRUD notifikasi ──────────────────────────────────────────────────────
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

  Future<void> markAsRead(int id) async {
    await supabase.from('notifikasi').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllAsRead() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase
        .from('notifikasi')
        .update({'is_read': true})
        .eq('user_uuid', user.id)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(int id) async {
    await supabase.from('notifikasi').delete().eq('id', id);
  }

  Future<void> deleteAllNotifications() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase.from('notifikasi').delete().eq('user_uuid', user.id);
  }

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
