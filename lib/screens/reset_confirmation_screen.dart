import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'forgot_password_screen.dart';

class ResetConfirmationScreen extends StatefulWidget {
  final String email;

  const ResetConfirmationScreen({super.key, required this.email});

  @override
  State<ResetConfirmationScreen> createState() =>
      _ResetConfirmationScreenState();
}

class _ResetConfirmationScreenState extends State<ResetConfirmationScreen> {
  bool _isLoading = false;
  int _cooldown = 60;
  Timer? _timer;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _cooldown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown > 0) {
        setState(() => _cooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendLink() async {
    setState(() => _isLoading = true);

    try {
      await _supabase.auth.resetPasswordForEmail(
        widget.email,
        redirectTo: 'wiskuyy://reset-password',
      );

      _showSnackBar("Link reset telah dikirim ulang", color: Colors.green);
      _startCooldown();
    } catch (e) {
      _showSnackBar("Gagal mengirim ulang", color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {Color? color}) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color brandBlue = const Color(0xFF1E7AC1);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.email_outlined,
              size: 90,
              color: Color(0xFF1E7AC1),
            ),
            const SizedBox(height: 24),
            const Text(
              "Cek Email Kamu",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "Kami telah mengirim link reset password ke:\n${widget.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              "Cek juga folder Spam / Junk",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _cooldown > 0 || _isLoading ? null : _resendLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
              ),
              child: Text(
                _cooldown > 0
                    ? "Kirim Ulang ($_cooldown detik)"
                    : "Kirim Ulang",
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text("Kembali ke Login"),
            ),
          ],
        ),
      ),
    );
  }
}
