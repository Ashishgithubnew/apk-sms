import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<dynamic> classData = [];
  String? selectedClass;
  List<String> subjects = [];
  String? selectedSubject;
  List<dynamic> students = [];
  Map<String, String> attendance = {};

  @override
  void initState() {
    super.initState();
    fetchClassData();
  }

  // Fetch class and subject data
  Future<void> fetchClassData() async {
    try {
      final response = await http.get(
        Uri.parse('https://s-m-s-keyw.onrender.com/class/data'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          classData = data['classData'];
        });
      }
    } catch (e) {
      print('Error fetching class data: $e');
    }
  }

  // Fetch student data for the selected class
  Future<void> fetchStudents() async {
    if (selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a class.')),
      );
      return;
    }
    try {
      final response = await http.get(
        Uri.parse(
            'https://s-m-s-keyw.onrender.com/student/findAllStudent?cls=$selectedClass&masterAttendance=false'),
      );
      if (response.statusCode == 200) {
        setState(() {
          students = json.decode(response.body);
          attendance = {
            for (var student in students) student['id']: 'Present',
          };
        });
      }
    } catch (e) {
      print('Error fetching students: $e');
    }
  }

  // Save attendance
  Future<void> saveAttendance() async {
    if (selectedClass == null || selectedSubject == null || students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }
    final attendanceData = {
      "className": selectedClass,
      "subject": selectedSubject,
      "studentList": students.map((student) {
        return {
          "stdId": student['id'],
          "name": student['name'],
          "attendance": attendance[student['id']],
          "remark": "",
        };
      }).toList(),
      "masterAttendance": false,
    };

    try {
      final response = await http.post(
        Uri.parse('https://s-m-s-keyw.onrender.com/attendance/save?masterAttendance=false'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(attendanceData),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Attendance saved successfully.')),
        );
      }
    } catch (e) {
      print('Error saving attendance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Class Dropdown
            DropdownButton<String>(
              hint: Text('Select Class'),
              value: selectedClass,
              isExpanded: true,
              items: classData.map((cls) {
                return DropdownMenuItem(
                  value: cls['className'],
                  child: Text(cls['className']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedClass = value;
                  selectedSubject = null;
                  subjects = classData
                      .firstWhere((cls) => cls['className'] == value)['subject']
                      .cast<String>();
                });
              },
            ),
            SizedBox(height: 16),

            // Subject Dropdown
            DropdownButton<String>(
              hint: Text('Select Subject'),
              value: selectedSubject,
              isExpanded: true,
              items: subjects.map((subject) {
                return DropdownMenuItem(
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
            SizedBox(height: 16),

            // Fetch Students Button
            ElevatedButton(
              onPressed: fetchStudents,
              child: Text('Fetch Students'),
            ),
            SizedBox(height: 16),

            // Students List
            Expanded(
              child: students.isNotEmpty
                  ? ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return ListTile(
                          title: Text(student['name']),
                          subtitle: Text('ID: ${student['id']}'),
                          trailing: DropdownButton<String>(
                            value: attendance[student['id']],
                            items: ['Present', 'Absent', 'Half Day', 'Late']
                                .map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                attendance[student['id']] = value!;
                              });
                            },
                          ),
                        );
                      },
                    )
                  : Center(child: Text('No students found.')),
            ),

            // Submit Button
            ElevatedButton(
              onPressed: saveAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text('Submit Attendance'),
            ),
          ],
        ),
      ),
    );
  }
}
