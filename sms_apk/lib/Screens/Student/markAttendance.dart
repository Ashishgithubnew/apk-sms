import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sms_apk/utils/app_colors.dart';
import 'package:sms_apk/widgets/custom_popup.dart';
import 'package:sms_apk/widgets/header.dart';

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
  bool studentsFetched = false;

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
        showPopup(context, "No token found. Please log in.", AppColors.primary);
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
        showPopup(context, "Failed to load classes", AppColors.primary);
      }
    } catch (e) {
      showPopup(context, "Error: $e", AppColors.primary);
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
      showPopup(context, "Please select a class first.", AppColors.primary);
      return;
    }

    try {
      final token = await getToken();
      if (token == null) {
        showPopup(context, "No token found. Please log in.", AppColors.primary);
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
            'controller': TextEditingController(),
          };
        }).toList();

        setState(() {
          students = fetchedStudents;
          studentsFetched = true;
        });
      } else {
        showPopup(context, "Failed to fetch students", AppColors.primary);
      }
    } catch (e) {
      showPopup(context, "Error: $e", AppColors.primary);
    }
  }

  Future<void> submitAttendance() async {
    if (selectedClass == null) {
      showPopup(context, "Please select a class first.", AppColors.primary);
      return;
    }
    if (!masterAttendance && selectedSubject == null) {
      showPopup(context, "Please select a subject.", AppColors.primary);
      return;
    }
    if (students.isEmpty) {
      showPopup(
          context, "No students to submit attendance.", AppColors.primary);
      return;
    }

    try {
      final token = await getToken();
      if (token == null) {
        showPopup(context, "No token found. Please log in.", AppColors.primary);
        return;
      }

      // ✅ Extracting remark values and creating clean student list
      List<Map<String, dynamic>> cleanedStudents = students.map((student) {
        return {
          'stdId': student['stdId'],
          'name': student['name'],
          'attendance': student['attendance'],
          'remark': student['controller'].text, // Extract text from controller
        };
      }).toList();

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
          "studentList": cleanedStudents,
          "masterAttendance": masterAttendance,
        }),
      );

      if (response.statusCode == 200) {
        showPopup(
            context, "Attendance submitted successfully!", AppColors.primary);
      } else {
        final errorMessage =
            jsonDecode(response.body)['message'] ?? "Unknown error";
        showPopup(context, "Failed to submit attendance: $errorMessage",
            AppColors.primary);
      }
    } catch (e) {
      showPopup(context, "Error: $e", AppColors.primary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: Header(text: 'Mark Attendance'),
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

            if (!masterAttendance)
              SizedBox(
                height: 10,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, // Button color
                foregroundColor: Colors.white, // Text color
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12), // Optional: Adjust padding
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8), // Optional: Rounded corners
                ),
              ),
              child: const Text("Fetch Students"),
            ),
            SizedBox(
              height: 20,
            ),
            if (studentsFetched)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade300, blurRadius: 6)
                  ],
                ),
                child: DropdownButton<String>(
                  hint: Text("Apply Attendance to All",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  isExpanded: true,
                  value: globalAttendance,
                  items: ["Present", "Absent", "Half Day", "Late", "Leave"]
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: applyAttendanceToAll,
                  dropdownColor: Colors.white,
                ),
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
                          students[index]['attendance'] = value!;
                        });
                      },
                    ),
                    trailing: SizedBox(
                      width: 200,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: TextField(
                          cursorColor:
                              AppColors.primary, // Cursor (caret) color
                          controller: students[index]
                              ['controller'], // ✅ Assign controller
                          decoration: InputDecoration(
                            hintText: "Enter remarks",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: AppColors
                                      .primary), // Default border color
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2), // Focused border color
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (value) {
                            students[index]['remark'] = value;
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity, // Full width
              child: ElevatedButton(
                onPressed: submitAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Primary color
                  foregroundColor: Colors.white, // White text color
                  padding: const EdgeInsets.symmetric(
                      vertical: 14), // Comfortable padding
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12), // Smooth rounded corners
                  ),
                  elevation: 4, // Slight shadow for better visibility
                ),
                child: const Text(
                  "Submit Attendance",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
