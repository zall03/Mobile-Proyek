import 'package:flutter/material.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final Color _brandBlue = const Color(0xFF1E7AC1);
  final Map<String, List<Map<String, dynamic>>> _groupedWishlist = {
    'Gunung': [
      {'foto': 'https://images.unsplash.com/photo-1589309736404-2e142a2acdf0'},
      {'foto': 'https://images.unsplash.com/photo-1603483080228-04f2313d9f10'},
      {'foto': 'https://images.unsplash.com/photo-1549887534-1541e9326642'},
      {'foto': 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b'},
    ],
    'Laut': [
      {'foto': 'https://images.unsplash.com/photo-1498623116890-37e912163d5d'},
      {'foto': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _brandBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER TITLE (Tanpa Tombol Back) ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Text(
                'My Wishlist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // --- WHITE SHEET CONTENT ---
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 24, right: 24, top: 30),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: GridView.builder(
                  padding: const EdgeInsets.only(
                    bottom: 100,
                  ), // Padding bawah agar tidak tertutup bottom nav
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _groupedWishlist.keys.length + 1,
                  itemBuilder: (context, index) {
                    // Tampilkan tombol "New Collection" di urutan terakhir
                    if (index == _groupedWishlist.keys.length) {
                      return _buildNewCollectionCard();
                    }

                    // Tampilkan Card Kategori
                    String kategori = _groupedWishlist.keys.elementAt(index);
                    List<Map<String, dynamic>> items =
                        _groupedWishlist[kategori]!;

                    return _buildCategoryCard(kategori, items);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CARD KATEGORI ---
  Widget _buildCategoryCard(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kotak Gambar Kolase
        Expanded(
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade200,
            ),
            child: _buildImageCollage(items),
          ),
        ),
        const SizedBox(height: 12),
        // Teks Kategori & Jumlah
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${items.length} Tempat',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  // --- WIDGET PEMBUAT KOLASE 4 GAMBAR ---
  Widget _buildImageCollage(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(child: Icon(Icons.image, color: Colors.grey));
    }

    // Jika gambar cuma 1, penuhi layar
    if (items.length == 1) {
      return Image.network(
        items[0]['foto'],
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300),
      );
    }

    // Ambil maksimal 4 gambar untuk grid
    int imageCount = items.length > 4 ? 4 : items.length;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2, // Garis pembatas antar foto
        mainAxisSpacing: 2,
      ),
      itemCount: imageCount,
      itemBuilder: (context, index) {
        return Image.network(
          items[index]['foto'],
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300),
        );
      },
    );
  }

  // --- WIDGET TOMBOL NEW COLLECTION ---
  Widget _buildNewCollectionCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade400,
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.grey.shade600, size: 32),
                const SizedBox(height: 8),
                Text(
                  'New Collection\nWishlist',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        // Spacer transparan agar menyeimbangkan layout grid di bawahnya
        const SizedBox(height: 12),
        const Text('', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        const Text('', style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
