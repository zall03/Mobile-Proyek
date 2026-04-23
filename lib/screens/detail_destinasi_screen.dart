import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'checkout_screen.dart';

class DetailDestinasiScreen extends StatefulWidget {
  final Map<String, dynamic> destinationData;
  final List<Review>
  reviews; // Tidak digunakan lagi, tapi biarkan untuk kompatibilitas

  const DetailDestinasiScreen({
    Key? key,
    required this.destinationData,
    this.reviews = const [],
  }) : super(key: key);

  @override
  _DetailDestinasiScreenState createState() => _DetailDestinasiScreenState();
}

class _DetailDestinasiScreenState extends State<DetailDestinasiScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isWishlisted = false;
  bool _isLoading = false;
  double _averageRating = 0.0;
  List<Review> _reviews = []; // Data ulasan dari database

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _checkWishlist();
    _fetchReviews();
  }

  // Ambil ulasan dari tabel 'ulasan' dan hitung rating rata-rata
  Future<void> _fetchReviews() async {
    try {
      // Ambil semua ulasan untuk destinasi ini
      final reviewsData = await supabase
          .from('ulasan')
          .select('*')
          .eq('id_destinasi', widget.destinationData['id_destinasi']);

      print('Reviews data: $reviewsData'); // Cek di console

      final List<Review> fetchedReviews = [];
      for (var item in reviewsData) {
        String userName = 'Pengguna';
        // Ambil nama user dari tabel users berdasarkan user_uuid
        if (item['user_uuid'] != null) {
          final userData = await supabase
              .from('users')
              .select('name')
              .eq('id', item['user_uuid'])
              .maybeSingle();
          if (userData != null && userData['name'] != null) {
            userName = userData['name'];
          }
        }
        fetchedReviews.add(
          Review(
            idUlasan: item['id_ulasan'] ?? 0,
            rating: (item['rating'] as num).toDouble(),
            reviewText: item['komentar'] ?? '',
            userName: userName,
            tanggalUlasan: item['tanggal_ulasan'] ?? '',
          ),
        );
      }
      setState(() {
        _reviews = fetchedReviews;
        _calculateAverageRating();
      });
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      setState(() {
        _reviews = [];
        _calculateAverageRating();
      });
    }
  }

  void _calculateAverageRating() {
    if (_reviews.isEmpty) {
      _averageRating = 0.0;
    } else {
      double total = 0;
      for (var review in _reviews) {
        total += review.rating;
      }
      _averageRating = total / _reviews.length;
    }
  }

  Future<void> _checkWishlist() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('wishlist')
          .select()
          .eq('user_uuid', user.id)
          .eq('id_destinasi', widget.destinationData['id_destinasi'])
          .maybeSingle();

      if (response != null && mounted) {
        setState(() => _isWishlisted = true);
      }
    } catch (e) {
      debugPrint('Error checking wishlist: $e');
    }
  }

  Future<void> _toggleWishlist() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isWishlisted) {
        await supabase
            .from('wishlist')
            .delete()
            .eq('user_uuid', user.id)
            .eq('id_destinasi', widget.destinationData['id_destinasi']);
      } else {
        await supabase.from('wishlist').insert({
          'user_uuid': user.id,
          'id_destinasi': widget.destinationData['id_destinasi'],
        });
      }
      setState(() => _isWishlisted = !_isWishlisted);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui wishlist: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openMaps() async {
    final namaDestinasi = widget.destinationData['nama'];
    final mapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(namaDestinasi)}',
    );

    if (await canLaunchUrl(mapsUrl)) {
      await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $mapsUrl');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka Google Maps')),
      );
    }
  }

  void _goToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(destinasi: widget.destinationData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF1E3A34);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  child: Image.network(
                    widget.destinationData['foto'] ??
                        'https://via.placeholder.com/400',
                    width: double.infinity,
                    height: 350,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 350,
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 20,
                  child: _buildCircleButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  top: 50,
                  right: 20,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : _buildCircleButton(
                          icon: _isWishlisted
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _isWishlisted ? Colors.red : null,
                          onPressed: _toggleWishlist,
                        ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.destinationData['nama'] ?? '-',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text(
                                _averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 24,
                              ),
                            ],
                          ),
                          Text(
                            '(${_reviews.length} reviews)',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Lokasi Google Maps',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _openMaps,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              'assets/images/map_snapshot.png',
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: darkGreen,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.destinationData['lokasi'] ?? '-',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: darkGreen,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.destinationData['deskripsi'] ?? '-',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Ulasan Pengunjung',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_reviews.isEmpty)
                    const Text('Belum ada ulasan.')
                  else
                    ..._reviews
                        .take(2)
                        .map((review) => _buildReviewItem(review, darkGreen))
                        .toList(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _goToCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Pesan Tiket Sekarang',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    Color? color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? Colors.white, size: 28),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildReviewItem(Review review, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundImage: AssetImage('assets/images/user_placeholder.png'),
            radius: 20,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          review.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  review.reviewText,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
