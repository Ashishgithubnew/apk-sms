import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StudentReportForm extends StatefulWidget {
  const StudentReportForm({super.key});

  @override
  _StudentReportFormState createState() => _StudentReportFormState();
}

class _StudentReportFormState extends State<StudentReportForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<dynamic> _classData = [];
  List<dynamic> _students = [];
  List<String> _subjects = [];
  List<Map<String, dynamic>> _subjectMarks = [];
  
  String? _selectedClass;
  String? _selectedStudent;
  String? _selectedExamType;
  DateTime _selectedExamDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadClassData();
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> _loadClassData() async {
    try {
      setState(() => _isLoading = true);
      final token = await _getToken();
      
      final response = await http.get(
        Uri.parse("https://s-m-s-keyw.onrender.com/class/data"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        if (decodedBody is Map && decodedBody['classData'] is List) {
          setState(() {
           _classData = decodedBody['classData'];
          });
        } else {
          _showError("Invalid class data format");
        }
      } else {
        _showError("Failed to load class data: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error loading class data: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStudents(String? classSelected) async {
    if (classSelected == null || classSelected.isEmpty) {
      setState(() {
        _students = [];
        _selectedStudent = null;
      });
      return;
    }

    try {
      setState(() => _isLoading = true);
      final token = await _getToken();
      
      final response = await http.get(
        Uri.parse("https://s-m-s-keyw.onrender.com/student/findAllStudent?cls=${Uri.encodeComponent(classSelected)}"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        if (decodedBody is List) {
          setState(() {
            _students = decodedBody;
          });
        } else {
          _showError("Invalid student data format");
        }
      } else {
        _showError("No students found in this class");
      }
    } catch (e) {
      _showError("Error fetching students: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _getSubjectsForClass(String? classSelected) {
    if (classSelected == null || classSelected.isEmpty || _classData.isEmpty) {
      setState(() {
        _subjects = [];
        _subjectMarks = [];
      });
      return;
    }

    try {
      final selectedClass = _classData.firstWhere(
        (c) => c['className']?.toString() == classSelected,
      );

      if (selectedClass != null && selectedClass['subject'] is List) {
        setState(() {
          _subjects = List<String>.from(selectedClass['subject'].map((s) => s.toString()));
          _subjectMarks = _subjects.map((subject) => {
            'subject': subject,
            'marksObtained': null,
            'maxMarks': 100,
            'remarks': '',
          }).toList();
        });
      } else {
        _showError("No subjects found for this class");
      }
    } catch (e) {
      _showError("Error getting subjects: ${e.toString()}");
    }
  }

  Map<String, dynamic> _calculateTotalAverageGrade() {
    if (_subjectMarks.isEmpty) {
      return {'totalMarks': 0, 'average': 0, 'grade': 'N/A'};
    }

    final validMarks = _subjectMarks.where((mark) =>
      mark['marksObtained'] != null && mark['maxMarks'] != null).toList();

    if (validMarks.isEmpty) {
      return {'totalMarks': 0, 'average': 0, 'grade': 'N/A'};
    }

    final totalMarks = validMarks.fold(0, (sum, row) => sum + (row['marksObtained'] as int));
    final totalMaxMarks = validMarks.fold(0, (sum, row) => sum + (row['maxMarks'] as int));
    final average = totalMarks / validMarks.length;
    final percentage = totalMaxMarks > 0 ? (totalMarks / totalMaxMarks) * 100 : 0;

    String grade = 'F';
    if (percentage >= 90) grade = 'A';
    else if (percentage >= 75) grade = 'B';
    else if (percentage >= 50) grade = 'C';

    return {
      'totalMarks': totalMarks,
      'average': double.parse(average.toStringAsFixed(2)),
      'grade': grade,
    };
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedStudent == null) {
        _showError("Please select a student");
        return;
      }

      try {
        setState(() => _isSubmitting = true);
        final token = await _getToken();

        // Prepare subjects data
        final subjectsData = _subjectMarks.map((subject) => ({
          'subject': subject['subject'],
          'marksObtained': subject['marksObtained'] ?? 0,
          'maxMarks': subject['maxMarks'] ?? 100,
          'remarks': subject['remarks'] ?? '',
        })).toList();

        final results = _calculateTotalAverageGrade();

        final payload = {
          'id': _selectedStudent,
          'examType': _selectedExamType,
          'examDate': DateFormat('dd/MM/yyyy').format(_selectedExamDate),
          'subjects': subjectsData,
          'totalMarks': results['totalMarks'],
          'average': results['average'],
          'grade': results['grade'],
        };

        final response = await http.post(
          Uri.parse("https://s-m-s-keyw.onrender.com/report/save?id=${Uri.encodeComponent(_selectedStudent!)}"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(payload),
        );

        if (response.statusCode == 200) {
          _showSuccess("Report submitted successfully!");
          _formKey.currentState!.reset();
          setState(() {
            _selectedClass = null;
            _selectedStudent = null;
            _selectedExamType = null;
            _selectedExamDate = DateTime.now();
            _subjectMarks = [];
          });
        } else {
          _showError("Failed to submit report: ${response.body}");
        }
      } catch (e) {
        _showError("Error submitting report: ${e.toString()}");
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExamDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedExamDate) {
      setState(() {
        _selectedExamDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Student Report Form'),
         backgroundColor: const Color(0xFF126666),
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
          iconTheme: const IconThemeData(
          color: Colors.white,
          size: 30,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Report',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(20), // Increased padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Class Selection - Full width
                            DropdownButtonFormField<String>(
                              value: _selectedClass,
                              decoration: const InputDecoration(
                                labelText: 'Class',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Increased padding
                              ),
                              items: _classData.map<DropdownMenuItem<String>>((classItem) {
                                final className = classItem['className']?.toString() ?? 'Unknown';
                                return DropdownMenuItem<String>(
                                  value: className,
                                  child: Text('Class $className'),
                                );
                              }).toList(),
                              validator: (value) => value == null ? 'Please select a class' : null,
                              onChanged: (value) {
                                setState(() {
                                  _selectedClass = value;
                                  _selectedStudent = null;
                                  _fetchStudents(value);
                                  _getSubjectsForClass(value);
                                });
                              },
                            ),
                            
                            const SizedBox(height: 20), // Increased spacing
                            
                            // Student Selection - Full width dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedStudent,
                              decoration: const InputDecoration(
                                labelText: 'Student',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Increased padding
                              ),
                              items: _students.map<DropdownMenuItem<String>>((student) {
                                final name = student['name']?.toString() ?? 'Unknown';
                                final fatherName = student['familyDetails']?['stdo_FatherName']?.toString() ?? '';
                                return DropdownMenuItem<String>(
                                  value: student['id'].toString(),
                                  child: Text('$name (Father: $fatherName)'),
                                );
                              }).toList(),
                              validator: (value) => value == null ? 'Please select a student' : null,
                              onChanged: (value) {
                                setState(() {
                                  _selectedStudent = value;
                                });
                              },
                              isExpanded: true, // Ensures dropdown uses full width
                            ),
                            
                            const SizedBox(height: 20), // Increased spacing
                            
                            // Exam Type - Full width
                            DropdownButtonFormField<String>(
                              value: _selectedExamType,
                              decoration: const InputDecoration(
                                labelText: 'Exam Type',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Increased padding
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Test', child: Text('Test')),
                                DropdownMenuItem(value: 'Quarterly', child: Text('Quarterly')),
                                DropdownMenuItem(value: 'Half Yearly', child: Text('Half Yearly')),
                                DropdownMenuItem(value: 'Final Year', child: Text('Final Year')),
                              ],
                              validator: (value) => value == null ? 'Please select exam type' : null,
                              onChanged: (value) {
                                setState(() {
                                  _selectedExamType = value;
                                });
                              },
                              isExpanded: true, // Ensures dropdown uses full width
                            ),
                            
                            const SizedBox(height: 20), // Increased spacing
                            
                            // Exam Date - Full width
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Exam Date',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20), // Increased padding
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(DateFormat('dd/MM/yyyy').format(_selectedExamDate)),
                                    const Icon(Icons.calendar_today, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Subject Marks Table
                            if (_subjects.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Subject Marks',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columnSpacing: 20, // Increased spacing
                                      headingRowHeight: 50, // Increased height
                                      dataRowHeight: 65, // Increased height
                                      columns: const [
                                        DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Marks Obtained', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Max Marks', style: TextStyle(fontWeight: FontWeight.bold))),
                                        DataColumn(label: Text('Remarks', style: TextStyle(fontWeight: FontWeight.bold))),
                                      ],
                                      rows: _subjectMarks.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final subject = entry.value;
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(subject['subject'])),
                                            DataCell(
                                              SizedBox(
                                                width: 120, // Increased width
                                                child: TextFormField(
                                                  initialValue: subject['marksObtained']?.toString(),
                                                  keyboardType: TextInputType.number,
                                                  decoration: const InputDecoration(
                                                    border: OutlineInputBorder(),
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Increased padding
                                                  ),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) {
                                                      return 'Required';
                                                    }
                                                    final marks = int.tryParse(value);
                                                    if (marks == null || marks < 0) {
                                                      return 'Invalid';
                                                    }
                                                    return null;
                                                  },
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _subjectMarks[index]['marksObtained'] = 
                                                        value.isNotEmpty ? int.tryParse(value) : null;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 120, // Increased width
                                                child: TextFormField(
                                                  initialValue: subject['maxMarks']?.toString(),
                                                  keyboardType: TextInputType.number,
                                                  decoration: const InputDecoration(
                                                    border: OutlineInputBorder(),
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Increased padding
                                                  ),
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) {
                                                      return 'Required';
                                                    }
                                                    final maxMarks = int.tryParse(value);
                                                    if (maxMarks == null || maxMarks <= 0) {
                                                      return 'Invalid';
                                                    }
                                                    return null;
                                                  },
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _subjectMarks[index]['maxMarks'] = 
                                                        value.isNotEmpty ? int.tryParse(value) : null;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 180, // Increased width
                                                child: TextFormField(
                                                  initialValue: subject['remarks'],
                                                  decoration: const InputDecoration(
                                                    border: OutlineInputBorder(),
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), // Increased padding
                                                  ),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _subjectMarks[index]['remarks'] = value;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                              
                            const SizedBox(height: 24),
                            
                            // Results Summary
                            if (_subjectMarks.isNotEmpty)
                              Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(20), // Increased padding
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          const Text(
                                            'Total Marks',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _calculateTotalAverageGrade()['totalMarks'].toString(),
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          const Text(
                                            'Average',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _calculateTotalAverageGrade()['average'].toString(),
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          const Text(
                                            'Grade',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _calculateTotalAverageGrade()['grade'].toString(),
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                            const SizedBox(height: 30), // Increased spacing
                            
                            // Submit Button
                            Center(
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), // Increased padding
                                  minimumSize: const Size(200, 50), // Set minimum size
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Submit Report',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}