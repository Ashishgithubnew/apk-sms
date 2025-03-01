import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth_screen/profile_screen.dart';

class Header extends StatefulWidget implements PreferredSizeWidget {
  final String text;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const Header({super.key, required this.text, this.scaffoldKey});

  @override
  _HeaderState createState() => _HeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HeaderState extends State<Header> {
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

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 18, 102, 102),
      title: Text(
        widget.text,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            borderRadius: BorderRadius.circular(20), // Smooth hover effect
            splashColor: Colors.teal.shade300.withOpacity(0.5), // Splash effect
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(0.2), // Light translucent background
                borderRadius: BorderRadius.circular(20), // Rounded edges
              ),
              child: Row(
                children: [
                  const Icon(Icons.person,
                      color: Colors.white, size: 20), // Smaller icon
                  const SizedBox(width: 6),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold, // Make text stand out
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      leading: widget.scaffoldKey != null
          ? IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => widget.scaffoldKey!.currentState?.openDrawer(),
            )
          : Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
    );
  }
}
