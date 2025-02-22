import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/utils/app_colors.dart';
import 'package:sms_apk/widgets/user_icon.dart';
import 'package:sms_apk/widgets/custom_popup.dart';

class MarkAttendance extends StatefulWidget {
  const MarkAttendance({super.key});

  @override
  _MarkAttendanceState createState() => _MarkAttendanceState();
}

class _MarkAttendanceState extends State<MarkAttendance> {
  List facultyList = [];
  Map<String, String> attendance = {};
  TextEditingController searchController = TextEditingController();
  List filteredList = [];
  String? token;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTokenAndFacultyList();
  }

  /// Fetch auth token and faculty list
  Future<void> fetchTokenAndFacultyList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('authToken');

    if (token == null) {
      showPopup(
          context, 'Token not found. Please log in again.', AppColors.error);
      return;
    }

    await fetchFacultyList();
  }

  /// Fetch faculty list from API
  Future<void> fetchFacultyList() async {
    try {
      final response = await http.get(
        Uri.parse('https://s-m-s-keyw.onrender.com/faculty/findAllFaculty'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          facultyList = json.decode(response.body);
          filteredList = facultyList;
          isLoading = false;
        });
      } else {
        showPopup(context, 'Failed to fetch faculty list', AppColors.error);
      }
    } catch (e) {
      showPopup(context, 'Error: $e', AppColors.error);
    }
  }

  /// Filter faculty list based on search input
  void filterSearchResults(String query) {
    List tempList = facultyList
        .where((faculty) =>
            faculty['fact_Name'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      filteredList = tempList;
    });
  }

  /// Send attendance data to the API with correct JSON format
  Future<void> saveAttendance() async {
    List<Map<String, dynamic>> factList = facultyList.map((faculty) {
      return {
        "factId": faculty['fact_id'].toString(),
        "name": faculty['fact_Name'].toString(),
        "attendance": attendance[faculty['fact_id']] ?? "Absent"
      };
    }).toList();

    final Map<String, dynamic> requestBody = {"factList": factList};

    try {
      final response = await http.post(
        Uri.parse('https://s-m-s-keyw.onrender.com/faculty/attendanceSave'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        showPopup(
            context, 'Attendance updated successfully', AppColors.success);
      } else {
        showPopup(context, 'Failed to update attendance', AppColors.error);
      }
    } catch (e) {
      showPopup(context, 'Error: $e', AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance', style: TextStyle(color: Colors.white, fontSize: 18),),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: const [
          UserIconWidget(
            userName: "Aditya Sharma",
          ),
          SizedBox(width: 10),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Faculty',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: filterSearchResults,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        var faculty = filteredList[index];
                        return _buildFacultyCard(faculty);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: saveAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFacultyCard(Map<String, dynamic> faculty) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          faculty['fact_Name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.primary,
          ),
        ),
        subtitle: Text(
          faculty['fact_email'],
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        trailing: DropdownButton<String>(
          value: attendance[faculty['fact_id']],
          hint: const Text('Select', style: TextStyle(color: AppColors.primary)),
          items: ['Present', 'Absent', 'Leave']
              .map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(
                      status,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              attendance[faculty['fact_id']] = value!;
            });
          },
        ),
      ),
    );
  }
}