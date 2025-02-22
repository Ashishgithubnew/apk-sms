import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FacultyAttendanceApp extends StatelessWidget {
  const FacultyAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FacultyAttendanceScreen(),
    );
  }
}

class FacultyAttendanceScreen extends StatefulWidget {
  const FacultyAttendanceScreen({super.key});

  @override
  _FacultyAttendanceScreenState createState() => _FacultyAttendanceScreenState();
}

class _FacultyAttendanceScreenState extends State<FacultyAttendanceScreen> {
  List facultyList = [];
  Map<String, String> attendance = {};
  TextEditingController searchController = TextEditingController();
  List filteredList = [];
  String? token;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTokenAndFacultyList();
  }

  /// Fetch auth token and faculty list
  Future<void> fetchTokenAndFacultyList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('authToken');
    
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token not found. Please log in again.')),
      );
      return;
    }

    await fetchFacultyList();
  }

  /// Fetch faculty list from API
  Future<void> fetchFacultyList() async {
    final response = await http.get(
      Uri.parse('https://s-m-s-keyw.onrender.com/faculty/findAllFaculty'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        facultyList = json.decode(response.body);
        filteredList = facultyList;
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch faculty list')),
      );
    }
  }

  /// Filter faculty list based on search input
  void filterSearchResults(String query) {
    List tempList = facultyList.where((faculty) =>
      faculty['fact_Name'].toLowerCase().contains(query.toLowerCase())
    ).toList();

    setState(() {
      filteredList = tempList;
    });
  }

  /// Send attendance data to the API with correct JSON format
  Future<void> saveAttendance() async {
    List<Map<String, dynamic>> factList = facultyList.map((faculty) {
      return {
        "factId": faculty['fact_id'].toString(),
        "name": faculty['fact_Name'].toString(),
        "attendance": attendance[faculty['fact_id']] ?? "Absent"
      };
    }).toList();

    final Map<String, dynamic> requestBody = {
      "factList": factList
    };

    final response = await http.post(
      Uri.parse('https://s-m-s-keyw.onrender.com/faculty/attendanceSave'),
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
        title: Text('Faculty Attendance Update'),
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
                      labelText: 'Search Faculty',
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
                        var faculty = filteredList[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(faculty['fact_Name']),
                            subtitle: Text(faculty['fact_email']),
                            trailing: DropdownButton<String>(
                              value: attendance[faculty['fact_id']],
                              hint: Text('Select'),
                              items: ['Present', 'Absent', 'Leave']
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  attendance[faculty['fact_id']] = value!;
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
