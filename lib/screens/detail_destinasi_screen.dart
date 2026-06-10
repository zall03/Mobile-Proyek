import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'checkout_screen.dart';
import 'video_player_screen.dart';

class DetailDestinasiScreen extends StatefulWidget {
  final Map<String, dynamic> destinationData;
  final List<Review> reviews;

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

  // Wishlist
  bool _isWishlisted = false;
  bool _isLoading = false;

  // Reviews
  double _averageRating = 0.0;
  List<Review> _reviews = [];

  // Carousel
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _mediaItems = [];

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
    _fetchAllPhotos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ─── Fetch semua foto ─────────────────────────────────────────────────────

  Future<void> _fetchAllPhotos() async {
    final coverPhoto = widget.destinationData['foto'] as String?;

    try {
      final List<Map<String, dynamic>> media = [];

      if (coverPhoto != null && coverPhoto.trim().isNotEmpty) {
        media.add({'type': 'image', 'url': coverPhoto.trim()});
      }

      final photos = await supabase
          .from('destinasi_fotos')
          .select('foto')
          .eq('id_destinasi', widget.destinationData['id_destinasi']);

      for (var item in photos) {
        final url = (item['foto'] as String?)?.trim();

        if (url != null && url.isNotEmpty) {
          media.add({'type': 'image', 'url': url});
        }
      }

      final video = await supabase
          .from('destinasi_media')
          .select('url,thumbnail')
          .eq('id_destinasi', widget.destinationData['id_destinasi'])
          .eq('type', 'video')
          .maybeSingle();

      if (video != null) {
        media.add({
          'type': 'video',
          'url': video['url'],
          'thumbnail': video['thumbnail'],
        });
      }

      setState(() {
        _mediaItems = media;
      });
    } catch (e) {
      debugPrint('Error fetching media: $e');
    }
  }

  // ─── Fetch ulasan ─────────────────────────────────────────────────────────

  Future<void> _fetchReviews() async {
    try {
      final reviewsData = await supabase
          .from('ulasan')
          .select('*')
          .eq('id_destinasi', widget.destinationData['id_destinasi']);

      final List<Review> fetchedReviews = [];

      for (var item in reviewsData) {
        String userName = 'Pengguna';

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

  // ─── Wishlist ─────────────────────────────────────────────────────────────

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
          'id_user': user.id,
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

  // ─── Maps & Checkout ──────────────────────────────────────────────────────

  void _openMaps() async {
    final namaDestinasi = widget.destinationData['nama'] ?? '';
    final lokasi = widget.destinationData['lokasi'] ?? '';

    final query = Uri.encodeComponent('$namaDestinasi $lokasi');
    final mapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    try {
      await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka Google Maps')),
        );
      }
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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF1E3A34);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Carousel Section ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 350,
                    child: _mediaItems.isEmpty
                        ? Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: _mediaItems.length,
                            onPageChanged: (index) {
                              setState(() => _currentImageIndex = index);
                            },
                            itemBuilder: (context, index) {
                              final item = _mediaItems[index];

                              if (item['type'] == 'image') {
                                return Image.network(
                                  item['url'],
                                  width: double.infinity,
                                  height: 350,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade300,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VideoPlayerScreen(
                                        videoUrl: item['url'],
                                      ),
                                    ),
                                  );
                                },
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    item['thumbnail'] != null &&
                                            item['thumbnail']
                                                .toString()
                                                .isNotEmpty
                                        ? Image.network(
                                            item['thumbnail'],
                                            fit: BoxFit.cover,
                                          )
                                        : Container(color: Colors.black),

                                    Container(color: Colors.black26),

                                    const Center(
                                      child: Icon(
                                        Icons.play_circle_fill,
                                        size: 90,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
                // Dot Indicator
                if (_mediaItems.length > 1)
                  Positioned(
                    bottom: 15,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_mediaItems.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentImageIndex == index ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),

                // Tombol Back
                Positioned(
                  top: 50,
                  left: 20,
                  child: _buildCircleButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Tombol Wishlist
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

            // ── Content Section ──
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama & Rating
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

                  const SizedBox(height: 20),

                  // ── Jam Operasional ──
                  _buildJamOperasional(darkGreen),

                  const SizedBox(height: 30),

                  // Lokasi Google Maps
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

                  // Deskripsi
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

                  // Ulasan
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
                    const Text(
                      'Belum ada ulasan.',
                      style: TextStyle(color: Colors.grey),
                    )
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

      // ── Bottom Bar ──
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

  // ─── Jam Operasional Widget ───────────────────────────────────────────────

  Widget _buildJamOperasional(Color darkGreen) {
    final String weekday =
        (widget.destinationData['weekday'] as String?)?.trim() ?? '-';
    final String weekend =
        (widget.destinationData['weekend'] as String?)?.trim() ?? '-';

    // Deteksi hari ini weekday atau weekend
    final int todayWeekday = DateTime.now().weekday; // 1=Sen ... 7=Min
    final bool isWeekend = todayWeekday == 6 || todayWeekday == 7;
    final String jamHariIni = isWeekend ? weekend : weekday;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: darkGreen.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(Icons.access_time_rounded, color: darkGreen, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Jam Operasional',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              // Badge "Hari ini"
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: darkGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Hari ini: $jamHariIni',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Weekday row
          _buildJamRow(
            icon: Icons.calendar_today_outlined,
            label: 'Senin – Jumat',
            jam: weekday,
            isActive: !isWeekend,
            darkGreen: darkGreen,
          ),

          const SizedBox(height: 10),

          // Weekend row
          _buildJamRow(
            icon: Icons.weekend_outlined,
            label: 'Sabtu – Minggu',
            jam: weekend,
            isActive: isWeekend,
            darkGreen: darkGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildJamRow({
    required IconData icon,
    required String label,
    required String jam,
    required bool isActive,
    required Color darkGreen,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isActive ? darkGreen : Colors.grey),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Poppins',
            color: isActive ? Colors.black87 : Colors.grey,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? darkGreen.withOpacity(0.1)
                : Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            jam,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: isActive ? darkGreen : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Helper Widgets ───────────────────────────────────────────────────────

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
