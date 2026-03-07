import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreenTwo extends StatelessWidget {
  const OnboardingScreenTwo({super.key});

  final Color _brandBlue = const Color(0xFF1E7AC1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.grey[100],
                  image: const DecorationImage(
                    image: AssetImage('assets/images/poster.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const Spacer(flex: 2),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                    height: 1.2,
                  ),
                  children: [
                    const TextSpan(text: 'Semua\n'),
                    TextSpan(
                      text: 'Destinasi Kamu',
                      style: TextStyle(color: _brandBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'TravelEase menghadirkan perjalanan tak terlupakan bagi semua orang, menawarkan destinasi pilihan, panduan cerdas, dan pengalaman lancar yang menginspirasi setiap penjelajah.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
              ),

              const Spacer(flex: 3),

              // TOMBOL AYO MULAI
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandBlue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Ayo Mulai',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
