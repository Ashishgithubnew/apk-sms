import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WatchAttendanceScreen extends StatefulWidget {
  @override
  _WatchAttendanceScreenState createState() => _WatchAttendanceScreenState();
}

class _WatchAttendanceScreenState extends State<WatchAttendanceScreen> {
  DateTime fromDate = DateTime.now().subtract(Duration(days: 7));
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
        showSnackbar("No token found. Please log in.");
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
        showSnackbar("Failed to fetch attendance.");
      }
    } catch (e) {
      showSnackbar("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
            showSnackbar("To Date cannot be earlier than From Date.");
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
      appBar: AppBar(title: Text("Watch Attendance")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => selectDate(context, true),
                  child: Text(
                      "From: ${DateFormat('dd/MM/yyyy').format(fromDate)}"),
                ),
                ElevatedButton(
                  onPressed: () => selectDate(context, false),
                  child: Text("To: ${DateFormat('dd/MM/yyyy').format(toDate)}"),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: fetchAttendance,
              child: Text("Fetch Attendance"),
            ),
            SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: attendanceData.length,
                      itemBuilder: (context, index) {
                        final entry = attendanceData[index];
                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(entry['date']))}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                Divider(),
                                ...entry['factList'].map<Widget>((student) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          student['name'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Chip(
                                          label: Text(student['attendance']),
                                          backgroundColor:
                                              student['attendance'] == 'Present'
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
