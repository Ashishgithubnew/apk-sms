import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

// Then use:

class Faculty {
  final String id;
  final String name;
  final String email;

  Faculty({required this.id, required this.name, required this.email});

  factory Faculty.fromJson(Map<String, dynamic> json) {
    return Faculty(
      id: json['fact_id'],
      name: json['fact_Name'],
      email: json['email'],
    );
  }
}

class Permissions {
  Map<String, bool> student;
  Map<String, bool> faculty;
  Map<String, bool> finance;
  Map<String, bool> notification;
  Map<String, bool> subject;

  Permissions({
    required this.student,
    required this.faculty,
    required this.finance,
    required this.notification,
    required this.subject,
  });

  factory Permissions.defaultPermissions() {
    return Permissions(
      student: {
        'studentAttendanceEdit': false,
        'studentAttendenceManagement': false,
        'studentFees': false,
        'studentAttendanceEditSave': false,
        'studentRegistrationController': false,
        'studentAttendanceShow': false,
        'studentFeesController': false,
        'studentFeesForm': false,
        'studentFeesDetails': false,
        'studentReportForm': false,
        'studentReport': false,
        'studentDetails': false,
        'bulkupload': false,
      },
      faculty: {
        'facultySalaryDetails': false,
        'facultySalaryController': false,
        'facultyAttendanceEditSave': false,
        'facultyAttendanceEdit': false,
        'facultyAttendanceShow': false,
        'facultyAttendanceSave': false,
        'facultyRegistrationForm': false,
        'facultyDetails': false,
      },
      finance: {
        'adminFees': false,
        'feesController': false,
        'permission': false,
      },
      notification: {
        'createNotification': false,
        'notificationList': false,
        'holidayFormController': false,
        'notificationController': false,
      },
      subject: {
        'saveSubjectsToClasses': false,
        'classSubjectShow': false,
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student': student,
      'faculty': faculty,
      'finance': finance,
      'notification': notification,
      'subject': subject,
    };
  }

  factory Permissions.fromJson(Map<String, dynamic> json) {
    return Permissions(
      student: Map<String, bool>.from(json['student'] ?? {}),
      faculty: Map<String, bool>.from(json['faculty'] ?? {}),
      finance: Map<String, bool>.from(json['finance'] ?? {}),
      notification: Map<String, bool>.from(json['notification'] ?? {}),
      subject: Map<String, bool>.from(json['subject'] ?? {}),
    );
  }
}

class PermissionManagement extends StatefulWidget {
  @override
  _PermissionManagementState createState() => _PermissionManagementState();
}

class _PermissionManagementState extends State<PermissionManagement> {
  List<Faculty> facultyData = [];
  Faculty? selectedFaculty;
  Permissions permissions = Permissions.defaultPermissions();
  bool isLoading = false;
  String? authToken;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

// Add this to your initState method
Future<void> _initializeData() async {
  final prefs = await SharedPreferences.getInstance();
  final storedToken = prefs.getString('authToken');
  
  if (storedToken == null) {
    print('WARNING: authToken is null in SharedPreferences');
    
  } else {
    authToken = storedToken;
  }
  
  await _fetchFaculty();
}
// Updated _fetchFaculty method only  
Future<void> _fetchFaculty() async {
  setState(() {
    isLoading = true;
  });

  try {
   
    final response = await http.get(
      Uri.parse('https://s-m-s-keyw.onrender.com/faculty/findAllFaculty'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(Duration(seconds: 30));

    

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        facultyData = data.map((faculty) => Faculty.fromJson(faculty)).toList();
      });
      
    } else {
      _showErrorSnackBar('Failed to fetch faculty data: ${response.statusCode}');
    }
  } catch (error) {
    
    _showErrorSnackBar('Failed to fetch faculty data');
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}
  Future<void> _fetchPermissions(Faculty faculty) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://s-m-s-keyw.onrender.com/permissions/getAll'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final selectedFacultyPermissions = data.firstWhere(
          (item) => item['email'] == faculty.email || 
                   item['permission']['facultyId'] == faculty.id,
          orElse: () => null,
        );

