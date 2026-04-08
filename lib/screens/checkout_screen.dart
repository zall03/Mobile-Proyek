import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/midtrans_service.dart';
import 'payment_webview.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> destinasi;

  const CheckoutScreen({super.key, required this.destinasi});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final supabase = Supabase.instance.client;

  // State Pemesan
  String _userName = "-";
  String _userEmail = "-";
  String _userPhone = "-";
  bool _isLoadingUser = true;

  // State Pesanan
  DateTime? _selectedDate;
  int _ticketCount = 1;
  int _totalPrice = 0;
  int _currentTicketPrice = 0;

  // State Pembayaran
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _currentTicketPrice = widget.destinasi['harga_tiket_weekday'] ?? 0;
    _calculateTotal();
  }

  // 1. Fungsi Ambil Data User
  Future<void> _fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        _userEmail = user.email ?? "-";
        final data = await supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data != null && mounted) {
          setState(() {
            _userName = data['name'] ?? "User";
            _userPhone = data['no_telepon'] ?? "-";
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
    } finally {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1E7AC1)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _calculateTotal();
    }
  }

  // 3. Fungsi Hitung Total Harga (Cek Weekday/Weekend)
  void _calculateTotal() {
    if (_selectedDate == null) {
      _currentTicketPrice = widget.destinasi['harga_tiket_weekday'] ?? 0;
    } else {
      bool isWeekend =
          _selectedDate!.weekday == DateTime.saturday ||
          _selectedDate!.weekday == DateTime.sunday;

      if (isWeekend) {
        _currentTicketPrice = widget.destinasi['harga_tiket_weekend'] ?? 0;
      } else {
        _currentTicketPrice = widget.destinasi['harga_tiket_weekday'] ?? 0;
      }
    }

    setState(() {
      _totalPrice = _currentTicketPrice * _ticketCount;
    });
  }

  // 4. Fungsi Proses Pembayaran ke Midtrans
  Future<void> _prosesPembayaran() async {
    if (_totalPrice == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Harga tiket tidak valid.')));
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final orderId = 'TRX-${DateTime.now().millisecondsSinceEpoch}';
      final namaDestinasi = widget.destinasi['nama'] ?? 'Tiket Wisata';

      final redirectUrl = await MidtransService.createTransaction(
        orderId: orderId,
        grossAmount: _totalPrice,
        itemName: '$namaDestinasi (x$_ticketCount)',
        customerName: _userName,
        customerEmail: _userEmail,
      );

      if (redirectUrl != null && mounted) {
        // Navigasi ke halaman WebView pembayaran
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebView(
              redirectUrl: redirectUrl,
              orderId: orderId,
              jumlahTiket: _ticketCount,
              namaDestinasi: namaDestinasi,
            ),
          ),
        );
      } else {
        throw 'Gagal mendapatkan link pembayaran dari Midtrans.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses pembayaran: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  // Format Rupiah
  String formatRupiah(int number) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoadingUser
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E7AC1)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECTION 1: INFO DESTINASI ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.destinasi['foto'] ??
                                'https://via.placeholder.com/80',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.destinasi['nama'] ?? 'Nama Destinasi',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.destinasi['lokasi'] ?? 'Lokasi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- SECTION 2: DATA PEMESAN ---
                  const Text(
                    'Data Pemesan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildUserInfoRow(
                          Icons.person,
                          'Nama Lengkap',
                          _userName,
                        ),
                        const Divider(height: 24),
                        _buildUserInfoRow(Icons.email, 'Email', _userEmail),
                        const Divider(height: 24),
                        _buildUserInfoRow(
                          Icons.phone,
                          'No. Telepon',
                          _userPhone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- SECTION 3: DETAIL TIKET & TANGGAL ---
                  const Text(
                    'Detail Tiket',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        // Pilih Tanggal
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month,
                                    color: Color(0xFF1E7AC1),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tanggal Keberangkatan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        _selectedDate == null
                                            ? 'Pilih Tanggal'
                                            : DateFormat(
                                                'EEEE, d MMMM yyyy',
                                                'id',
                                              ).format(_selectedDate!),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _selectedDate == null
                                              ? Colors.red
                                              : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 32),
                        // Jumlah Tiket
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Jumlah Tiket',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    if (_ticketCount > 1) {
                                      setState(() => _ticketCount--);
                                      _calculateTotal();
                                    }
                                  },
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: _ticketCount > 1
                                      ? const Color(0xFF1E7AC1)
                                      : Colors.grey,
                                ),
                                Text(
                                  '$_ticketCount',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() => _ticketCount++);
                                    _calculateTotal();
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: const Color(0xFF1E7AC1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- SECTION 4: RINCIAN HARGA ---
                  const Text(
                    'Rincian Harga',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Harga Tiket (${_selectedDate == null ? "Pilih Tanggal" : (_selectedDate!.weekday >= 6 ? "Weekend" : "Weekday")})',
                            ),
                            Text(formatRupiah(_currentTicketPrice)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Jumlah Pesanan'),
                            Text('$_ticketCount Tiket'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

      // --- BOTTOM NAVIGATION BAR (TOTAL & TOMBOL BAYAR) ---
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Pembayaran',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      formatRupiah(_totalPrice),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E7AC1),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                // Tombol mati jika tanggal belum dipilih ATAU sedang loading pembayaran
                onPressed: (_selectedDate == null || _isProcessingPayment)
                    ? null
                    : _prosesPembayaran,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessingPayment
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Lanjut Bayar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget bantuan untuk menampilkan baris data pemesan
  Widget _buildUserInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
