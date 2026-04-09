import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class OrderService {
  Future<bool> hasUserReviewed(String userId, int destinasiId) async {
    try {
      final response = await supabase
          .from('ulasan')
          .select('id_ulasan')
          .eq('user_uuid', userId)
          .eq('id_destinasi', destinasiId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Error check review: $e');
      return false;
    }
  }

  final supabase = Supabase.instance.client;
  Future<bool> saveReview({
    required String userId, // UUID dari auth.users
    required int destinasiId,
    required double rating,
    required String komentar,
  }) async {
    try {
      await supabase.from('ulasan').insert({
        'rating': rating,
        'komentar': komentar,
        'tanggal_ulasan': DateTime.now().toIso8601String().split('T')[0],
        'id_user': 0,
        'user_uuid': userId,
        'id_destinasi': destinasiId,
      });
      return true;
    } catch (e) {
      debugPrint('Error save review: $e');
      return false;
    }
  }

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
      final pemesananData = {
        'tanggal_pemesanan': DateTime.now().toIso8601String().split('T')[0],
        'jumlah_tiket': jumlahTiket,
        'total_harga': totalHarga,
        'status': 'paid',
        'id_user': null,
        'user_uuid': userId,
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

  Future<List<Map<String, dynamic>>> getUserOrdersWithDetails(
    String userId,
  ) async {
    try {
      final response = await supabase
          .from('pemesanan')
          .select('*, destinasi:destinasi(*)')
          .eq('user_uuid', userId)
          .order('tanggal_berangkat', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching orders with details: $e');
      return [];
    }
  }

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
