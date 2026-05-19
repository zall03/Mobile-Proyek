import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'reset_password_screen.dart';

class ResetConfirmationScreen extends StatefulWidget {
  final String email;

  const ResetConfirmationScreen({super.key, required this.email});

  @override
  State<ResetConfirmationScreen> createState() =>
      _ResetConfirmationScreenState();
}

class _ResetConfirmationScreenState extends State<ResetConfirmationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  int _cooldown = 60;
  Timer? _timer;
  final Color _brandBlue = const Color(0xFF1E7AC1);
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

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final otp = _otpCode;

    if (otp.length < 6) {
      _showSnackBar("Masukkan 6 digit kode OTP!", color: Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _supabase.auth.verifyOTP(
        email: widget.email,
        token: otp,
        type: OtpType.email,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        );
      }
    } on AuthException catch (e) {
      String message = "Kode OTP tidak valid atau sudah kadaluarsa.";
      if (e.message.contains('expired')) {
        message = "Kode OTP sudah kadaluarsa. Minta kode baru.";
      }
      _showSnackBar(message, color: Colors.red);
      _clearOtp();
    } catch (e) {
      _showSnackBar("Terjadi kesalahan. Silakan coba lagi.", color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearOtp() {
    for (final c in _otpControllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);

    try {
      await _supabase.auth.signInWithOtp(
        email: widget.email,
        shouldCreateUser: false,
      );
      _showSnackBar("Kode OTP telah dikirim ulang", color: Colors.green);
      _startCooldown();
      _clearOtp();
    } catch (e) {
      _showSnackBar("Gagal mengirim ulang kode OTP.", color: Colors.red);
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
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _brandBlue, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          // Auto verify kalau sudah 6 digit
          if (_otpCode.length == 6) {
            _verifyOtp();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.lock_outline, size: 80, color: Color(0xFF1E7AC1)),
            const SizedBox(height: 24),
            const Text(
              "Masukkan Kode OTP",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Kode OTP telah dikirim ke:\n${widget.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 36),

            // OTP Box
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) => _buildOtpBox(index)),
            ),
            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
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
                        "Verifikasi OTP",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            TextButton(
              onPressed: _cooldown > 0 || _isLoading ? null : _resendOtp,
              child: Text(
                _cooldown > 0
                    ? "Kirim ulang kode ($_cooldown detik)"
                    : "Kirim Ulang Kode",
                style: TextStyle(
                  color: _cooldown > 0 ? Colors.grey : _brandBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
