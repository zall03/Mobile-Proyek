import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_destinasi_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _wishlist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() => _isLoading = true);
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final response = await _supabase
          .from('wishlist')
          .select('*, destinasi(*)')
          .eq('user_uuid', user.id);
      setState(() {
        _wishlist = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error load wishlist: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromWishlist(int destinasiId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase
        .from('wishlist')
        .delete()
        .eq('user_uuid', user.id)
        .eq('id_destinasi', destinasiId);
    _loadWishlist(); // refresh
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dihapus dari wishlist')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        backgroundColor: const Color(0xFF1E7AC1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wishlist.isEmpty
          ? const Center(child: Text('Belum ada destinasi di wishlist'))
          : ListView.builder(
              itemCount: _wishlist.length,
              itemBuilder: (context, index) {
                final item = _wishlist[index];
                final destinasi = item['destinasi'];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        destinasi['foto'] ?? '',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey,
                          child: const Icon(Icons.image),
                        ),
                      ),
                    ),
                    title: Text(destinasi['nama'] ?? 'Destinasi'),
                    subtitle: Text(destinasi['lokasi'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () =>
                          _removeFromWishlist(destinasi['id_destinasi']),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailDestinasiScreen(
                            destinationData: destinasi,
                            reviews: const [],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
