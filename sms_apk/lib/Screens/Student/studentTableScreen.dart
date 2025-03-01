import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/widgets/header.dart';
import '../../auth_screen/login.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_popup.dart';

class StudentTableScreen extends StatefulWidget {
  const StudentTableScreen({super.key});

  @override
  _StudentTableScreenState createState() => _StudentTableScreenState();
}

class _StudentTableScreenState extends State<StudentTableScreen> {
  List<dynamic> students = [];
  bool isLoading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    fetchTokenAndStudents();
  }

  Future<void> fetchTokenAndStudents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('authToken');
    if (token != null) {
      fetchStudents();
    } else {
      showPopup(context, 'Token not found. Please log in again.', Colors.red);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  Future<void> fetchStudents() async {
    try {
      final response = await http.get(
        Uri.parse('https://s-m-s-keyw.onrender.com/student/findAllStudent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          students = json.decode(response.body);
        });
      } else {
        showPopup(context, 'Failed to load students', Colors.red);
      }
    } catch (e) {
      showPopup(context, 'Error: $e', Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      final response = await http.post(
        Uri.parse('https://s-m-s-keyw.onrender.com/student/delete?id=$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          students.removeWhere((student) => student['id'] == id);
        });
        showPopup(context, 'Student deleted successfully', Colors.green);
      } else {
        showPopup(context, 'Failed to delete student', Colors.red);
      }
    } catch (e) {
      showPopup(context, 'Error: $e', Colors.red);
    }
  }

  // Future<void> editStudent(Map<String, dynamic> student) async {
  //   if (token == null) {
  //     showPopup(context, 'Authentication token is missing. Please log in again.', Colors.red);
  //     return;
  //   }

  //   try {
  //     final response = await http.post(
  //       Uri.parse('https://s-m-s-keyw.onrender.com/student/update'),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer $token',
  //       },
  //       body: json.encode(student),
  //     );

  //     if (response.statusCode == 200) {
  //       showPopup(context, 'Student updated successfully', Colors.green);
  //       fetchStudents(); // Refresh data
  //     } else {
  //       showPopup(context, 'Failed to update student: ${response.statusCode}', Colors.red);
  //     }
  //   } catch (e) {
  //     showPopup(context, 'Error: $e', Colors.red);
  //   }
  // }

//   void showEditDialog(Map<String, dynamic> student) {
//     TextEditingController nameController = TextEditingController(text: student['name']);
//     TextEditingController cityController = TextEditingController(text: student['city']);
//     TextEditingController contactController = TextEditingController(text: student['contact']);
//     TextEditingController clsController = TextEditingController(text: student['cls']);

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           backgroundColor: AppColors.primary,
//           title: Text('Edit Student', style: TextStyle(color: Colors.white)),
//           content: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   TextField(
//                     controller: nameController,
//                     decoration: InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white)),
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   SizedBox(height: 10),
//                   TextField(
//                     controller: cityController,
//                     decoration: InputDecoration(labelText: 'City', labelStyle: TextStyle(color: Colors.white)),
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   SizedBox(height: 10),
//                   TextField(
//                     controller: contactController,
//                     decoration: InputDecoration(labelText: 'Contact', labelStyle: TextStyle(color: Colors.white)),
//                     style: TextStyle(color: Colors.white),
//                   ),
//                   SizedBox(height: 10),
//                   TextField(
//                     controller: clsController,
//                     decoration: InputDecoration(labelText: 'Class', labelStyle: TextStyle(color: Colors.white)),
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('Cancel', style: TextStyle(color: Colors.white)),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 student['name'] = nameController.text;
//                 student['city'] = cityController.text;
//                 student['contact'] = contactController.text;
//                 student['cls'] = clsController.text;
//                 editStudent(student);
//               },
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//               child: Text('Save', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         );
//       },
//     );
//   }
  Future<void> confirmDeleteStudent(String id) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Delete Student"),
        content: Text("Are you sure you want to delete this student?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: Text("Cancel", style: TextStyle(color: AppColors.primary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              deleteStudent(id); // Call the delete function
            },
            child: Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: Header(text: "Student Table"),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? Center(child: Text('No data available'))
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      color: Colors.white,
                      shadowColor: AppColors.primary,
                      elevation: 4,
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(student['name'] ?? 'N/A', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('City: ${student['city'] ?? 'N/A'}'),
                            Text('Contact: ${student['contact'] ?? 'N/A'}'),
                            Text('Class: ${student['cls'] ?? 'N/A'}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // IconButton(
                            //   icon: Icon(Icons.edit, color: Colors.blue),
                            //   onPressed: () => showEditDialog(student),
                            // ),
                            IconButton(
                             icon: Icon(Icons.delete, color: AppColors.primary),
                             onPressed: () => confirmDeleteStudent(student['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}