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
  String selectedClass = "1";
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  List<dynamic> attendanceData = [];
  bool isLoading = false;

  // Hardcoded classes from 1 to 12
  final List<String> classes =
      List.generate(12, (index) => (index + 1).toString());

  @override
  void initState() {
    super.initState();
  }

  // Function to get token
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Function to fetch attendance
  Future<void> fetchAttendance() async {
    setState(() {
      isLoading = true;
    });

    final token = await getToken();
    if (token == null) {
      showSnackbar("No token found. Please log in.");
      return;
    }

    String formattedFromDate = DateFormat("dd/MM/yyyy").format(fromDate);
    String formattedToDate = DateFormat("dd/MM/yyyy").format(toDate);

    final String apiUrl =
        "https://s-m-s-keyw.onrender.com/attendance/getAttendance"
        "?cls=$selectedClass"
        "&fromDate=$formattedFromDate"
        "&toDate=$formattedToDate"
        "&subject="
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

  // Function to show snackbar
  void showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Function to show Date Picker
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
        } else {
          toDate = picked;
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

            // Class Dropdown (Hardcoded 1 to 12)
            DropdownButton<String>(
              value: selectedClass,
              items: classes.map((String className) {
                return DropdownMenuItem<String>(
                  value: className,
                  child: Text("Class $className"),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedClass = newValue!;
                });
              },
            ),

            SizedBox(height: 10),

            // Date Pickers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("From Date: ${fromDate.toString().split(" ")[0]}"),
                ElevatedButton(
                  onPressed: () => selectDate(context, true),
                  child: Text("Select"),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("To Date: ${toDate.toString().split(" ")[0]}"),
                ElevatedButton(
                  onPressed: () => selectDate(context, false),
                  child: Text("Select"),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Fetch Attendance Button
            ElevatedButton(
              onPressed: fetchAttendance,
              child: Text("Fetch Attendance"),
            ),

            SizedBox(height: 20),

            // Loading Indicator
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else
              // Display Attendance Data Properly
              Expanded(
                child: ListView.builder(
                  itemCount: attendanceData.length,
                  itemBuilder: (context, index) {
                    var attendanceEntry =
                        attendanceData[index]; // Each date entry
                    String formattedDate = DateFormat("dd/MM/yyyy").format(
                        DateTime.parse(
                            attendanceEntry["date"])); // Convert date format

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show Date as a Heading
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            "Date: $formattedDate",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),

                        // Iterate over students inside this date entry
                        ...attendanceEntry["students"].map<Widget>((student) {
                          return ListTile(
                            title: Text(
                                student["name"] ?? "Unknown"), // Student Name
                            subtitle: Text(student["remark"]?.isNotEmpty == true
                                ? student["remark"]
                                : "No remarks"), // Show remarks if available
                            trailing: Text(
                              student["attendance"] ?? "N/A",
                              style: TextStyle(
                                color: student["attendance"] == "Present"
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ), // Show attendance status
                          );
                        }).toList(),
                      ],
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
