import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'subject_screen.dart'; // Import the SaveSubjectsToClasses screen

// Keep your existing ClassData class
class ClassData {
  final String className;
  final dynamic subject;

  ClassData({required this.className, required this.subject});

  factory ClassData.fromJson(Map<String, dynamic> json) {
    return ClassData(
      className: json['className'] ?? '',
      subject: json['subject'],
    );
  }

  List<String> get subjectList {
    if (subject is String) {
      return subject.split(', ');
    } else if (subject is List) {
      return List<String>.from(subject);
    }
    return [];
  }
  
  // Convert ClassData to a Map
  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'subject': subject,
    };
  }
}

class ClassSubjectShow extends StatefulWidget {
  const ClassSubjectShow({Key? key}) : super(key: key);

  @override
  State<ClassSubjectShow> createState() => _ClassSubjectShowState();
}

class _ClassSubjectShowState extends State<ClassSubjectShow> {
  List<ClassData> data = [];
  bool loading = true;
  String? error;
  bool showForm = false;
  ClassData? editableRow;

  static const String baseUrl = 'https://s-m-s-keyw.onrender.com';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // Get auth token from shared preferences
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // API Calls with authentication
  Future<void> fetchData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/class/data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add auth token
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> classDataList = jsonData['classData'] ?? [];
        
        setState(() {
          data = classDataList.map((item) => ClassData.fromJson(item)).toList();
          loading = false;
        });
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to load class data: ${response.statusCode}');
      }
    } catch (err) {
      setState(() {
        error = err.toString();
        loading = false;
      });
      _showSnackBar('Error: ${err.toString()}', isError: true);
    }
  }

  Future<void> deleteClass(String className) async {
    try {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/class/delete?className=${Uri.encodeComponent(className)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add auth token
        },
      );

      if (response.statusCode == 200) {
        await fetchData();
        _showSnackBar('Class $className has been deleted successfully!');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to delete class');
      }
    } catch (error) {
      _showSnackBar('Failed to delete the row: ${error.toString()}', isError: true);
    }
  }

  void handleEdit(ClassData row) {
    setState(() {
      showForm = true;
      editableRow = row;
    });
  }

  Future<void> handleSave() async {
    await fetchData();
    setState(() {
      showForm = false;
      editableRow = null;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Class & Subjects'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: showForm
          ? SaveSubjectsToClasses(
              onClose: () {
                setState(() {
                  showForm = false;
                  editableRow = null;
                });
              },
              onSave: handleSave,
              // Convert ClassData to Map
              editableRowData: editableRow?.toMap(),
              getAuthToken: getAuthToken,
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Class & Subjects',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() => showForm = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add Subject'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (error != null)
                    Center(
                      child: Text(error!, style: const TextStyle(color: Colors.red)),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Class Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Subjects', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Edit', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Delete', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: data.map((item) {
                            return DataRow(cells: [
                              DataCell(Text(item.className)),
                              DataCell(Text(item.subjectList.join(', '))),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => handleEdit(item),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deleteClass(item.className),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
