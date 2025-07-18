// ignore_for_file: file_names

import 'package:flutter/material.dart';
import './school/auth_screen/login.dart';
import 'selection_screen.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
 @override
void initState() {
  super.initState();
  Timer(const Duration(seconds: 3), () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SelectionScreen()),
    );
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 18, 102, 102),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(
                        255, 30, 120, 120), // Slightly lighter shade
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/ews-full-white.png',
                    height: 70, // Adjust height as needed
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(
                    height:
                        12), // Adds spacing between text box and version text
                Text(
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
          Positioned(
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
