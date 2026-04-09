import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/order_service.dart';
import 'tiket.dart'; 
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final OrderService _orderService = OrderService();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final orders = await _orderService.getUserOrdersWithDetails(user.id);
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReview(
    Map<String, dynamic> order,
    int rating,
    String comment,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final success = await _orderService.saveReview(
      userId: user.id,
      destinasiId: order['id_destinasi'],
      rating: rating.toDouble(),
      komentar: comment,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ulasan berhasil disimpan')));
      _loadOrders(); // refresh
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal menyimpan ulasan')));
    }
  }

  void _showReviewDialog(Map<String, dynamic> order) {
    int rating = 5;
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tulis Ulasan'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Berikan rating dan komentar untuk destinasi ini'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setStateDialog(() {
                          rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: 'Tulis komentar Anda...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _submitReview(order, rating, commentController.text);
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        backgroundColor: const Color(0xFF1E7AC1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(child: Text('Belum ada pesanan'))
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final destinasi = order['destinasi'];
                final tanggalBerangkat = DateTime.parse(
                  order['tanggal_berangkat'],
                );
                final isPast = tanggalBerangkat.isBefore(DateTime.now());
                final isActive =
                    !isPast; // tiket aktif jika belum lewat tanggal
                final canReview = order['status'] == 'paid' && isPast;
                return FutureBuilder<bool>(
                  future: _orderService.hasUserReviewed(
                    _supabase.auth.currentUser?.id ?? '',
                    order['id_destinasi'],
                  ),
                  builder: (context, snapshot) {
                    final alreadyReviewed = snapshot.data ?? false;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destinasi['nama'] ?? 'Destinasi',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tanggal Kunjungan: ${DateFormat('dd MMM yyyy', 'id').format(tanggalBerangkat)}',
                            ),
                            Text('Jumlah Tiket: ${order['jumlah_tiket']}'),
                            Text('Total Harga: Rp ${order['total_harga']}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: order['status'] == 'paid'
                                        ? Colors.green
                                        : Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    order['status'] == 'paid'
                                        ? 'Berhasil'
                                        : order['status'],
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const Spacer(),
                                // Tombol Lihat Tiket - hanya jika tiket masih aktif
                                if (isActive)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.receipt_long,
                                      color: Color(0xFF1E7AC1),
                                    ),
                                    onPressed: () {
                                      // Gunakan order_id jika ada, fallback ke id_pemesanan
                                      final orderId =
                                          order['order_id'] ??
                                          order['id_pemesanan'].toString();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TiketOnlineScreen(
                                                orderId: orderId,
                                                jumlahTiket:
                                                    order['jumlah_tiket'],
                                                namaDestinasi:
                                                    destinasi['nama'],
                                              ),
                                        ),
                                      );
                                    },
                                    tooltip: 'Lihat Tiket',
                                  ),
                                if (canReview && !alreadyReviewed)
                                  ElevatedButton(
                                    onPressed: () => _showReviewDialog(order),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E7AC1),
                                    ),
                                    child: const Text('Tulis Ulasan'),
                                  ),
                                if (alreadyReviewed)
                                  const Text(
                                    'Sudah Diulas',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
