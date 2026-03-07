import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zglovosnylnowriqeaya.supabase.co',
    anonKey: 'sb_publishable_p6ntwZ-oKKajwGV3lUhaHg_L1YUrhD0',
  );

  runApp(const WisKuyyApp());
}

final supabase = Supabase.instance.client;

class WisKuyyApp extends StatelessWidget {
  const WisKuyyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WisKuyy Ciayumajakuning',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription _authSubscription;
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Cek session awal
    _isLoggedIn = supabase.auth.currentSession != null;
    _isLoading = false;

    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      print('DEBUG AUTH EVENT: ${data.event}'); // ← tambah ini
      if (!mounted) return;
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        print('DEBUG: setState isLoggedIn = true'); // ← tambah ini
        setState(() => _isLoggedIn = true);
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() => _isLoggedIn = false);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SplashScreen();
    return _isLoggedIn ? const HomeScreen() : const SplashScreen();
  }
}
