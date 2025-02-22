// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import '../widgets/drawer_menu.dart'; // Import Drawer Menu
import '../widgets/menu_card.dart'; // Import Menu Cards
import '../widgets/user_icon.dart'; // Import User Icon Widget

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Fix for Drawer
  String? userName =
      "Aditya Sharma"; // Replace this with dynamic username from API

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 102, 102),
        title: Text("Dashboard", style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: UserIconWidget(userName: "Aditya Sharma"),
          )
        ],
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),

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
