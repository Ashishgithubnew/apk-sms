// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/auth_screen/login.dart';
import 'package:sms_apk/utils/app_colors.dart';
import 'package:sms_apk/widgets/custom_popup.dart';
import 'package:sms_apk/widgets/header.dart';

class FacultyTableScreen extends StatefulWidget {
  const FacultyTableScreen({super.key});

  @override
  _FacultyTableScreenState createState() => _FacultyTableScreenState();
}

class _FacultyTableScreenState extends State<FacultyTableScreen> {
  List<dynamic> facultyList = [];
  bool isLoading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    fetchTokenAndFaculty();
  }

  Future<void> fetchTokenAndFaculty() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('authToken');
    if (token != null) {
      fetchFaculty();
    } else {
      showPopup(
          context, 'Token not found. Please log in again.', AppColors.primary);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  Future<void> fetchFaculty() async {
    try {
      final response = await http.get(
        Uri.parse('https://s-m-s-keyw.onrender.com/faculty/findAllFaculty'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          facultyList = json.decode(response.body);
        });
      } else if (response.statusCode == 400) {
          final responseBody = jsonDecode(response.body);
          final errorMessage = responseBody["detail"] ??
              "Invalid request. Please check your input.";
          showPopup(context, errorMessage, AppColors.primary);
        } else {
        showPopup(
            context,
            'No Data Available',
            AppColors.primary);
      }
    } catch (e) {
      showPopup(context, 'Error: $e', AppColors.primary);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteFaculty(String facultyId) async {
    bool confirmDelete = await showDeleteConfirmation(context);
    if (!confirmDelete) return;

    try {
      final response = await http.post(
        Uri.parse(
            'https://s-m-s-keyw.onrender.com/faculty/delete?id=$facultyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          facultyList.removeWhere((faculty) => faculty['fact_id'] == facultyId);
        });
        showPopup(context, 'Faculty deleted successfully', AppColors.primary);
      } else {
        showPopup(context, 'Failed to delete faculty: ${response.statusCode}',
            AppColors.primary);
      }
    } catch (e) {
      showPopup(context, 'Error: $e', AppColors.primary);
    }
  }

  Future<bool> showDeleteConfirmation(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title:
                Text('Delete Faculty'),
            content: Text('Are you sure you want to delete this faculty?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child:
                    Text('Cancel', style: TextStyle(color: AppColors.primary)),
              ),
              TextButton(
                style: TextButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => Navigator.pop(context, true),
                child: Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: Header(text: "Faculty Table"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary,))
          : facultyList.isEmpty
              ? _buildEmptyState() // Improved "No Data" UI
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  itemCount: facultyList.length,
                  itemBuilder: (context, index) {
                    final faculty = facultyList[index];
                    return Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      shadowColor: AppColors.primary,
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(
                          faculty['fact_Name'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow('City', faculty['fact_city']),
                            _buildInfoRow('Contact', faculty['fact_contact']),
                            _buildInfoRow('Gender', faculty['fact_gender']),
                          ],
                        ),
                        trailing: _buildActionButton(
                          icon: Icons.delete,
                          color: AppColors.primary,
                          tooltip: 'Delete Faculty',
                          onTap: () => deleteFaculty(faculty['fact_id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  /// Helper Widget for Displaying Faculty Info Row
  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: ${value ?? 'N/A'}',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  /// Helper Widget for Action Buttons (Edit & Delete)
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10), // Larger tap target
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  /// Improved Empty State UI
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            'No data available',
            style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
