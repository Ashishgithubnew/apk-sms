import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/utils/app_colors.dart';
import 'package:sms_apk/widgets/custom_popup.dart';
import 'package:sms_apk/widgets/user_icon.dart';

class ViewAttendance extends StatefulWidget {
  const ViewAttendance({super.key});

  @override
  _ViewAttendanceState createState() => _ViewAttendanceState();
}

class _ViewAttendanceState extends State<ViewAttendance> {
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime toDate = DateTime.now();
  List<dynamic> attendanceData = [];
  bool isLoading = false;

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> fetchAttendance() async {
    setState(() {
      isLoading = true;
    });

    String formattedFromDate = DateFormat("dd/MM/yyyy").format(fromDate);
    String formattedToDate = DateFormat("dd/MM/yyyy").format(toDate);

    final String apiUrl =
        "https://s-m-s-keyw.onrender.com/faculty/getAttendance"
        "?fromDate=$formattedFromDate&toDate=$formattedToDate";

    try {
      final token = await getToken();
      if (token == null) {
        showPopup(context, "No token found. Please log in.", Colors.red);
        return;
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          attendanceData = jsonDecode(response.body);
        });
      } else {
        showPopup(context, "Failed to fetch attendance.", Colors.red);
      }
    } catch (e) {
      showPopup(context, "Error: $e", Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? fromDate : toDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
          if (toDate.isBefore(fromDate)) {
            toDate = fromDate;
          }
        } else {
          if (picked.isBefore(fromDate)) {
            showPopup(context, "To Date cannot be earlier than From Date.",
                Colors.red);
          } else {
            toDate = picked;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Attendance" , style: TextStyle(color: Colors.white, fontSize: 18),),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: const [
          UserIconWidget(
            userName: "Aditya Sharma",
          ), // UserIconWidget placed in actions
          SizedBox(width: 10), // Adds some spacing
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDateButton(
                    "From: ${DateFormat('dd/MM/yyyy').format(fromDate)}",
                    () => selectDate(context, true)),
                _buildDateButton(
                    "To: ${DateFormat('dd/MM/yyyy').format(toDate)}",
                    () => selectDate(context, false)),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: fetchAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  "Fetch Attendance",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : attendanceData.isEmpty
                      ? const Center(
                          child: Text(
                            "No attendance data found.",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: attendanceData.length,
                          itemBuilder: (context, index) {
                            final entry = attendanceData[index];
                            return _buildAttendanceCard(entry);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> entry) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(entry['date']))}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blueAccent,
              ),
            ),
            const Divider(),
            ...entry['factList'].map<Widget>((student) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      student['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Chip(
                      label: Text(
                        student['attendance'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: student['attendance'] == 'Present'
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
