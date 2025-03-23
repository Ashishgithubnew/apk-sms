// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/Screens/Student/markAttendance.dart';
import 'package:sms_apk/Screens/Student/studentTableScreen.dart';
import 'package:sms_apk/Screens/Student/viewAttendance.dart';
import 'package:sms_apk/auth_screen/profile_screen.dart';
import 'package:sms_apk/utils/app_colors.dart';
import 'package:sms_apk/widgets/header.dart';
import '../widgets/drawer_menu.dart'; // Import Drawer Menu
import '../widgets/menu_card.dart'; // Import Menu Cards

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "Guest"; // Default value

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  /// Fetches username from SharedPreferences
  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? "Guest";
    });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Fix for Drawer

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: Header(
          text: "Dashboard", scaffoldKey: _scaffoldKey), // Pass key to Header
      drawer: const DrawerMenu(), // Drawer from separate widget

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Welcome, $userName',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                color: Colors.white10, // Set background color
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  padding: const EdgeInsets.all(10), // Add padding for spacing
                  children: [
                    MenuCard(
                      icon: Icons.check_circle,
                      title: 'Mark Student Attendance',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MarkAttendanceScreen()),
                        );
                      },
                    ),
                    MenuCard(
                      icon: Icons.bar_chart,
                      title: 'View Student Attendance',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ViewAttendanceScreen()),
                        );
                      },
                    ),
                    MenuCard(
                      icon: Icons.group,
                      title: 'Manage Students',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => StudentTableScreen()),
                        );
                      },
                    ),
                    MenuCard(
                      icon: Icons.settings,
                      title: 'Settings',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfileScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
