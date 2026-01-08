import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'selection_screen.dart';
import 'package:sms_apk/hotel/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Easy Way Solution',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ================= Splash Screen =================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    String loginType = prefs.getString('loginType') ?? '';
    String? token = prefs.getString('token');

    // Delay for splash effect
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (!isLoggedIn || token == null) {
      _navigateToSelection();
      return;
    }

    _navigateByRole(loginType);
  }

  void _navigateByRole(String role) {
    switch (role.toLowerCase()) {
      case 'hotel':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HotelHomeScreen()),
        );
        break;
      case 'admin':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const HotelAdminDashboardScreen()),
        );
        break;
      default:
        _navigateToSelection();
    }
  }

  void _navigateToSelection() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 102, 102),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 30, 120, 120),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/ews-full-white.png',
                    height: 70,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Version 1.0.1',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Text(
              '© 2025 EasyWaySolution',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ================= Dummy Admin Dashboard =================
class HotelAdminDashboardScreen extends StatelessWidget {
  const HotelAdminDashboardScreen({super.key});

  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hotel Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: const Center(child: Text("Welcome Admin!")),
    );
  }
}
