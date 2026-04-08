import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class OrderService {
  final supabase = Supabase.instance.client;

  /// Simpan pesanan setelah pembayaran sukses
  Future<Map<String, dynamic>> saveOrder({
    required String orderId,
    required int jumlahTiket,
    required int totalHarga,
    required int destinasiId,
    required DateTime tanggalBerangkat,
    required String userId,
    required String metodeBayar,
  }) async {
    try {
      // 1. Simpan ke tabel pemesanan
      final pemesananData = {
        'tanggal_pemesanan': DateTime.now().toIso8601String().split('T')[0],
        'jumlah_tiket': jumlahTiket,
        'total_harga': totalHarga,
        'status': 'paid',
        'id_user': null, // biarkan null, pakai user_uuid
        'user_uuid': userId, // simpan UUID di kolom baru
        'id_destinasi': destinasiId,
        'order_id': orderId,
        'tanggal_berangkat': tanggalBerangkat.toIso8601String().split('T')[0],
        'midtrans_status': 'settlement',
        'created_at': DateTime.now().toIso8601String(),
      };

      final pemesananResponse = await supabase
          .from('pemesanan')
          .insert(pemesananData)
          .select()
          .single();

      final idPemesanan = pemesananResponse['id_pemesanan'];

      // 2. Simpan ke tabel pembayaran
      final pembayaranData = {
        'metode_bayar': metodeBayar,
        'tanggal_bayar': DateTime.now().toIso8601String().split('T')[0],
        'status_pembayaran': 'success',
        'total_bayar': totalHarga,
        'id_pemesanan': idPemesanan,
        'created_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('pembayaran').insert(pembayaranData);

      return {
        'success': true,
        'id_pemesanan': idPemesanan,
        'message': 'Pesanan berhasil disimpan',
      };
    } catch (e) {
      debugPrint('Error saving order: $e');
      return {'success': false, 'message': 'Gagal menyimpan pesanan: $e'};
    }
  }

  /// Ambil riwayat pesanan user berdasarkan UUID
  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final response = await supabase
          .from('pemesanan')
          .select('''
            *,
            destinasi:destinasi(*),
            pembayaran:pembayaran(*)
          ''')
          .eq('user_uuid', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

  /// Update status pesanan berdasarkan order_id
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await supabase
          .from('pemesanan')
          .update({'status': status, 'midtrans_status': status})
          .eq('order_id', orderId);
      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }
}
