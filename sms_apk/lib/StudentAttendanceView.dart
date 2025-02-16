import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StudentAttendanceScreen extends StatefulWidget {
  @override
  _StudentAttendanceScreenState createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  List studentList = [];
  Map<String, String> attendance = {};
  TextEditingController searchController = TextEditingController();
  List filteredList = [];
  String? token;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchToken();
  }

  /// Fetch auth token and student list
  Future<void> fetchToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('authToken');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token not found. Please log in again.')),
      );
    } else {
      fetchStudentList();
    }
  }

  /// Fetch student list from API
  Future<void> fetchStudentList() async {
    if (token == null) return;

    final response = await http.get(
      Uri.parse('https://s-m-s-keyw.onrender.com/student/findAllStudents'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        studentList = json.decode(response.body);
        filteredList = studentList;
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch student list')),
      );
    }
  }

  /// Filter student list based on search input
  void filterSearchResults(String query) {
    List tempList = studentList.where((student) =>
      student['stud_Name'].toLowerCase().contains(query.toLowerCase())
    ).toList();

    setState(() {
      filteredList = tempList;
    });
  }

  /// Send attendance data to the API with correct JSON format
  Future<void> saveAttendance() async {
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Token is missing!')),
      );
      return;
    }

    List<Map<String, dynamic>> studList = studentList.map((student) {
      return {
        "studId": student['stud_id'].toString(),
        "name": student['stud_Name'].toString(),
        "attendance": attendance[student['stud_id']] ?? "Absent"
      };
    }).toList();

    final Map<String, dynamic> requestBody = {
      "studList": studList
    };

    final response = await http.post(
      Uri.parse('https://s-m-s-keyw.onrender.com/student/attendanceSave'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update attendance')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Attendance Update'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Student',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: filterSearchResults,
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        var student = filteredList[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(student['stud_Name']),
                            subtitle: Text(student['stud_email']),
                            trailing: DropdownButton<String>(
                              value: attendance[student['stud_id']],
                              hint: Text('Select'),
                              items: ['Present', 'Absent', 'Leave']
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  attendance[student['stud_id']] = value!;
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: saveAttendance,
                    child: Text('Save Changes'),
                  ),
                ],
              ),
            ),
    );
  }
}
