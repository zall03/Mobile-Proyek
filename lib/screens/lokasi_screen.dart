import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_destinasi_screen.dart';

class LokasiScreen extends StatefulWidget {
  final String namaKota;
  final String fotoKota;

  const LokasiScreen({
    super.key,
    required this.namaKota,
    required this.fotoKota,
  });

  @override
  State<LokasiScreen> createState() => _LokasiScreenState();
}

class _LokasiScreenState extends State<LokasiScreen> {
  final _supabase = Supabase.instance.client;
  final Color _brandBlue = const Color(0xFF1E7AC1);

  List<Map<String, dynamic>> _destinasiList = [];
  List<Map<String, dynamic>> _filteredList = [];
  List<Map<String, dynamic>> _kategoriList = [];
  String _selectedKategori = 'Semua';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadDestinasiByLokasi(), _loadKategori()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadDestinasiByLokasi() async {
    try {
      final res = await _supabase
          .from('destinasi')
          .select('*, kategori(nama_kategori)')
          .ilike('lokasi', '%${widget.namaKota}%')
          .order('nama', ascending: true);

      setState(() {
        _destinasiList = List<Map<String, dynamic>>.from(res);
        _filteredList = _destinasiList;
      });
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _loadKategori() async {
    try {
      final res = await _supabase
          .from('kategori')
          .select()
          .order('nama_kategori', ascending: true);
      setState(() => _kategoriList = List<Map<String, dynamic>>.from(res));
    } catch (e) {
      debugPrint('Error load kategori: $e');
    }
  }

  void _filterData(String query, String kategori) {
    List<Map<String, dynamic>> result = _destinasiList;

    if (kategori != 'Semua') {
      result = result.where((item) {
        return item['kategori']?['nama_kategori'] == kategori;
      }).toList();
    }

    if (query.isNotEmpty) {
      result = result.where((item) {
        return item['nama'].toString().toLowerCase().contains(
          query.toLowerCase(),
        );
      }).toList();
    }

    setState(() => _filteredList = result);
  }

  Future<double> _getAvgRating(int idDestinasiasi) async {
    try {
      final res = await _supabase
          .from('ulasan')
          .select('rating')
          .eq('id_destinasi', idDestinasiasi);
      if (res.isEmpty) return 0.0;
      final avg =
          res.map((e) => e['rating'] as double).reduce((a, b) => a + b) /
          res.length;
      return double.parse(avg.toStringAsFixed(1));
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: _brandBlue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.fotoKota,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: _brandBlue),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20, // Mengatur jarak dari bawah
                    left: 20, // Mengatur jarak dari kiri
                    child: Text(
                      widget.namaKota,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // SEARCH BAR
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => _filterData(val, _selectedKategori),
                        decoration: const InputDecoration(
                          hintText: 'Cari destinasi...',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),

                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _kategoriList.length + 1,
                        itemBuilder: (context, index) {
                          final isAll = index == 0;
                          final label = isAll
                              ? 'Semua'
                              : _kategoriList[index - 1]['nama_kategori'];
                          final isSelected = _selectedKategori == label;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedKategori = label);
                              _filterData(_searchController.text, label);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _brandBlue
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? _brandBlue
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // JUMLAH HASIL
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        Text(
                          '${_filteredList.length} destinasi ditemukan',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // LIST DESTINASI
                  Expanded(
                    child: _filteredList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 60,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tidak ada destinasi\ndi ${widget.namaKota}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: _filteredList.length,
                            itemBuilder: (context, index) {
                              final item = _filteredList[index];
                              return FutureBuilder<double>(
                                future: _getAvgRating(item['id_destinasi']),
                                builder: (context, snapshot) {
                                  final rating = snapshot.data ?? 0.0;
                                  return _buildDestinasiCard(item, rating);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDestinasiCard(Map<String, dynamic> item, double rating) {
    final kategori = item['kategori']?['nama_kategori'] ?? '-';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetailDestinasiScreen(destinationData: item, reviews: const []),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            // FOTO
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Image.network(
                    item['foto'] ?? '',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      height: 160,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                  // BADGE KATEGORI
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        kategori,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _brandBlue,
                        ),
                      ),
                    ),
                  ),
                  // RATING
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 13, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            rating > 0 ? rating.toStringAsFixed(1) : 'Baru',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // INFO
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['nama'] ?? '-',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: _brandBlue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item['alamat_lengkap'] ?? item['lokasi'] ?? '-',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mulai dari',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          Text(
                            'Rp ${_formatHarga(item['harga_tiket_weekday'] ?? 0)}',
                            style: TextStyle(
                              color: _brandBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _brandBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Lihat Detail',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
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

  String _formatHarga(int harga) {
    if (harga == 0) return 'Gratis';
    return harga.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }
}
