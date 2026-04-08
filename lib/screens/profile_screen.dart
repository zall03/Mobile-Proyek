import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  String _fullName = "";
  String _email = "";
  String _gender = "-";
  String _phone = "-";
  String? _photoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // FUNGSI INI SUDAH DIPERBAIKI (MENGGUNAKAN SELECT, BUKAN UPSERT)
  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Ambil email dari data Auth
        _email = user.email ?? "-";

        // Ambil data profil dari tabel 'users'
        final data = await supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle(); // maybeSingle mencegah error jika data belum ada

        if (data != null) {
          _fullName = data['name'] ?? "User";
          _phone = data['no_telepon'] ?? "-";
          _gender = data['jenis_kelamin'] ?? "-";
          _photoUrl = data['foto_profil'];
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String getEmailInitial(String email) {
    if (email.isEmpty || email == "-") return "?";
    return email[0].toUpperCase();
  }

  String getFirstName(String name) {
    List<String> parts = name.trim().split(' ');
    return parts.isNotEmpty ? parts[0] : "";
  }

  String getLastName(String name) {
    List<String> parts = name.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : "";
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Konfirmasi Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      await supabase.auth.signOut();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saat logout: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E7AC1)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1E7AC1),
                              width: 3,
                            ),
                            color: Colors.grey.shade200,
                            image: _photoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_photoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _photoUrl == null
                              ? Center(
                                  child: Text(
                                    getEmailInitial(_email),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E7AC1),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _fullName.isEmpty ? "User" : _fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _email,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PERSONAL INFORMATION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.person_outline,
                                'First Name',
                                getFirstName(_fullName),
                              ),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _buildInfoRow(
                                Icons.person_outline,
                                'Last Name',
                                getLastName(_fullName),
                              ),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _buildInfoRow(
                                Icons.verified_user_outlined,
                                'Gender',
                                _gender,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'CONTACT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.email_outlined,
                                'Email Address',
                                _email,
                              ),
                              Divider(height: 1, color: Colors.grey.shade200),
                              _buildInfoRow(
                                Icons.phone_android_outlined,
                                'Phone Number',
                                _phone,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(
                          initialName: _fullName,
                          initialEmail: _email,
                          initialGender: _gender,
                          initialPhone: _phone,
                          initialPhoto: _photoUrl,
                        ),
                      ),
                    );
                    if (result == true) {
                      _fetchUserData(); // Refresh data setelah kembali dari EditProfileScreen
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () => _showLogoutDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade600, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? "-" : value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
