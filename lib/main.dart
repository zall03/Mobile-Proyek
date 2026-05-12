import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:intl/date_symbol_data_local.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reset_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

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
  bool _isLoggedIn = false;
  bool _isLoading = true;

  late final StreamSubscription<AuthState> _authSubscription;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();

    _initializeAuth();
    _setupDeepLinks();
  }

  Future<void> _initializeAuth() async {
    // Cek session saat pertama kali buka aplikasi
    setState(() {
      _isLoggedIn = supabase.auth.currentSession != null;
      _isLoading = false;
    });

    // Listen perubahan auth state
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      print('DEBUG AUTH EVENT: ${data.event}');

      if (!mounted) return;

      final event = data.event;

      switch (event) {
        case AuthChangeEvent.signedIn:
          setState(() => _isLoggedIn = true);
          break;
        case AuthChangeEvent.signedOut:
          setState(() => _isLoggedIn = false);
          break;
        case AuthChangeEvent.passwordRecovery:
          // User membuka link reset password
          print('DEBUG: Password Recovery Event');
          _navigateToResetPassword();
          break;
        default:
          break;
      }
    });
  }

  Future<void> _setupDeepLinks() async {
    // Handle deep link saat aplikasi dibuka dari luar (cold start)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        await _handleDeepLink(initialLink);
      }
    } catch (e) {
      print('Initial deep link error: $e');
    }

    // Listen deep link saat aplikasi sudah berjalan
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) async {
        await _handleDeepLink(uri);
      },
      onError: (err) {
        print('Deep link error: $err');
      },
    );
  }

  Future<void> _handleDeepLink(Uri uri) async {
    print('Received deep link: $uri');

    if (uri.path.contains('reset-password') ||
        uri.toString().contains('reset')) {
      try {
        await supabase.auth.getSessionFromUrl(uri);
        // Jika berhasil, event passwordRecovery akan ter-trigger otomatis
      } catch (e) {
        print('Error processing deep link: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Link reset password tidak valid atau sudah kadaluarsa',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToResetPassword() {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }
    return _isLoggedIn ? const HomeScreen() : const SplashScreen();
  }
}
