import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_colors.dart';
import '../widgets/class_subject_selection.dart';
import '../widgets/user_icon.dart'; // Import UserIconWidget
import 'package:shared_preferences/shared_preferences.dart';

class MarkAttendanceScreen extends StatefulWidget {
  @override
  _MarkAttendanceScreenState createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  List<Map<String, dynamic>> students = [];
  List<int> selectedStudentIds = [];
  String? selectedClass;
  String? selectedSubject;
  bool isLoading = false;

  Future<void> fetchStudents(String selectedClass) async {
    setState(() {
      isLoading = true;
      students = [];
      selectedStudentIds = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        showPopup("Token not found. Please log in again.");
        return;
      }

      final response = await http.get(
        Uri.parse('https://your-api.com/students?class=$selectedClass'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          students = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        showPopup("Failed to fetch students. Please try again.");
      }
    } catch (e) {
      showPopup("Error fetching students: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  void markStudent(int studentId, bool isPresent) {
    setState(() {
      if (isPresent) {
        if (!selectedStudentIds.contains(studentId)) {
          selectedStudentIds.add(studentId);
        }
      } else {
        selectedStudentIds.remove(studentId);
      }
    });
  }

  Future<void> submitAttendance() async {
    if (selectedStudentIds.isEmpty) {
      showPopup("Please mark attendance before submitting.");
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        showPopup("Token not found. Please log in again.");
        return;
      }

      final response = await http.post(
        Uri.parse('https://your-api.com/mark-attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          "class": selectedClass,
          "subject": selectedSubject,
          "present_students": selectedStudentIds
        }),
      );

      if (response.statusCode == 200) {
        showPopup("Attendance submitted successfully!");
        setState(() {
          selectedStudentIds = [];
        });
      } else {
        showPopup("Failed to submit attendance. Please try again.");
      }
    } catch (e) {
      showPopup("Error submitting attendance: $e");
    }
  }

  void showPopup(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            message,
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mark Attendance", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          UserIconWidget(userName: "Aditya Sharma",), // Add User Icon in the AppBar
          SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class & Subject Selection
            ClassSubjectSelection(
              onSelectionChanged: (classSelected, subjectSelected) {
                setState(() {
                  selectedClass = classSelected;
                  selectedSubject = subjectSelected;
                });
                fetchStudents(classSelected);
              },
            ),
            SizedBox(height: 20),

            // Loading Indicator
            if (isLoading)
              Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (students.isEmpty)
              Center(
                child: Text(
                  "No students found for this class.",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
            else
              // Student List
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      color: AppColors.primary,
                      margin: EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        title: Text(
                          student['name'],
                          style: TextStyle(color: Colors.white),
                        ),
                        trailing: Checkbox(
                          value: selectedStudentIds.contains(student['id']),
                          onChanged: (value) {
                            markStudent(student['id'], value ?? false);
                          },
                          checkColor: AppColors.primary,
                          activeColor: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Submit Attendance Button
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: submitAttendance,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Center(
                child: Text("Submit Attendance", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class MarkAttendanceScreen extends StatefulWidget {
//   const MarkAttendanceScreen({super.key});

//   @override
//   _MarkAttendanceScreenState createState() => _MarkAttendanceScreenState();
// }

// class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
//   List<dynamic> classData = [];
//   String? selectedClass;
//   List<dynamic> subjects = [];
//   String? selectedSubject;
//   List<Map<String, dynamic>> students = [];
//   bool masterAttendance = false;
//   String? globalAttendance;

//   @override
//   void initState() {
//     super.initState();
//     fetchClasses();
//   }

//   Future<String?> getToken() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString('authToken');
//   }

//   Future<void> fetchClasses() async {
//     try {
//       final token = await getToken();
//       if (token == null) {
//         showSnackbar("No token found. Please log in.");
//         return;
//       }
      
//       final response = await http.get(
//         Uri.parse('https://s-m-s-keyw.onrender.com/class/data'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
      
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> data = jsonDecode(response.body);
//         setState(() {
//           classData = data['classData'];
//         });
//       } else {
//         showSnackbar("Failed to load classes");
//       }
//     } catch (e) {
//       showSnackbar("Error: $e");
//     }
//   }

//   void onClassChange(String? className) {
//     setState(() {
//       selectedClass = className;
//       subjects = classData.firstWhere(
//         (cls) => cls['className'] == className,
//         orElse: () => {'subject': []},
//       )['subject'];
//     });
//   }

//   void applyAttendanceToAll(String? value) {
//     if (value == null) return;
//     setState(() {
//       globalAttendance = value;
//       students = students.map((student) {
//         return {
//           ...student,
//           'attendance': value,
//         };
//       }).toList();
//     });
//   }

//   Future<void> fetchStudents() async {
//     if (selectedClass == null) {
//       showSnackbar("Please select a class first.");
//       return;
//     }
    
//     try {
//       final token = await getToken();
//       if (token == null) {
//         showSnackbar("No token found. Please log in.");
//         return;
//       }

//       final response = await http.get(
//         Uri.parse('https://s-m-s-keyw.onrender.com/student/findAllStudent?cls=$selectedClass&masterAttendance=$masterAttendance'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data = jsonDecode(response.body);
//         setState(() {
//           students = data.map((student) {
//             return {
//               'stdId': student['id'],
//               'name': student['name'],
//               'attendance': globalAttendance ?? 'Present',
//               'remark': '',
//             };
//           }).toList();
//         });
//       } else {
//         showSnackbar("Failed to fetch students");
//       }
//     } catch (e) {
//       showSnackbar("Error: $e");
//     }
//   }

//   Future<void> submitAttendance() async {
//     if (selectedClass == null) {
//       showSnackbar("Please select a class first.");
//       return;
//     }
//     if (!masterAttendance && selectedSubject == null) {
//       showSnackbar("Please select a subject.");
//       return;
//     }
//     if (students.isEmpty) {
//       showSnackbar("No students to submit attendance.");
//       return;
//     }

//     try {
//       final token = await getToken();
//       if (token == null) {
//         showSnackbar("No token found. Please log in.");
//         return;
//       }

//       final response = await http.post(
//         Uri.parse('https://s-m-s-keyw.onrender.com/attendance/save?masterAttendance=$masterAttendance'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({
//           "className": selectedClass,
//           "subject": masterAttendance ? "" : selectedSubject,
//           "studentList": students,
//           "masterAttendance": masterAttendance,
//         }),
//       );

//       if (response.statusCode == 200) {
//         showSnackbar("Attendance submitted successfully!");
//       } else {
//         showSnackbar("Failed to submit attendance.");
//       }
//     } catch (e) {
//       showSnackbar("Error: $e");
//     }
//   }

//   void showSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Student Attendance')),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             SwitchListTile(
//               title: Text("Subject-Wise Attendance"),
//               value: masterAttendance,
//               onChanged: (value) {
//                 setState(() {
//                   masterAttendance = value;
//                 });
//               },
//             ),
//             DropdownButton<String>(
//               value: selectedClass,
//               hint: Text("Select Class"),
//               isExpanded: true,
//               items: classData.map<DropdownMenuItem<String>>((classItem) {
//                 return DropdownMenuItem<String>(
//                   value: classItem['className'],
//                   child: Text(classItem['className']),
//                 );
//               }).toList(),
//               onChanged: onClassChange,
//             ),
//             if (!masterAttendance)
//               DropdownButton<String>(
//                 value: selectedSubject,
//                 hint: Text("Select Subject"),
//                 isExpanded: true,
//                 items: subjects.map<DropdownMenuItem<String>>((subject) {
//                   return DropdownMenuItem<String>(
//                     value: subject,
//                     child: Text(subject),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     selectedSubject = value;
//                   });
//                 },
//               ),
//             ElevatedButton(
//               onPressed: fetchStudents,
//               child: Text("Fetch Students"),
//             ),
//             DropdownButton<String>(
//               hint: Text("Apply Attendance to All"),
//               isExpanded: true,
//               items: ["Present", "Absent", "Half Day", "Late", "Leave"].map((String value) {
//                 return DropdownMenuItem<String>(
//                   value: value,
//                   child: Text(value),
//                 );
//               }).toList(),
//               onChanged: applyAttendanceToAll,
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: students.length,
//                 itemBuilder: (context, index) {
//                   var student = students[index];
//                   return ListTile(
//                     title: Text(student['name']),
//                     subtitle: DropdownButton<String>(
//                       value: student['attendance'],
//                       items: ["Present", "Absent", "Half Day", "Late", "Leave"].map((String value) {
//                         return DropdownMenuItem<String>(
//                           value: value,
//                           child: Text(value),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           student['attendance'] = value!;
//                         });
//                       },
//                     ),
//                     trailing: SizedBox(
//                       width: 150,
//                       child: TextField(
//                         decoration: InputDecoration(hintText: "Enter remarks"),
//                         onChanged: (value) {
//                           student['remark'] = value;
//                         },
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//             ElevatedButton(
//               onPressed: submitAttendance,
//               child: Text("Submit Attendance"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
