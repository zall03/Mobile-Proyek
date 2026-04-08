import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class MidtransService {
  static const String serverKey = '';

  static Future<String?> createTransaction({
    required String orderId,
    required int grossAmount,
    required String itemName,
    required String customerName,
    required String customerEmail,
  }) async {
    const String url = 'https://app.sandbox.midtrans.com/snap/v1/transactions';
    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$serverKey:'))}';

    final Map<String, dynamic> body = {
      "transaction_details": {"order_id": orderId, "gross_amount": grossAmount},
      "item_details": [
        {
          "id": "TIK-${DateTime.now().millisecondsSinceEpoch}",
          "price": grossAmount,
          "quantity": 1,
          "name": itemName,
        },
      ],
      "customer_details": {"first_name": customerName, "email": customerEmail},
      // 🔥 TAMBAHKAN INI - URL callback setelah pembayaran
      "finish_url": "https://your-app-scheme.com/payment-finish",
      "error_url": "https://your-app-scheme.com/payment-error",
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
        body: jsonEncode(body),
      );

      debugPrint('Midtrans Response: ${response.body}'); // Buat debugging

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['redirect_url'];
      } else {
        debugPrint('Gagal buat transaksi: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error Midtrans: $e');
      return null;
    }
  }

  static Future<String?> cekStatusPembayaran(String orderId) async {
    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$serverKey:'))}';
    final String url = 'https://api.sandbox.midtrans.com/v2/$orderId/status';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transaction_status'];
      }
      return null;
    } catch (e) {
      debugPrint('Error cek status Midtrans: $e');
      return null;
    }
  }
}
