// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/auth_screen/login.dart';
import 'package:sms_apk/utils/app_colors.dart';
import 'package:sms_apk/widgets/custom_popup.dart';
import 'package:sms_apk/widgets/user_icon.dart';

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
      } else {
        showPopup(
            context,
            'Failed to load faculty data: ${response.statusCode}',
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
            backgroundColor: AppColors.primary,
            title:
                Text('Confirm Delete', style: TextStyle(color: Colors.white)),
            content: Text('Are you sure you want to delete this faculty?',
                style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> editFaculty(Map<String, dynamic> faculty) async {
    try {
      final response = await http.post(
        Uri.parse('https://s-m-s-keyw.onrender.com/faculty/Update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(faculty),
      );

      if (response.statusCode == 200) {
        setState(() {
          int index =
              facultyList.indexWhere((f) => f['fact_id'] == faculty['fact_id']);
          if (index != -1) {
            facultyList[index] = faculty;
          }
        });

        showPopup(context, 'Faculty updated successfully', AppColors.primary);
      } else {
        showPopup(context, 'Failed to update faculty: ${response.statusCode}',
            AppColors.primary);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void showEditForm(Map<String, dynamic> faculty) {
    final formKey = GlobalKey<FormState>();
    Map<String, dynamic> updatedFaculty = Map.from(faculty);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.primary, // Use your theme color
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: const Text(
            'Edit Faculty',
            style: TextStyle(color: Colors.white),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: faculty['fact_Name'],
                    decoration: InputDecoration(
                      labelText: 'Name',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) => updatedFaculty['fact_Name'] = value,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter a name'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: faculty['fact_email'],
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) => updatedFaculty['fact_email'] = value,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter an email'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: faculty['fact_contact'],
                    decoration: InputDecoration(
                      labelText: 'Contact',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) =>
                        updatedFaculty['fact_contact'] = value,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: faculty['fact_address'],
                    decoration: InputDecoration(
                      labelText: 'Address',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) =>
                        updatedFaculty['fact_address'] = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  editFaculty(updatedFaculty);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Faculty Table',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: const [
        UserIconWidget(userName: "Aditya Sharma",), // UserIconWidget placed in actions
        SizedBox(width: 10), // Adds some spacing
      ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
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
                      color: AppColors.primary.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              faculty['fact_Name'] ?? 'N/A',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _buildInfoRow('City', faculty['fact_city']),
                            _buildInfoRow('Contact', faculty['fact_contact']),
                            _buildInfoRow('Gender', faculty['fact_gender']),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _buildActionButton(
                                  icon: Icons.edit,
                                  color: Colors.blue,
                                  tooltip: 'Edit Faculty',
                                  onTap: () => showEditForm(faculty),
                                ),
                                const SizedBox(width: 8),
                                _buildActionButton(
                                  icon: Icons.delete,
                                  color: Colors.red,
                                  tooltip: 'Delete Faculty',
                                  onTap: () =>
                                      deleteFaculty(faculty['fact_id']),
                                ),
                              ],
                            ),
                          ],
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
