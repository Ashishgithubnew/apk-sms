import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<dynamic> classData = [];
  String? selectedClass;
  List<dynamic> subjects = [];
  String? selectedSubject;
  List<Map<String, dynamic>> students = [];
  bool isMasterAttendance = false; // Switch state

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
        showSnackbar("No token found. Please log in.");
        return;
      }

      final response = await http.get(
        Uri.parse('https://s-m-s-keyw.onrender.com/class/data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          classData = data['classData'];
        });
      } else {
        showSnackbar("Failed to load classes");
      }
    } catch (e) {
      showSnackbar("Error: $e");
    }
  }

  void onClassChange(String? className) {
    setState(() {
      selectedClass = className;
      subjects = classData.firstWhere(
        (cls) => cls['className'] == className,
        orElse: () => {'subject': []},
      )['subject'];
    });
  }

  Future<void> fetchStudents() async {
    if (selectedClass == null) {
      showSnackbar("Please select a class first.");
      return;
    }

    try {
      final token = await getToken();
      if (token == null) {
        showSnackbar("No token found. Please log in.");
        return;
      }

      final response = await http.get(
        Uri.parse('https://s-m-s-keyw.onrender.com/student/findAllStudent?cls=$selectedClass&masterAttendance=$isMasterAttendance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          students = data.map((student) {
            return {
              'stdId': student['id'],
              'name': student['name'],
              'attendance': 'Present',
              'remark': '',
            };
          }).toList();
        });
      } else {
        showSnackbar("Failed to fetch students");
      }
    } catch (e) {
      showSnackbar("Error: $e");
    }
  }

  Future<void> submitAttendance() async {
    if (selectedClass == null || selectedSubject == null || students.isEmpty) {
      showSnackbar("Please complete all fields before submitting.");
      return;
    }

    try {
      final token = await getToken();
      if (token == null) {
        showSnackbar("No token found. Please log in.");
        return;
      }

      final Map<String, dynamic> payload = {
        "className": selectedClass,
        "subject": selectedSubject,
        "masterAttendance": isMasterAttendance,
        "studentList": students.map((student) {
          return {
            "stdId": student['stdId'],
            "name": student['name'],
            "attendance": student['attendance'],
            "remark": student['remark'],
          };
        }).toList(),
      };

      final response = await http.post(
        Uri.parse('https://s-m-s-keyw.onrender.com/attendance/save?masterAttendance=$isMasterAttendance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        showSnackbar("Attendance submitted successfully!");
      } else {
        showSnackbar("Failed to submit attendance");
      }
    } catch (e) {
      showSnackbar("Error: $e");
    }
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attendance')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Switch for Master Attendance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Master Attendance",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: isMasterAttendance,
                  onChanged: (value) {
                    setState(() {
                      isMasterAttendance = value;
                     // fetchStudents(); // Fetch students on toggle
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedClass,
              hint: Text("Select Class"),
              isExpanded: true,
              items: classData.map<DropdownMenuItem<String>>((classItem) {
                return DropdownMenuItem<String>(
                  value: classItem['className'],
                  child: Text(classItem['className']),
                );
              }).toList(),
              onChanged: onClassChange,
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedSubject,
              hint: Text("Select Subject"),
              isExpanded: true,
              items: subjects.map<DropdownMenuItem<String>>((subject) {
                return DropdownMenuItem<String>(
                  value: subject,
                  child: Text(subject),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSubject = value;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchStudents,
              child: Text("Fetch Students"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  var student = students[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['name'],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text("Present"),
                                  value: "Present",
                                  groupValue: student['attendance'],
                                  onChanged: (value) {
                                    setState(() {
                                      student['attendance'] = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text("Absent"),
                                  value: "Absent",
                                  groupValue: student['attendance'],
                                  onChanged: (value) {
                                    setState(() {
                                      student['attendance'] = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                           Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text("Half Day"),
                                  value: "Half Day",
                                  groupValue: student['attendance'],
                                  onChanged: (value) {
                                    setState(() {
                                      student['attendance'] = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: Text("Late"),
                                  value: "Late",
                                  groupValue: student['attendance'],
                                  onChanged: (value) {
                                    setState(() {
                                      student['attendance'] = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          TextField(
                            decoration: InputDecoration(
                              labelText: "Enter remarks",
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              student['remark'] = value;
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
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