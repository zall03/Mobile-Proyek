import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordObscured = true;
  bool _isConfirmObscured = true;
  final Color _brandBlue = const Color(0xFF1E7AC1);
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkRecoverySession();
  }

  Future<void> _checkRecoverySession() async {
    final session = _supabase.auth.currentSession;
    if (session == null || session.user == null) {
      if (mounted) {
        _showSnackBar(
          "Sesi tidak valid. Silakan ulangi proses.",
          color: Colors.red,
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        });
      }
    }
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmController.text.trim();

    // Validasi
    if (password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar("Password tidak boleh kosong!");
      return;
    }

    if (password.length < 6) {
      _showSnackBar("Password minimal 6 karakter!");
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("Password tidak cocok!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _supabase.auth.updateUser(UserAttributes(password: password));

      if (mounted) {
        _showSnackBar(
          "Password berhasil diubah!\nSilakan login kembali.",
          color: Colors.green,
        );

        // Bersihkan stack dan kembali ke Login
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      String message = "Gagal mengubah password";

      if (e.message.contains('Invalid') || e.message.contains('expired')) {
        message = "Link reset sudah kadaluarsa.\nSilakan minta link baru.";
      } else if (e.message.contains('Password')) {
        message = e.message;
      }

      _showSnackBar(message, color: Colors.red);
    } catch (e) {
      _showSnackBar("Terjadi kesalahan. Silakan coba lagi.", color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {Color? color}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color ?? Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Password Baru"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Masukkan Password Baru",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Password baru harus berbeda dari password sebelumnya",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _passwordController,
              obscureText: _isPasswordObscured,
              decoration: InputDecoration(
                labelText: "Password Baru",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordObscured
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => setState(
                    () => _isPasswordObscured = !_isPasswordObscured,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _confirmController,
              obscureText: _isConfirmObscured,
              decoration: InputDecoration(
                labelText: "Konfirmasi Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmObscured
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _isConfirmObscured = !_isConfirmObscured),
                ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandBlue,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Ubah Password",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
