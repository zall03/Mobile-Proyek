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
  final int totalHarga;
  final int destinasiId;
  final DateTime tanggalBerangkat;
  final String metodeBayar;
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
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            // Tangkap custom scheme sebelum WebView mencoba memuatnya
            if (url.startsWith('myapp://payment-success')) {
              _handlePaymentSuccess();
              return NavigationDecision.prevent; // Jangan load URL
            } else if (url.startsWith('myapp://payment-error')) {
              _handlePaymentError();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            // Backup detection jika perlu
            final url = change.url ?? '';
            if (url.startsWith('myapp://payment-success')) {
              _handlePaymentSuccess();
            } else if (url.startsWith('myapp://payment-error')) {
              _handlePaymentError();
            }
          },
          onPageFinished: (String url) {
            // Fallback untuk URL internal Midtrans
            if (url.contains('#/success') ||
                url.contains('transaction_status=settlement')) {
              _handlePaymentSuccess();
            } else if (url.contains('#/error') ||
                url.contains('transaction_status=deny')) {
              _handlePaymentError();
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
    if (status == 'settlement' || status == 'capture') {
      final orderService = OrderService();
      final user = supabase.auth.currentUser;
      if (user == null) return;

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
