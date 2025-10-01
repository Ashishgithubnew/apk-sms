import 'package:flutter/material.dart';
import 'package:sms_apk/splashScreen.dart';
import 'package:sms_apk/hotel/home_screen.dart'; // <-- import your HotelHomeScreen file
// add imports for login, register guest, reports etc if you have them
import 'package:sms_apk/hotel/hotelScreen/hoteltabel_screen.dart';
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
      routes: {
        '/hotel-home': (context) => const HotelHomeScreen(),
        '/hotel-customer': (context) => const PlaceholderScreen(title: "Register New Guest"),
      
     '/hotel-tabel': (context) => const HotelGuestHistoryScreen(),
      },
    );
  }
}

/// Temporary placeholder screens so app won’t crash
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text("$title Screen Coming Soon...")),
    );
  }
}
