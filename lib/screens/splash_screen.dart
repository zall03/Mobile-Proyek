import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project2/screens/onboarding_screen.dart';
import 'package:project2/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  final int _totalSteps = 10;
  final Color _brandBlue = const Color(0xFF1E7AC1);

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() async {
    for (int i = 1; i <= _totalSteps; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _progress = i / _totalSteps;
        });
      }
    }

    if (!mounted) return;

    // Cek session Supabase
    final session = Supabase.instance.client.auth.currentSession;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            session != null ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo1.png',
                width:
                    MediaQuery.of(context).size.width *
                    0.6, // Ukuran 60% lebar layar
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback jika gambar belum dimasukkan ke folder assets
                  return const Text(
                    "WisKuyy Logo",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  );
                },
              ),
            ),

            // PROGRESS BAR DI BAWAH
            Positioned(
              bottom: 60,
              left: 40,
              right: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _brandBlue.withOpacity(0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_totalSteps, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 22,
                      width:
                          (MediaQuery.of(context).size.width - 120) /
                          _totalSteps,
                      decoration: BoxDecoration(
                        color: _progress > (index / _totalSteps)
                            ? _brandBlue
                            : _brandBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
