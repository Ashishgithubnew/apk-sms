import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class FacultyTableScreen extends StatefulWidget {
  @override
  _FacultyTableScreenState createState() => _FacultyTableScreenState();
}

class _FacultyTableScreenState extends State<FacultyTableScreen> {
  List<dynamic> facultyList = [];
  bool isLoading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    fetchTokenAndFaculty();
  }

  Future<void> fetchTokenAndFaculty() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('authToken');
    if (token != null) {
      fetchFaculty();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token not found. Please log in again.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()), // Add the login screen if not found
      );
    }
  }

  Future<void> fetchFaculty() async {
    try {
      final response = await http.get(
        Uri.parse('https://s-m-s-keyw.onrender.com/faculty/findAllFaculty'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          facultyList = json.decode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load faculty data: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteFaculty(String facultyId) async {
    try {
      final response = await http.post(
        Uri.parse('https://s-m-s-keyw.onrender.com/faculty/delete?id=$facultyId'), // Passing ID as a query parameter
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Remove the deleted faculty from the list
        setState(() {
          facultyList.removeWhere((faculty) => faculty['fact_id'] == facultyId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Faculty deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete faculty: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
 

  Future<void> editFaculty(String facultyId) async {
    // Handle the edit logic, like navigating to a form or showing a dialog to update the faculty details.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit button pressed for $facultyId')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Faculty Table'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : facultyList.isEmpty
              ? Center(child: Text('No data available'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Check screen width to adjust layout
                    if (constraints.maxWidth < 600) {
                      // Small screen (e.g., mobile)
                      return ListView.builder(
                        itemCount: facultyList.length,
                        itemBuilder: (context, index) {
                          final faculty = facultyList[index];
                          return Card(
                            margin: EdgeInsets.all(8.0),
                            child: ListTile(
                              title: Text(faculty['fact_Name'] ?? 'N/A'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('City: ${faculty['fact_city'] ?? 'N/A'}'),
                                  Text('Contact: ${faculty['fact_contact'] ?? 'N/A'}'),
                                  Text('Gender: ${faculty['fact_gender'] ?? 'N/A'}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () {
                                      editFaculty(faculty['fact_id']);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      deleteFaculty(faculty['fact_id']);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      // Large screen (e.g., tablet, desktop)
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Contact')),
                            DataColumn(label: Text('Gender')),
                            DataColumn(label: Text('City')),
                            DataColumn(label: Text('State')),
                            DataColumn(label: Text('Address')),
                            DataColumn(label: Text('Joining Date')),
                            DataColumn(label: Text('Leaving Date')),
                            DataColumn(label: Text('Edit')), // Add Edit column
                            DataColumn(label: Text('Delete')), // Add Delete column
                          ],
                          rows: facultyList.map((faculty) {
                            return DataRow(
                              cells: [
                                DataCell(Text(faculty['fact_id'] ?? 'N/A')),
                                DataCell(Text(faculty['fact_Name'] ?? 'N/A')),
                                DataCell(Text(faculty['fact_email'] ?? 'N/A')),
                                DataCell(Text(faculty['fact_contact'] ?? 'N/A')),
                                DataCell(Text(faculty['fact_gender'] ?? 'N/A')),
                                DataCell(Text(faculty['fact_city'] ?? 'N/A')),
                                DataCell(Text(faculty['fact_state'] ?? 'N/A')),
                                DataCell(Text(faculty['fact_address'] ?? 'N/A')),
                                DataCell(Text(faculty['fact_joiningDate'] ?? 'N/A')),
                                DataCell(Text(faculty['fact_leavingDate'] ?? 'N/A')),
                                DataCell(
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () {
                                      editFaculty(faculty['fact_id']);
                                    },
                                  ),
                                ),
                                DataCell(
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      deleteFaculty(faculty['fact_id']);
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    }
                  },
                ),
    );
  }
}
