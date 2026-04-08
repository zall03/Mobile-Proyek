import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email; // Kita butuh email user untuk verifikasi

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  Future<void> _verify() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan kode verifikasi!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Kirim kode OTP ke Supabase
      final AuthResponse res = await _supabase.auth.verifyOTP(
        type: OtpType.signup, // Tipe signup karena ini pendaftaran baru
        token: _otpController.text.trim(),
        email: widget.email,
      );

      if (res.session != null) {
        // BERHASIL! Simpan sesi login
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', widget.email);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Verifikasi Berhasil!")));

          // Pindah ke Home dan hapus semua halaman sebelumnya
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gagal: ${e.message}",
            ), // Biasanya "Token has expired or is invalid"
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Verifikasi Email"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cek Email Kamu",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Kami telah mengirimkan kode verifikasi 6 digit ke email:\n${widget.email}",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "000000",
                counterText: "",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Verifikasi Akun",
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
    );
  }
}
