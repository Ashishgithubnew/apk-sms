import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import "./model/student_model.dart";
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class TransferCertificateScreen extends StatefulWidget {
  const TransferCertificateScreen({super.key});

  @override
  State<TransferCertificateScreen> createState() => _TransferCertificateScreenState();
}

class _TransferCertificateScreenState extends State<TransferCertificateScreen> {
  static const String baseUrl = 'https://s-m-s-keyw.onrender.com';

  List<Student> students = [];
  List<Student> filteredStudents = [];
  Student? selectedStudent;
  bool loading = false;
  bool downloading = false;

  // Filter states
  String classFilter = "All Classes";
  String nameFilter = "";

  // Form controllers
  final Map<String, TextEditingController> controllers = {
    'tcNo': TextEditingController(),
    'admissionNo': TextEditingController(),
    'dobWords': TextEditingController(),
    'nationality': TextEditingController(text: 'Indian'),
    'promotedTo': TextEditingController(),
    'admissionDate': TextEditingController(),
    'leavingDate': TextEditingController(),
    'reason': TextEditingController(),
    'conduct': TextEditingController(text: 'Good'),
    'remarks': TextEditingController(),
    'date': TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now())),
    'principalName': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  @override
  void dispose() {
    controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // API Methods
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken");
  }

  Future<void> fetchStudents() async {
    setState(() => loading = true);
    try {
      final token = await getToken();
      if (token == null) {
        _showSnackBar('Token not found. Please login again.', isError: true);
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/student/findAllStudent'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final studentList = data.map((json) => Student.fromJson(json)).toList();
        setState(() {
          students = studentList;
          filteredStudents = studentList;
        });
      } else {
        throw Exception('Failed to fetch students');
      }
    } catch (e) {
      _showSnackBar('Failed to fetch students data: $e', isError: true);
    } finally {
      setState(() => loading = false);
    }
  }

  // Simplified permission handling method
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Try multiple permission approaches for different Android versions
      try {
        // First try the newer permissions for Android 11+
        var status = await Permission.manageExternalStorage.status;
        if (status.isGranted) {
          return true;
        }

        // If not granted, try to request it
        status = await Permission.manageExternalStorage.request();
        if (status.isGranted) {
          return true;
        }

        // If manage external storage is not available, try storage permission
        var storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) {
          return true;
        }

        storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          return true;
        }

        // If both fail, we'll use app-specific directory which doesn't need permission
        return true;
      } catch (e) {
        print('Permission error: $e');
        // If permission handling fails, we'll use app-specific directory
        return true;
      }
    }
    return true; // For iOS or other platforms
  }

  // Updated download method with simplified permission handling
  Future<void> downloadTC() async {
    if (selectedStudent == null) {
      _showSnackBar('Please select a student first', isError: true);
      return;
    }

    setState(() => downloading = true);
    try {
      final token = await getToken();
      if (token == null) {
        _showSnackBar('Token not found. Please login again.', isError: true);
        return;
      }

      final payload = generateTCPayload();

      if (kIsWeb) {
        // Web version
        final dio = Dio();
        final response = await dio.post(
          '$baseUrl/student/download-tc',
          data: payload.toJson(),
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            responseType: ResponseType.bytes,
          ),
        );

        final fileName = 'TC_${payload.studentName}_${payload.tcNo}.pdf';
        final blob = html.Blob([response.data], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();

        html.Url.revokeObjectUrl(url);
        _showSnackBar('Transfer Certificate download started!');
      } else {
        // Mobile version with simplified permission handling
        await _requestStoragePermission();

        final dio = Dio();
        final fileName = 'TC_${payload.studentName}_${payload.tcNo}.pdf';

        // Try different storage locations in order of preference
        String? filePath;

        try {
          // First try: Downloads folder (works on most devices)
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            filePath = '${downloadsDir.path}/$fileName';
          }
        } catch (e) {
          print('Downloads directory not accessible: $e');
        }

        if (filePath == null) {
          try {
            // Second try: External storage directory
            final dir = await getExternalStorageDirectory();
            if (dir != null) {
              final downloadDir = '${dir.path}/Downloads';
              final downloadFolder = Directory(downloadDir);
              if (!await downloadFolder.exists()) {
                await downloadFolder.create(recursive: true);
              }
              filePath = '$downloadDir/$fileName';
            }
          } catch (e) {
            print('External storage directory not accessible: $e');
          }
        }

        if (filePath == null) {
          // Final fallback: App documents directory (always works)
          final dir = await getApplicationDocumentsDirectory();
          filePath = '${dir.path}/$fileName';
        }

        await dio.post(
          '$baseUrl/student/download-tc',
          data: payload.toJson(),
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            responseType: ResponseType.bytes,
          ),
        ).then((response) async {
          final file = File(filePath!);
          await file.writeAsBytes(response.data);
        });

        _showSnackBar('Transfer Certificate downloaded successfully to: $filePath');
      }
    } catch (e) {
      _showSnackBar('Failed to download Transfer Certificate: $e', isError: true);
    } finally {
      setState(() => downloading = false);
    }
  }

  // Helper Methods
  void filterStudents() {
    List<Student> filtered = students;

    if (classFilter != "All Classes") {
      filtered = filtered.where((student) =>
          student.cls.toLowerCase().contains(classFilter.toLowerCase())).toList();
    }

    if (nameFilter.isNotEmpty) {
      filtered = filtered.where((student) =>
          student.name.toLowerCase().contains(nameFilter.toLowerCase())).toList();
    }

    setState(() => filteredStudents = filtered);
  }

  String formatDateForDisplay(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void selectStudent(Student student) {
    setState(() => selectedStudent = student);
    controllers['admissionNo']?.text = student.studentCode;
    controllers['dobWords']?.text = '';
  }

  TCPayload generateTCPayload() {
    if (selectedStudent == null) throw Exception('No student selected');

    return TCPayload(
      tcNo: controllers['tcNo']?.text ?? '',
      admissionNo: controllers['admissionNo']?.text ?? selectedStudent!.studentCode,
      studentName: selectedStudent!.name,
      fatherName: selectedStudent!.familyDetails.stdoFatherName,
      motherName: selectedStudent!.familyDetails.stdoMotherName,
      caste: selectedStudent!.category,
      dobFigures: formatDateForDisplay(selectedStudent!.dob),
      dobWords: controllers['dobWords']?.text ?? '',
      nationality: controllers['nationality']?.text ?? 'Indian',
      lastClass: selectedStudent!.cls,
      promotedTo: controllers['promotedTo']?.text ?? '',
      admissionDate: controllers['admissionDate']?.text ?? '',
      leavingDate: controllers['leavingDate']?.text ?? '',
      reason: controllers['reason']?.text ?? '',
      conduct: controllers['conduct']?.text ?? 'Good',
      remarks: controllers['remarks']?.text ?? '',
      date: controllers['date']?.text ?? DateFormat('dd/MM/yyyy').format(DateTime.now()),
      principalName: controllers['principalName']?.text ?? '',
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  List<String> getUniqueClasses() {
    final classes = students.map((student) => student.cls).toSet().toList();
    classes.sort();
    return classes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transfer Certificate Generator'),
        backgroundColor: Color(0xFF126666),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Transfer Certificate Generator',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF126666),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Generate and download student transfer certificates',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Filters
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.search, color: Color(0xFF126666)),
                      SizedBox(width: 8),
                      Text(
                        'Search & Filter Students',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Filter by Class', style: TextStyle(fontWeight: FontWeight.w500)),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: classFilter,
                                      isExpanded: true,
                                      items: ['All Classes', ...getUniqueClasses()]
                                          .map((cls) => DropdownMenuItem(value: cls, child: Text(cls)))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() => classFilter = value!);
                                        filterStudents();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Search by Name', style: TextStyle(fontWeight: FontWeight.w500)),
                                SizedBox(height: 8),
                                TextField(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    hintText: 'Enter student name...',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    prefixIcon: Icon(Icons.person_search, color: Colors.grey[400]),
                                  ),
                                  onChanged: (value) {
                                    setState(() => nameFilter = value);
                                    filterStudents();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: loading ? null : fetchStudents,
                          icon: loading
                              ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                              : Icon(Icons.refresh),
                          label: Text(loading ? 'Loading...' : 'Refresh'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF126666),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Students List
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: Color(0xFF126666)),
                      SizedBox(width: 8),
                      Text(
                        'Students (${filteredStudents.length})',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Click on a student to generate their TC',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  loading
                      ? Container(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF126666)),
                          SizedBox(height: 16),
                          Text('Loading students...', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  )
                      : Container(
                    height: 300,
                    child: filteredStudents.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No students found',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = filteredStudents[index];
                        final isSelected = selectedStudent?.id == student.id;
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xFF126666) : Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Color(0xFF126666) : Colors.grey[200]!,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? Colors.white : Color(0xFF126666),
                              child: Text(
                                student.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: isSelected ? Color(0xFF126666) : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              student.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Class: ${student.cls} | Code: ${student.studentCode} | Category: ${student.category}',
                              style: TextStyle(
                                color: isSelected ? Colors.white70 : Colors.grey[600],
                              ),
                            ),
                            trailing: Text(
                              student.contact,
                              style: TextStyle(
                                color: isSelected ? Colors.white70 : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () => selectStudent(student),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // TC Form
            if (selectedStudent != null) ...[
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment, color: Color(0xFF126666)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Generate TC for ${selectedStudent!.name}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Fill in the missing information to generate the transfer certificate',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 20),

                    // Auto-filled fields
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue[700], size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Auto-filled Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          _buildReadOnlyField('Student Name', selectedStudent!.name),
                          _buildReadOnlyField('Father Name', selectedStudent!.familyDetails.stdoFatherName),
                          _buildReadOnlyField('Mother Name', selectedStudent!.familyDetails.stdoMotherName),
                          _buildReadOnlyField('Caste/Category', selectedStudent!.category),
                          _buildReadOnlyField('Date of Birth', formatDateForDisplay(selectedStudent!.dob)),
                          _buildReadOnlyField('Last Class', selectedStudent!.cls),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(Icons.edit, color: Color(0xFF126666), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Additional Information',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Manual input fields
                    _buildTextField('TC Number', 'tcNo', 'e.g., 2024/001'),
                    _buildTextField('Admission Number', 'admissionNo', 'Admission number'),
                    _buildTextField('Date of Birth (in words)', 'dobWords', 'e.g., Fifteenth August Two Thousand Ten'),
                    _buildTextField('Nationality', 'nationality', 'Nationality'),
                    _buildTextField('Promoted To', 'promotedTo', 'e.g., IX'),
                    _buildDateField('Admission Date', 'admissionDate'),
                    _buildDateField('Leaving Date', 'leavingDate'),
                    _buildTextField('Reason for Leaving', 'reason', 'e.g., Parent Transfer'),
                    _buildDropdownField('Conduct', 'conduct', ['Excellent', 'Very Good', 'Good', 'Satisfactory']),
                    _buildTextField('Principal Name', 'principalName', 'e.g., Mr. A. Sharma'),
                    _buildTextField('Remarks', 'remarks', 'Additional remarks...', maxLines: 3),

                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: downloading ? null : downloadTC,
                        icon: downloading
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : Icon(Icons.download),
                        label: Text(
                          downloading ? 'Generating TC...' : 'Download Transfer Certificate',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF126666),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              value.isEmpty ? 'Not available' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey[500] : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String key, String hint, {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          SizedBox(height: 6),
          TextField(
            controller: controllers[key],
            maxLines: maxLines,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF126666), width: 2),
              ),
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, String key) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          SizedBox(height: 6),
          TextField(
            controller: controllers[key],
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF126666), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              suffixIcon: Icon(Icons.calendar_today, color: Color(0xFF126666)),
            ),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                controllers[key]?.text = DateFormat('yyyy-MM-dd').format(date);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String key, List<String> options) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          SizedBox(height: 6),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controllers[key]?.text.isNotEmpty == true ? controllers[key]?.text : options.first,
                isExpanded: true,
                items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                onChanged: (value) => controllers[key]?.text = value!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
