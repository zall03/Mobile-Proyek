import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TiketOnlineScreen extends StatelessWidget {
  final String orderId;
  final int jumlahTiket;
  final String namaDestinasi;

  const TiketOnlineScreen({
    super.key,
    required this.orderId,
    required this.jumlahTiket,
    required this.namaDestinasi,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E7AC1), // Warna tema aplikasi Anda
      appBar: AppBar(
        title: const Text('E-Ticket Anda', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                namaDestinasi,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Berlaku untuk $jumlahTiket Orang',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
            
              QrImageView(
                data: orderId, // Teks yang akan diubah jadi QR (biasanya Order ID)
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
              
              const SizedBox(height: 30),
              const Text(
                'Tunjukkan QR Code ini kepada petugas di loket pintu masuk.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const Divider(height: 40, thickness: 2, color: Colors.black12),
              Text(
                'Order ID: $orderId',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}