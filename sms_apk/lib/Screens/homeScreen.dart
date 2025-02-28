// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:sms_apk/widgets/header.dart';
import '../widgets/drawer_menu.dart'; // Import Drawer Menu
import '../widgets/menu_card.dart'; // Import Menu Cards


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
            const Text('Welcome, Teacher!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  MenuCard(
                      icon: Icons.check_circle,
                      title: 'Mark Attendance',
                      color: Colors.green,
                      onTap: () {}),
                  MenuCard(
                      icon: Icons.bar_chart,
                      title: 'View Reports',
                      color: Colors.blue,
                      onTap: () {}),
                  MenuCard(
                      icon: Icons.group,
                      title: 'Manage Students',
                      color: Colors.orange,
                      onTap: () {}),
                  MenuCard(
                      icon: Icons.settings,
                      title: 'Settings',
                      color: Colors.grey,
                      onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
