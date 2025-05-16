import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/auth_screen/login.dart';
import 'package:sms_apk/utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "Guest";
  String email = "example@mail.com";
  String role = "User";
  String schoolAddress = "N/A";
  String adminContact = "N/A";
  String factAddress = "N/A";
  String factContact = "N/A";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Fetch stored user data from SharedPreferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? "Guest";
      email = prefs.getString('email') ?? "example@mail.com";
      role = prefs.getString('role') ?? "User";
      schoolAddress = prefs.getString('schoolAddress') ?? "N/A";
      adminContact = prefs.getString('adminContact') ?? "N/A";
      factAddress = prefs.getString('factAddress') ?? "N/A";
      factContact = prefs.getString('factContact') ?? "N/A";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 18, 102, 102),
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),

            // User Name
            Text(
              userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Role
            Text(
              "Role : $role",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),

            // Profile Details Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _profileDetailRow(Icons.email, "Email", email),
                    // _profileDetailRow(Icons.work, "Role", role),
                    if (role == "user") ...[
                      _profileDetailRow(
                          Icons.location_on, "Address", schoolAddress),
                      _profileDetailRow(
                          Icons.phone, "Contact", adminContact),
                    ],
                    if (role == "sub-user") ...[
                      _profileDetailRow(
                          Icons.location_city, "Address", factAddress),
                      _profileDetailRow(
                          Icons.phone_android, "Contact", factContact),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),

            // Logout Button
            ElevatedButton.icon(
              icon: Icon(Icons.logout, color: AppColors.logout),
              label: Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.logout,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 2,
              ),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Clear all stored user data

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Helper method for profile details row
  Widget _profileDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 24),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
