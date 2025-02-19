import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentAttendanceScreen extends StatefulWidget {
  @override
  _StudentAttendanceScreenState createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  bool masterAttendance = false;
  String? selectedClass;
  String? selectedSubject;
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  List<dynamic> attendanceData = [];
  bool isLoading = false;
  List<Map<String, dynamic>> classData = [];

  @override
  void initState() {
    super.initState();
    fetchClassData();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> fetchClassData() async {
    setState(() {
      isLoading = true;
    });

    final token = await getToken();
    if (token == null) {
      showSnackbar("No token found. Please log in.");
      return;
    }

    final String apiUrl = "https://s-m-s-keyw.onrender.com/class/data";
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          classData = List<Map<String, dynamic>>.from(data['classData'] ?? []);
          if (classData.isNotEmpty) {
            selectedClass = classData[0]['className'];
          }
        });
      } else {
        showSnackbar("Failed to fetch class data.");
      }
    } catch (e) {
      showSnackbar("Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<String> getSubjects() {
    if (selectedClass == null) return [];
    var selectedClassData = classData
        .firstWhere((c) => c['className'] == selectedClass, orElse: () => {});
    return List<String>.from(selectedClassData['subject'] ?? []);
  }

  Future<void> fetchAttendance() async {
    setState(() {
      isLoading = true;
    });

    final token = await getToken();
    if (token == null) {
      showSnackbar("No token found. Please log in.");
      return;
    }

    String formattedFromDate = DateFormat("yyyy-MM-dd").format(fromDate);
    String formattedToDate = DateFormat("yyyy-MM-dd").format(toDate);

    final String apiUrl =
        "https://s-m-s-keyw.onrender.com/attendance/getAttendance"
        "?cls=$selectedClass"
        "&fromDate=$formattedFromDate"
        "&toDate=$formattedToDate"
        "&subject=${masterAttendance ? '' : selectedSubject}"
        "&masterAttendance=$masterAttendance";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Authorization": "Bearer $token"},
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
      appBar: AppBar(title: Text("Master Attendance")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Master Attendance", style: TextStyle(fontSize: 18)),
                Switch(
                  value: masterAttendance,
                  onChanged: (value) {
                    setState(() {
                      masterAttendance = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedClass,
              items: classData.map((c) {
                return DropdownMenuItem<String>(
                  value: c['className'],
                  child: Text("Class ${c['className']}"),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedClass = newValue;
                  selectedSubject = null;
                });
              },
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => selectDate(context, true),
                  child: Text(
                      "From Date: ${DateFormat('yyyy-MM-dd').format(fromDate)}"),
                ),
                ElevatedButton(
                  onPressed: () => selectDate(context, false),
                  child: Text(
                      "To Date: ${DateFormat('yyyy-MM-dd').format(toDate)}"),
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
                          child: ListTile(
                            title: Text("Date: ${entry['date']}",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  entry['students'].map<Widget>((student) {
                                return Text(
                                    "${student['name']} - ${student['attendance']}");
                              }).toList(),
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