        if (selectedFacultyPermissions != null) {
          setState(() {
            permissions = Permissions.fromJson(
              selectedFacultyPermissions['permission']['permissions']
            );
          });
        } else {
          setState(() {
            permissions = Permissions.defaultPermissions();
          });
        }
      } else {
        _showErrorSnackBar('Failed to fetch permissions');
      }
    } catch (error) {
      
      _showErrorSnackBar('Failed to fetch permissions');
    }

    setState(() {
      isLoading = false;
    });
  }
Future<void> _savePermissions() async {
  if (selectedFaculty == null) {
    _showWarningSnackBar('Please select a faculty member.');
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    // Get token exactly as stored
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    
    if (token == null) {
      throw Exception('Auth token is null');
    }

    // Create payload exactly like React version
    final payload = {
      'facultyId': selectedFaculty!.id,
      'email': selectedFaculty!.email,
      'permissions': permissions.toJson(),
    };

  
   
final url = 'https://s-m-s-keyw.onrender.com/permissions/save?user=${selectedFaculty!.email}';

final response = await http.post(
  Uri.parse(url),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: json.encode({
    'facultyId': selectedFaculty!.id,
    'email': selectedFaculty!.email,
    'permissions': permissions.toJson(),
  }),
);
   
    if (response.statusCode == 200 || response.statusCode == 201) {
      _showSuccessSnackBar('Permissions updated successfully!');
    } else {
      _showErrorSnackBar('Error updating permissions: ${response.statusCode}');
    }
  } catch (error) {
    
    _showErrorSnackBar('Error updating permissions');
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}
  void _updatePermission(String section, String key, bool value) {
    setState(() {
      switch (section) {
        case 'student':
          permissions.student[key] = value;
          break;
        case 'faculty':
          permissions.faculty[key] = value;
          break;
        case 'finance':
          permissions.finance[key] = value;
          break;
        case 'notification':
          permissions.notification[key] = value;
          break;
        case 'subject':
          permissions.subject[key] = value;
          break;
      }
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _formatPermissionName(String key) {
    return key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).trim();
  }

  Widget _buildPermissionSection(String sectionName, Map<String, bool> sectionPermissions) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF3a8686),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              '${sectionName.substring(0, 1).toUpperCase()}${sectionName.substring(1)} Permissions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: sectionPermissions.entries.map((entry) {
                return CheckboxListTile(
                  title: Text(_formatPermissionName(entry.key)),
                  value: entry.value,
                  onChanged: (bool? value) {
                    _updatePermission(sectionName, entry.key, value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Faculty Permission'),
        backgroundColor: Color(0xFF3a8686),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Faculty Selection Dropdown
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Faculty Email:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: selectedFaculty?.email,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: '-- Select Email --',
                            ),
                            items: facultyData.map((faculty) {
                              return DropdownMenuItem<String>(
                                value: faculty.email,
                                child: Text(faculty.email),
                              );
                            }).toList(),
                            onChanged: (String? selectedEmail) {
                              if (selectedEmail != null) {
                                final faculty = facultyData.firstWhere(
                                  (f) => f.email == selectedEmail,
                                );
                                setState(() {
                                  selectedFaculty = faculty;
                                });
                                _fetchPermissions(faculty);
                              }
                            },
                          ),
                          if (selectedFaculty != null) ...[
                            SizedBox(height: 16),
                            Text(
                              'Selected Faculty Name:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              initialValue: selectedFaculty!.name,
                              enabled: false,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Permissions List
                  if (selectedFaculty != null)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildPermissionSection('student', permissions.student),
                            _buildPermissionSection('faculty', permissions.faculty),
                            _buildPermissionSection('finance', permissions.finance),
                            _buildPermissionSection('notification', permissions.notification),
                            _buildPermissionSection('subject', permissions.subject),
                            
                            SizedBox(height: 20),
                            
                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: selectedFaculty != null ? _savePermissions : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF3a8686),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  textStyle: TextStyle(fontSize: 18),
                                ),
                                child: Text('Save Permissions'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}