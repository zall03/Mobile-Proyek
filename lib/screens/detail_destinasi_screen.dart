import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class DetailDestinasiScreen extends StatefulWidget {
  final Map<String, dynamic> destinasi;

  const DetailDestinasiScreen({super.key, required this.destinasi});

  @override
  State<DetailDestinasiScreen> createState() => _DetailDestinasiScreenState();
}

class _DetailDestinasiScreenState extends State<DetailDestinasiScreen> {
  final _supabase = Supabase.instance.client;
  final Color _brandBlue = const Color(0xFF1E7AC1);

  List<Map<String, dynamic>> _ulasanList = [];
  double _avgRating = 0.0;
  bool _isWishlisted = false;
  bool _isLoadingWishlist = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadUlasan(), _checkWishlist()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadUlasan() async {
    try {
      final res = await _supabase
          .from('ulasan')
          .select('*, users(name)')
          .eq('id_destinasi', widget.destinasi['id_destinasi'])
          .order('tanggal_ulasan', ascending: false);

      final list = List<Map<String, dynamic>>.from(res);
      double avg = 0;
      if (list.isNotEmpty) {
        avg =
            list
                .map((e) => (e['rating'] as num).toDouble())
                .reduce((a, b) => a + b) /
            list.length;
      }

      setState(() {
        _ulasanList = list;
        _avgRating = double.parse(avg.toStringAsFixed(1));
      });
    } catch (e) {
      debugPrint('Error ulasan: $e');
    }
  }

  Future<void> _checkWishlist() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Cari id user di public.users berdasarkan email
      final userRes = await _supabase
          .from('users')
          .select('id')
          .eq('email', user.email!)
          .maybeSingle();

      if (userRes == null) return;

      final res = await _supabase
          .from('wishlist')
          .select()
          .eq('id_user', userRes['id'])
          .eq('id_destinasi', widget.destinasi['id_destinasi'])
          .maybeSingle();

      setState(() => _isWishlisted = res != null);
    } catch (e) {
      debugPrint('Error check wishlist: $e');
    }
  }

  Future<void> _toggleWishlist() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login dulu untuk menambah wishlist!')),
      );
      return;
    }

    setState(() => _isLoadingWishlist = true);
    try {
      final userRes = await _supabase
          .from('users')
          .select('id')
          .eq('email', user.email!)
          .maybeSingle();

      if (userRes == null) return;
      final userId = userRes['id'];

      if (_isWishlisted) {
        await _supabase
            .from('wishlist')
            .delete()
            .eq('id_user', userId)
            .eq('id_destinasi', widget.destinasi['id_destinasi']);
        setState(() => _isWishlisted = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dihapus dari wishlist')),
          );
        }
      } else {
        await _supabase.from('wishlist').insert({
          'id_user': userId,
          'id_destinasi': widget.destinasi['id_destinasi'],
        });
        setState(() => _isWishlisted = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ditambahkan ke wishlist!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error wishlist: $e');
    } finally {
      if (mounted) setState(() => _isLoadingWishlist = false);
    }
  }

  Future<void> _openMaps() async {
    final alamat = Uri.encodeComponent(
      '${widget.destinasi['alamat_lengkap'] ?? widget.destinasi['nama']}, ${widget.destinasi['lokasi']}',
    );
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$alamat',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinasi = widget.destinasi;
    final kategori = destinasi['kategori']?['nama_kategori'] ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // HERO IMAGE + APPBAR
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: _brandBlue,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: _isLoadingWishlist ? null : _toggleWishlist,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: _isLoadingWishlist
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isWishlisted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isWishlisted ? Colors.red : Colors.grey,
                              size: 22,
                            ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        destinasi['foto'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // INFO UTAMA
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _brandBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  kategori,
                                  style: TextStyle(
                                    color: _brandBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            destinasi['nama'] ?? '-',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: _brandBlue,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  destinasi['alamat_lengkap'] ??
                                      destinasi['lokasi'] ??
                                      '-',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _infoChip(
                                Icons.star,
                                '${_avgRating > 0 ? _avgRating : "Baru"}',
                                Colors.amber,
                              ),
                              const SizedBox(width: 10),
                              _infoChip(
                                Icons.rate_review,
                                '${_ulasanList.length} ulasan',
                                Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // HARGA TIKET
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Harga Tiket',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _hargaCard(
                                  'Weekday',
                                  destinasi['weekday'] ?? '-',
                                  destinasi['harga_tiket_weekday'] ?? 0,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _hargaCard(
                                  'Weekend',
                                  destinasi['weekend'] ?? '-',
                                  destinasi['harga_tiket_weekend'] ?? 0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // DESKRIPSI
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deskripsi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            destinasi['deskripsi'] ?? '-',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // LOKASI / BUKA MAPS
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lokasi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _openMaps,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _brandBlue.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.map_outlined,
                                      color: _brandBlue,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          destinasi['nama'] ?? '-',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          destinasi['alamat_lengkap'] ?? '-',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: _brandBlue),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Tap untuk buka di Google Maps',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ULASAN
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Ulasan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_ulasanList.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_avgRating / 5.0',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_isLoading)
                            const Center(child: CircularProgressIndicator())
                          else if (_ulasanList.isEmpty)
                            Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 10),
                                  Icon(
                                    Icons.rate_review_outlined,
                                    size: 40,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Belum ada ulasan',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            )
                          else
                            ...List.generate(
                              _ulasanList.length > 3 ? 3 : _ulasanList.length,
                              (index) {
                                return _buildUlasanCard(_ulasanList[index]);
                              },
                            ),
                          if (_ulasanList.length > 3)
                            Center(
                              child: TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Lihat semua ${_ulasanList.length} ulasan',
                                  style: TextStyle(color: _brandBlue),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Padding bawah untuk tombol
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ],
          ),

          // TOMBOL PESAN SEKARANG (FIXED BOTTOM)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Mulai dari',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        _formatHarga(destinasi['harga_tiket_weekday'] ?? 0),
                        style: TextStyle(
                          color: _brandBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fitur pemesanan segera hadir!'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Pesan Sekarang',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hargaCard(String tipe, String jam, int harga) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tipe,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                jam,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatHarga(harga),
            style: TextStyle(
              color: _brandBlue,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUlasanCard(Map<String, dynamic> ulasan) {
    final rating = (ulasan['rating'] as num).toInt();
    final nama = ulasan['users']?['name'] ?? 'Pengguna';
    final tanggal = ulasan['tanggal_ulasan'] != null
        ? DateFormat(
            'd MMM yyyy',
            'id',
          ).format(DateTime.parse(ulasan['tanggal_ulasan']))
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _brandBlue.withOpacity(0.2),
                child: Text(
                  nama.isNotEmpty ? nama[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: _brandBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      tanggal,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ulasan['komentar'] ?? '-',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatHarga(int harga) {
    if (harga == 0) return 'Gratis';
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(harga);
  }
}
