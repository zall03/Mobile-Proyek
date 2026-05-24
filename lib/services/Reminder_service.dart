import 'package:supabase_flutter/supabase_flutter.dart';
import 'notifikasi_service.dart';
import 'package:intl/intl.dart';

class ReminderService {
  final supabase = Supabase.instance.client;
  final _notifikasiService = NotifikasiService();

  Future<void> checkAndSendH1Reminders() async {
    try {
      print('🔄 Checking H-1 reminders...');

      // Ambil semua pemesanan yang tanggal berangkatnya besok
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowFormatted = DateFormat('yyyy-MM-dd').format(tomorrow);

      final orders = await supabase
          .from('pemesanan')
          .select('''
            id_pemesanan,
            tanggal_berangkat,
            user_id,
            users!inner(email, name),
            destinasi!inner(nama)
          ''')
          .eq('tanggal_berangkat', tomorrowFormatted)
          .eq('status', 'completed');

      if (orders.isEmpty) {
        print('✓ Tidak ada pemesanan untuk H-1');
        return;
      }

      print('📨 Menemukan ${orders.length} pemesanan untuk reminder H-1');

      for (final order in orders) {
        try {
          final userId = order['user_id'];
          final userEmail = order['users']['email'];
          final userName = order['users']['name'];
          final namaDestinasi = order['destinasi']['nama'];

          // Format tanggal yang bagus
          final tanggalWisata = DateFormat(
            'EEEE, dd MMMM yyyy',
            'id_ID',
          ).format(DateTime.parse(order['tanggal_berangkat']));

          // Kirim notifikasi
          await _notifikasiService.sendReminderH1Notification(
            userId: userId,
            userEmail: userEmail,
            namaDestinasi: namaDestinasi,
            tanggalWisata: tanggalWisata,
          );

          print('✓ Reminder dikirim ke $userName ($userEmail)');
        } catch (e) {
          print('✗ Error mengirim reminder untuk order: $e');
        }
      }

      print('✓ H-1 reminder check selesai');
    } catch (e) {
      print('✗ Error checking H-1 reminders: $e');
    }
  }

  Future<void> initializeReminderService() async {
    print('🚀 Initializing reminder service...');

    await checkAndSendH1Reminders();

    print('✓ Reminder service initialized');
  }
}
