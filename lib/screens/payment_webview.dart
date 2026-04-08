import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/midtrans_service.dart';
import 'tiket.dart';
import '../services/order_service.dart';

class PaymentWebView extends StatefulWidget {
  final String redirectUrl;
  final String orderId;
  final int jumlahTiket;
  final int totalHarga; // ← TAMBAHKAN
  final int destinasiId; // ← TAMBAHKAN
  final DateTime tanggalBerangkat; // ← TAMBAHKAN
  final String metodeBayar; // ← TAMBAHKAN
  final String namaDestinasi;

  const PaymentWebView({
    super.key,
    required this.redirectUrl,
    required this.orderId,
    required this.jumlahTiket,
    required this.totalHarga,
    required this.destinasiId,
    required this.tanggalBerangkat,
    required this.metodeBayar,
    required this.namaDestinasi,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isPaymentComplete = false;
  final supabase = Supabase.instance.client; // ← TAMBAHKAN INI

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            debugPrint('Page finished: $url');
            if (url.contains('payment-finish') ||
                url.contains('success') ||
                url.contains('finish')) {
              _handlePaymentSuccess();
            } else if (url.contains('payment-error') || url.contains('error')) {
              _handlePaymentError();
            }
          },
          onUrlChange: (UrlChange change) {
            debugPrint('URL changed to: ${change.url}');
            if (change.url?.contains('payment-finish') == true ||
                change.url?.contains('success') == true) {
              _handlePaymentSuccess();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  Future<void> _handlePaymentSuccess() async {
    if (_isPaymentComplete) return;
    _isPaymentComplete = true;

    final status = await MidtransService.cekStatusPembayaran(widget.orderId);
    debugPrint('Payment status: $status');

    if (status == 'settlement' || status == 'capture') {
      final orderService = OrderService();
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint('User tidak ditemukan');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User tidak ditemukan, silakan login ulang'),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      final result = await orderService.saveOrder(
        orderId: widget.orderId,
        jumlahTiket: widget.jumlahTiket,
        totalHarga: widget.totalHarga,
        destinasiId: widget.destinasiId,
        tanggalBerangkat: widget.tanggalBerangkat,
        userId: user.id,
        metodeBayar: widget.metodeBayar,
      );

      if (result['success'] && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pembayaran berhasil!')));

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => TiketOnlineScreen(
              orderId: widget.orderId,
              jumlahTiket: widget.jumlahTiket,
              namaDestinasi: widget.namaDestinasi,
            ),
          ),
          (route) => route.isFirst,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pembayaran berhasil tapi gagal menyimpan: ${result['message']}',
            ),
          ),
        );
        // Tetap arahkan ke halaman tiket meskipun gagal simpan? Terserah Anda
        // Atau biarkan di webview
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran gagal atau dibatalkan')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _handlePaymentError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran gagal atau dibatalkan')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran Midtrans'),
        backgroundColor: const Color(0xFF1E7AC1),
        foregroundColor: Colors.white,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
