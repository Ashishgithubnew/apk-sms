import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateAttendanceScreen extends StatefulWidget {
  @override
  _UpdateAttendanceScreenState createState() => _UpdateAttendanceScreenState();
}

class _UpdateAttendanceScreenState extends State<UpdateAttendanceScreen> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = "";
  String? selectedClass;
  String? selectedSubject;
  DateTime selectedDate = DateTime.now();
  bool masterAttendance = false;
  List<Map<String, dynamic>> classData = [];

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> fetchClasses() async {
    try {
      final token = await getToken();
      if (token == null) {
        showError("No token found. Please log in.");
        return;
      }

      final url = Uri.parse("https://s-m-s-keyw.onrender.com/class/data");
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          classData = List<Map<String, dynamic>>.from(data["classData"]);
        });
      } else {
        showError("Failed to load classes");
      }
    } catch (e) {
      showError("Error fetching classes: ${e.toString()}");
    }
  }

  Future<void> fetchAttendance() async {
    try {
      if (selectedClass == null || selectedSubject == null) {
        showError("Please select class and subject");
        return;
      }

      setState(() {
        isLoading = true;
        hasError = false;
      });

      final token = await getToken();
      if (token == null) {
        showError("No token found. Please log in.");
        return;
      }

      final formattedDate = "${selectedDate.toLocal()}".split(' ')[0];

      final url = Uri.parse(
        'https://s-m-s-keyw.onrender.com/attendance/getAttendance'
        '?cls=$selectedClass'
        '&fromDate=$formattedDate'
        '&toDate=$formattedDate'
        '&subject=$selectedSubject'
        '&masterAttendance=$masterAttendance',
      );

      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]["students"] != null) {
          setState(() {
            students = List<Map<String, dynamic>>.from(data[0]["students"]);
            isLoading = false;
          });
        } else {
          setState(() {
            hasError = true;
            errorMessage = "No student data available.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          hasError = true;
          errorMessage = "Failed to fetch attendance. Try again later.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = "Error fetching attendance: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  Future<void> submitAttendance() async {
  try {
    final token = await getToken();
    if (token == null) {
      showError("No token found. Please log in.");
      return;
    }

    if (selectedClass == null || selectedSubject == null) {
      showError("Please select class and subject before submitting.");
      return;
    }

    final formattedDate = "${selectedDate.toLocal()}".split(' ')[0];

    final url = Uri.parse("https://s-m-s-keyw.onrender.com/attendance/update?masterAttendance=$masterAttendance");

    final payload = {
      "date": formattedDate,
      "className": selectedClass,
      "subject": selectedSubject,
      "studentList": students.map((student) => {
            "stdId": student["stdId"],
            "name": student["name"],
            "attendance": student["attendance"],
            "remark": student["remark"] ?? "",
          }).toList(),
      "masterAttendance": masterAttendance,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      showSuccess("Attendance updated successfully");
    } else {
      showError("Failed to update attendance. Try again.");
    }
  } catch (e) {
    showError("Error updating attendance: ${e.toString()}");
  }
}


  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Update Attendance")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Class Dropdown
            DropdownButton<String>(
              value: selectedClass,
              hint: Text("Select Class"),
              onChanged: (newValue) {
                setState(() {
                  selectedClass = newValue;
                  selectedSubject = null; // Reset subject selection
                });
              },
              items: classData.map((classItem) {
                return DropdownMenuItem<String>(
                  value: classItem["className"],
                  child: Text(classItem["className"]),
                );
              }).toList(),
            ),
            SizedBox(height: 10),

            // Subject Dropdown
            DropdownButton<String>(
              value: selectedSubject,
              hint: Text("Select Subject"),
              onChanged: (newValue) {
                setState(() {
                  selectedSubject = newValue;
                });
              },
              items: selectedClass == null
                  ? []
                  : classData
                      .firstWhere((classItem) => classItem["className"] == selectedClass)["subject"]
                      .map<DropdownMenuItem<String>>((subject) {
                      return DropdownMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      );
                    }).toList(),
            ),
            SizedBox(height: 10),

            // Date Picker
            ElevatedButton(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null && pickedDate != selectedDate) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },
              child: Text("Select Date: ${selectedDate.toLocal()}".split(' ')[0]),
            ),
            SizedBox(height: 10),

            // Master Attendance Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Master Attendance"),
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
            SizedBox(height: 20),

            // Fetch Attendance Button
            ElevatedButton(
              onPressed: fetchAttendance,
              child: Text("Fetch Attendance"),
            ),

            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : hasError
                      ? Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)))
                      : students.isEmpty
                          ? Center(child: Text("No attendance data available"))
                          : ListView.builder(
                              itemCount: students.length,
                              itemBuilder: (context, index) {
                                return Card(
                                  child: ListTile(
                                    title: Text(students[index]['name']),
                                    subtitle: Text("Attendance: ${students[index]['attendance']}"),
                                  ),
                                );
                              },
                            ),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: submitAttendance,
              child: Text("Submit Attendance"),
            ),
          ],
        ),
      ),
    );
  }
}
