import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/auth_screen/login.dart';

class FacultyTableScreen extends StatefulWidget {
  const FacultyTableScreen({super.key});

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
        MaterialPageRoute(builder: (context) => LoginScreen()),
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
        Uri.parse('https://s-m-s-keyw.onrender.com/faculty/delete?id=$facultyId'), 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
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

  void showEditForm(Map<String, dynamic> faculty) {
    final formKey = GlobalKey<FormState>();
    Map<String, dynamic> updatedFaculty = Map.from(faculty);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Faculty'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    initialValue: faculty['fact_Name'],
                    decoration: InputDecoration(labelText: 'Name'),
                    onChanged: (value) {
                      updatedFaculty['fact_Name'] = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    initialValue: faculty['fact_email'],
                    decoration: InputDecoration(labelText: 'Email'),
                    onChanged: (value) {
                      updatedFaculty['fact_email'] = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    initialValue: faculty['fact_contact'],
                    decoration: InputDecoration(labelText: 'Contact'),
                    onChanged: (value) {
                      updatedFaculty['fact_contact'] = value;
                    },
                  ),
                  TextFormField(
                    initialValue: faculty['fact_address'],
                    decoration: InputDecoration(labelText: 'Address'),
                    onChanged: (value) {
                      updatedFaculty['fact_address'] = value;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  editFaculty(updatedFaculty);
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> editFaculty(Map<String, dynamic> faculty) async {
    try {
      final response = await http.post(
        Uri.parse('https://s-m-s-keyw.onrender.com/faculty/Update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(faculty),
      );

      if (response.statusCode == 200) {
        setState(() {
          int index = facultyList.indexWhere((f) => f['fact_id'] == faculty['fact_id']);
          if (index != -1) {
            facultyList[index] = faculty;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Faculty updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update faculty: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
                    if (constraints.maxWidth < 600) {
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
                                      showEditForm(faculty);
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
                            DataColumn(label: Text('Edit')),
                            DataColumn(label: Text('Delete')),
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
                                      showEditForm(faculty);
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
