import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserIconWidget extends StatefulWidget {
  const UserIconWidget({super.key});

  @override
  _UserIconWidgetState createState() => _UserIconWidgetState();
}

class _UserIconWidgetState extends State<UserIconWidget> {
  String? userName;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchAndStoreUserData();
  }

  /// Fetches data from API and stores it in SharedPreferences
  Future<void> fetchAndStoreUserData() async {
    try {
      final response = await http.get(Uri.parse('https://s-m-s-keyw.onrender.com/self'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Store full API response in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', json.encode(data));

        // Extract username
        extractUserName(data);
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      print('Error fetching user data: $error');
    }
  }

  /// Extracts username based on "role"
  void extractUserName(Map<String, dynamic> data) {
    setState(() {
      if (data["role"] == "user") {
        userName = data["schoolCreationEntity"]?["ownerName"] ?? "Guest";
      } else if (data["role"] == "sub-user") {
        userName = data["facultyInfo"]?["fact_Name"] ?? "Guest";
      } else {
        userName = "Guest";
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.person, color: Colors.white),
        const SizedBox(width: 8),
        if (isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
        else if (hasError)
          const Icon(Icons.error, color: Colors.red, size: 18)
        else
          Text(
            userName ?? "Guest",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}
