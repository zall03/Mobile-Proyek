import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lokasi_screen.dart';
import 'detail_destinasi_screen.dart';
import 'wishlist_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'notifikasi_screen.dart';
import '../services/notifikasi_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  final Color _brandBlue = const Color(0xFF1E7AC1);

  String _userName = 'Pengguna';
  List<Map<String, dynamic>> _popularDestinasiList = [];
  List<Map<String, dynamic>> _rekomendasiList = [];
  bool _isLoading = true;
  int _unreadNotifCount = 0;

  int _selectedIndex = 0;

  final List<Map<String, String>> _kotaList = [
    {
      'nama': 'Cirebon',
      'foto':
          'https://zglovosnylnowriqeaya.supabase.co/storage/v1/object/public/images/cirebon.png',
    },
    {
      'nama': 'Indramayu',
      'foto':
          'https://zglovosnylnowriqeaya.supabase.co/storage/v1/object/public/images/indramayu.png',
    },
    {
      'nama': 'Majalengka',
      'foto':
          'https://zglovosnylnowriqeaya.supabase.co/storage/v1/object/public/images/majalengka.png',
    },
    {
      'nama': 'Kuningan',
      'foto':
          'https://zglovosnylnowriqeaya.supabase.co/storage/v1/object/public/images/kuningan.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadData();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotifikasiService().getUnreadCount();
    if (mounted) setState(() => _unreadNotifCount = count);
  }

  Future<void> _loadUserName() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final fullName =
          user.userMetadata?['full_name'] ?? user.userMetadata?['name'];
      if (fullName != null && fullName.toString().isNotEmpty) {
        setState(() => _userName = fullName.toString().split(' ').first);
        return;
      }
      if (user.email != null) {
        setState(() => _userName = user.email!.split('@').first);
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail') ?? '';
    if (email.isNotEmpty) {
      setState(() => _userName = email.split('@').first);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadPopular(), _loadRekomendasi()]);
    await _attachRatings();
    setState(() => _isLoading = false);
  }

  // Fungsi untuk menghitung rating rata-rata dari tabel ulasan
  Future<void> _attachRatings() async {
    // Kumpulkan semua id destinasi dari popular dan rekomendasi
    Set<int> destinasiIds = {};
    for (var item in _popularDestinasiList) {
      destinasiIds.add(item['id_destinasi']);
    }
    for (var item in _rekomendasiList) {
      final destinasi = item['destinasi'];
      if (destinasi != null) {
        destinasiIds.add(destinasi['id_destinasi']);
      }
    }

    if (destinasiIds.isEmpty) return;

    // Ambil semua rating untuk destinasi tersebut
    final response = await _supabase
        .from('ulasan')
        .select('id_destinasi, rating')
        .inFilter('id_destinasi', destinasiIds.toList());

    // Hitung rata-rata per id_destinasi
    Map<int, double> avgRatings = {};
    Map<int, int> countRatings = {};

    for (var ulasan in response) {
      int id = ulasan['id_destinasi'];
      double rating = (ulasan['rating'] as num).toDouble();
      avgRatings[id] = (avgRatings[id] ?? 0) + rating;
      countRatings[id] = (countRatings[id] ?? 0) + 1;
    }

    // Hitung rata-rata
    for (var id in avgRatings.keys) {
      avgRatings[id] = avgRatings[id]! / countRatings[id]!;
    }

    // Tempelkan ke popular destinasi
    for (var i = 0; i < _popularDestinasiList.length; i++) {
      int id = _popularDestinasiList[i]['id_destinasi'];
      double avg = avgRatings[id] ?? 0.0;
      _popularDestinasiList[i]['avg_rating'] = avg;
    }

    // Tempelkan ke rekomendasi (di dalam objek destinasi)
    for (var i = 0; i < _rekomendasiList.length; i++) {
      var destinasi = _rekomendasiList[i]['destinasi'];
      if (destinasi != null) {
        int id = destinasi['id_destinasi'];
        double avg = avgRatings[id] ?? 0.0;
        _rekomendasiList[i]['destinasi']['avg_rating'] = avg;
      }
    }
  }

  Future<void> _loadPopular() async {
    try {
      final res = await _supabase.rpc('get_popular_destinasi');
      setState(
        () => _popularDestinasiList = List<Map<String, dynamic>>.from(res),
      );
    } catch (e) {
      // Fallback: ambil 5 destinasi pertama
      final res = await _supabase
          .from('destinasi')
          .select('*, kategori(nama_kategori)')
          .limit(5);
      setState(
        () => _popularDestinasiList = List<Map<String, dynamic>>.from(res),
      );
    }
  }

  Future<void> _loadRekomendasi() async {
    try {
      final res = await _supabase
          .from('rekomendasi')
          .select('*, destinasi(*, kategori(nama_kategori))')
          .eq('is_active', true)
          .order('urutan', ascending: true);
      setState(() => _rekomendasiList = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('Error load rekomendasi: $e');
      setState(() => _rekomendasiList = []);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildBodyContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const WishlistScreen();
      case 2:
        return NotifikasiScreen(onUnreadCountChanged: _loadUnreadCount);
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Wis',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Kuyy',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: _brandBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Halo, $_userName',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HistoryScreen(),
                              ),
                            ),
                            icon: Icon(
                              Icons.history,
                              color: _brandBlue,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Popular Destinasi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220,
                      child: _popularDestinasiList.isEmpty
                          ? const Center(
                              child: Text(
                                'Belum ada data',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount: _popularDestinasiList.length,
                              itemBuilder: (context, index) {
                                final item = _popularDestinasiList[index];
                                final avgRating = (item['avg_rating'] ?? 0.0)
                                    .toDouble();
                                final kategori =
                                    item['kategori']?['nama_kategori'] ?? '-';
                                return _buildPopularCard(
                                  item,
                                  avgRating,
                                  kategori,
                                );
                              },
                            ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Rekomendasi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _rekomendasiList[index];
                      final destinasi = item['destinasi'];
                      if (destinasi == null) return const SizedBox.shrink();
                      final avgRating = (destinasi['avg_rating'] ?? 0.0)
                          .toDouble();
                      final kategori =
                          destinasi['kategori']?['nama_kategori'] ?? '-';
                      return _buildRekomendasiCard(
                        destinasi,
                        kategori,
                        avgRating,
                      );
                    }, childCount: _rekomendasiList.length),
                  ),
                  if (_rekomendasiList.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Belum ada rekomendasi',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pilih Lokasi Yang Anda Mau',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 130,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _kotaList.length,
                        itemBuilder: (context, index) =>
                            _buildKotaCard(_kotaList[index]),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _buildBodyContent(),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: _brandBlue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none),
                if (_unreadNotifCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_unreadNotifCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Notification',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCard(
    Map<String, dynamic> item,
    double avgRating,
    String kategori,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DetailDestinasiScreen(destinationData: item, reviews: const []),
        ),
      ),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Image.network(
                    item['foto'] ?? '',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        kategori,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['nama'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey,
                      ),
                      Expanded(
                        child: Text(
                          item['lokasi'] ?? '-',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRekomendasiCard(
    Map<String, dynamic> destinasi,
    String kategori,
    double avgRating,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailDestinasiScreen(
            destinationData: destinasi,
            reviews: const [],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                destinasi['foto'] ?? '',
                width: 75,
                height: 75,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 75,
                  height: 75,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destinasi['nama'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      kategori,
                      style: TextStyle(fontSize: 11, color: _brandBlue),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 13,
                        color: Colors.grey,
                      ),
                      Expanded(
                        child: Text(
                          destinasi['lokasi'] ?? '-',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKotaCard(Map<String, String> kota) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LokasiScreen(namaKota: kota['nama']!, fotoKota: kota['foto']!),
        ),
      ),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                kota['foto']!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: _brandBlue),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Text(
                  kota['nama']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
