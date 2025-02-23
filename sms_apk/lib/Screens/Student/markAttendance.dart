import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sms_apk/utils/app_colors.dart';
import 'package:sms_apk/widgets/user_icon.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  _MarkAttendanceScreenState createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  List<dynamic> classData = [];
  String? selectedClass;
  List<dynamic> subjects = [];
  String? selectedSubject;
  List<Map<String, dynamic>> students = [];
  bool masterAttendance = true;
  String? globalAttendance;
  String? userName;

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
        final Map<String, dynamic> data = jsonDecode(response.body);
        List<dynamic> fetchedClasses = data['classData'] ?? [];

        setState(() {
          classData = fetchedClasses;
        });
      } else {
        showSnackbar("Failed to load classes");
      }
    } catch (e) {
      showSnackbar("Error: $e");
    }
  }

  void onClassChange(String? className) {
    if (className == null) return;

    var selectedClassData = classData.firstWhere(
      (cls) => cls['className'] == className,
      orElse: () => null, // Returns null if no match
    );

    setState(() {
      selectedClass = className;
      subjects = selectedClassData != null
          ? List<String>.from(selectedClassData['subject'] ?? [])
          : [];
    });
  }

  void applyAttendanceToAll(String? value) {
    if (value == null) return;
    setState(() {
      globalAttendance = value;
      students = students.map((student) {
        return {
          ...student,
          'attendance': value,
        };
      }).toList();
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
        Uri.parse(
            'https://s-m-s-keyw.onrender.com/student/findAllStudent?cls=$selectedClass&masterAttendance=$masterAttendance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<Map<String, dynamic>> fetchedStudents = data.map((student) {
          return {
            'stdId': student['id'],
            'name': student['name'],
            'attendance': globalAttendance ?? 'Present',
            'remark': '',
          };
        }).toList();

        setState(() {
          students = fetchedStudents;
        });
      } else {
        showSnackbar("Failed to fetch students");
      }
    } catch (e) {
      showSnackbar("Error: $e");
    }
  }

  Future<void> submitAttendance() async {
    if (selectedClass == null) {
      showSnackbar("Please select a class first.");
      return;
    }
    if (!masterAttendance && selectedSubject == null) {
      showSnackbar("Please select a subject.");
      return;
    }
    if (students.isEmpty) {
      showSnackbar("No students to submit attendance.");
      return;
    }

    try {
      final token = await getToken();
      if (token == null) {
        showSnackbar("No token found. Please log in.");
        return;
      }

      final response = await http.post(
        Uri.parse(
            'https://s-m-s-keyw.onrender.com/attendance/save?masterAttendance=$masterAttendance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "className": selectedClass,
          "subject": masterAttendance ? "" : selectedSubject,
          "studentList": students,
          "masterAttendance": masterAttendance,
        }),
      );

      if (response.statusCode == 200) {
        showSnackbar("Attendance submitted successfully!");
      } else {
        final errorMessage =
            jsonDecode(response.body)['message'] ?? "Unknown error";
        showSnackbar("Failed to submit attendance: $errorMessage");
      }
    } catch (e) {
      showSnackbar("Error: $e");
    }
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mark Attendance",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: UserIconWidget(userName: userName ?? "Guest"),
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  masterAttendance
                      ? "Master Attendance"
                      : "Subject-wise Attendance",
                  style: TextStyle(fontSize: 18),
                ),
                Switch(
                  value: masterAttendance,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      masterAttendance = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            // Class Selection Container
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade300, blurRadius: 6)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select Class",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButton<String>(
                      value: selectedClass?.isNotEmpty == true
                          ? selectedClass
                          : null, // ✅ Safe check
                      isExpanded: true,
                      items:
                          classData.map<DropdownMenuItem<String>>((classItem) {
                        return DropdownMenuItem<String>(
                          value: classItem['className'],
                          child: Text(classItem['className']),
                        );
                      }).toList(),
                      onChanged: onClassChange,
                      hint: Text(
                          "Select a class"), // ✅ Shows hint when nothing is selected
                      dropdownColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            if (!masterAttendance)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade300, blurRadius: 6)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Select Subject",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: DropdownButton<String>(
                        value: selectedSubject,
                        isExpanded: true,
                        items:
                            subjects.map<DropdownMenuItem<String>>((subject) {
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
                        hint: Text("Select a subject"),
                        dropdownColor: Colors.white,
                        disabledHint: Text("Select a class first"),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: fetchStudents,
              child: Text("Fetch Students"),
            ),
            SizedBox(
              height: 20,
            ),
            DropdownButton<String>(
              hint: Text("Apply Attendance to All"),
              isExpanded: true,
              items: ["Present", "Absent", "Half Day", "Late", "Leave"]
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: applyAttendanceToAll,
            ),
            SizedBox(
              height: 20,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  var student = students[index];
                  return ListTile(
                    title: Text(student['name']),
                    subtitle: DropdownButton<String>(
                      value: student['attendance'],
                      items: ["Present", "Absent", "Half Day", "Late", "Leave"]
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          student['attendance'] = value!;
                        });
                      },
                    ),
                    trailing: SizedBox(
                      width: 150,
                      child: TextField(
                        decoration: InputDecoration(hintText: "Enter remarks"),
                        onChanged: (value) {
                          student['remark'] = value;
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
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
