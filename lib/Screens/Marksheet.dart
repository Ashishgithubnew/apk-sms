import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// Web-specific imports
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
import './model/marksheet_model.dart';
import './model/student_model.dart';

class MarksheetScreen extends StatefulWidget {
  const MarksheetScreen({super.key});

  @override
  State<MarksheetScreen> createState() => _MarksheetScreenState();
}

class _MarksheetScreenState extends State<MarksheetScreen> {
  static const String baseUrl = 'https://s-m-s-keyw.onrender.com';
  List<Student> students = [];
  List<Student> filteredStudents = [];
  Student? selectedStudent;
  List<ReportCard> reportCards = [];
  ConsolidatedReport? consolidatedReport;
  bool loading = false;
  bool downloading = false;
  String searchTerm = "";
  String selectedClass = "";
  String? error;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final token = await getToken();
    if (token != null) {
      fetchStudents();
    }
  }

  // API Methods
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Map<String, String> getHeaders(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      headers['token'] = token;
    }
    return headers;
  }

  String safeValue(dynamic value, [String fallback = "N/A"]) {
    if (value == null || value == "" || value.toString().isEmpty) {
      return fallback;
    }
    return value.toString();
  }

  String calculateGrade(double percentage) {
    if (percentage >= 90) return "A+";
    if (percentage >= 80) return "A";
    if (percentage >= 70) return "B+";
    if (percentage >= 60) return "B";
    if (percentage >= 50) return "C";
    if (percentage >= 40) return "D";
    return "F";
  }

  Color getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case "A+":
      case "A":
        return Colors.green;
      case "B+":
      case "B":
        return Colors.blue;
      case "C":
        return Colors.orange;
      case "D":
        return Colors.deepOrange;
      case "F":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String normalizeExamType(String examType) {
    final type = examType.toLowerCase().trim();
    if (type.contains("quarter") || type.contains("quaterly")) return "quarterly";
    if (type.contains("half") || type.contains("mid")) return "halfyearly";
    if (type.contains("final") || type.contains("annual")) return "final";
    if (type.contains("test")) return "test";
    return type;
  }

  DateTime? parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }
    try {
      final formats = [
        'yyyy-MM-dd',
        'dd/MM/yyyy',
        'MM/dd/yyyy',
        'yyyy-MM-ddTHH:mm:ss',
        'yyyy-MM-ddTHH:mm:ss.SSS',
        'yyyy-MM-ddTHH:mm:ssZ',
        'dd-MM-yyyy',
        'MM-dd-yyyy',
      ];
      for (final format in formats) {
        try {
          final formatter = DateFormat(format);
          return formatter.parse(dateString);
        } catch (e) {
          continue;
        }
      }
      return DateTime.parse(dateString);
    } catch (e) {
      print('Error parsing date: $dateString - $e');
      return DateTime.now();
    }
  }

  // EXACTLY matching web version's getUniqueExams logic
  List<ReportCard> getUniqueExams(List<ReportCard> reports) {
    final Map<String, ReportCard> examMap = {};
    
    for (final report in reports) {
      final normalizedType = normalizeExamType(report.examType);
      // Only keep quarterly, halfyearly, and final exams
      if (["quarterly", "halfyearly", "final"].contains(normalizedType)) {
        // If we already have this exam type, keep the one with later date
        if (!examMap.containsKey(normalizedType) ||
            (parseDate(report.examDate)?.isAfter(parseDate(examMap[normalizedType]!.examDate) ?? DateTime(1900)) ?? false)) {
          examMap[normalizedType] = ReportCard(
            id: report.id,
            reportId: report.reportId,
            examType: normalizedType, // Use normalized type
            examDate: report.examDate,
            subjects: report.subjects,
            totalMarks: report.totalMarks,
            average: report.average,
            grade: report.grade,
          );
        }
      }
    }
    return examMap.values.toList();
  }

  // EXACTLY matching web version's createConsolidatedReport logic
  ConsolidatedReport createConsolidatedReport(List<ReportCard> uniqueReports) {
    final Map<String, ConsolidatedSubject> subjectMap = {};
    final Map<String, String> examDates = {};

    print('=== DEBUG: Creating Consolidated Report ===');
    print('Unique reports count: ${uniqueReports.length}');
    for (final report in uniqueReports) {
      print('Report: ${report.examType}, Date: ${report.examDate}, Subjects: ${report.subjects.length}');
      for (final subject in report.subjects) {
        print('  Subject: ${subject.subject}, Marks: ${subject.marksObtained}/${subject.maxMarks}');
      }
    }

    // Initialize subjects from all exams - exactly like web version
    for (final report in uniqueReports) {
      final examType = report.examType;
      examDates[examType == "halfyearly" ? "halfYearly" : examType] = report.examDate;
      
      for (final subject in report.subjects) {
        if (!subjectMap.containsKey(subject.subject)) {
          subjectMap[subject.subject] = ConsolidatedSubject(
            subject: subject.subject,
            quarterly: null,
            halfYearly: null,
            finalExam: null,
            total: 0,
            maxTotal: 0,
            percentage: 0.0,
            grade: 'N/A',
          );
        }
      }
    }

    // Populate marks for each exam type
    for (final report in uniqueReports) {
      final examType = report.examType;
      
      for (final subject in report.subjects) {
        final consolidatedSubject = subjectMap[subject.subject]!;
        final marksObtained = (subject.marksObtained is double) 
            ? (subject.marksObtained as double).round() 
            : (subject.marksObtained as int);
        final maxMarks = (subject.maxMarks is double) 
            ? (subject.maxMarks as double).round() 
            : (subject.maxMarks as int);

        // Set marks based on exam type - exactly like web version
        if (examType == "quarterly") {
          consolidatedSubject.quarterly = {'marks': marksObtained, 'maxMarks': maxMarks};
        } else if (examType == "halfyearly") {
          consolidatedSubject.halfYearly = {'marks': marksObtained, 'maxMarks': maxMarks};
        } else if (examType == "final") {
          consolidatedSubject.finalExam = {'marks': marksObtained, 'maxMarks': maxMarks};
        }
        
        print('Set ${subject.subject} ${examType}: ${marksObtained}/${maxMarks}');
      }
    }

    // Calculate totals and percentages - exactly like web version
    final List<ConsolidatedSubject> subjects = [];
    for (final subjectName in subjectMap.keys) {
      final subject = subjectMap[subjectName]!;
      
      final quarterly = subject.quarterly?['marks'] ?? 0;
      final halfYearly = subject.halfYearly?['marks'] ?? 0;
      final finalMarks = subject.finalExam?['marks'] ?? 0;
      final quarterlyMax = subject.quarterly?['maxMarks'] ?? 0;
      final halfYearlyMax = subject.halfYearly?['maxMarks'] ?? 0;
      final finalMax = subject.finalExam?['maxMarks'] ?? 0;
      
      final total = quarterly + halfYearly + finalMarks;
      final maxTotal = quarterlyMax + halfYearlyMax + finalMax;
      final percentage = maxTotal > 0 ? (total / maxTotal) * 100 : 0.0;

      print('Subject: $subjectName');
      print('  Quarterly: $quarterly/$quarterlyMax');
      print('  Half Yearly: $halfYearly/$halfYearlyMax');
      print('  Final: $finalMarks/$finalMax');
      print('  Total: $total/$maxTotal');
      print('  Percentage: $percentage');

      // Create new consolidated subject with calculated values
      final consolidatedSubject = ConsolidatedSubject(
        subject: subjectName,
        quarterly: subject.quarterly,
        halfYearly: subject.halfYearly,
        finalExam: subject.finalExam,
        total: total,
        maxTotal: maxTotal,
        percentage: double.parse((percentage).toStringAsFixed(2)),
        grade: calculateGrade(percentage),
      );

      subjects.add(consolidatedSubject);
    }

    final totalMarks = subjects.fold(0, (sum, subject) => sum + subject.total);
    final totalMaxMarks = subjects.fold(0, (sum, subject) => sum + subject.maxTotal);
    final overallPercentage = totalMaxMarks > 0 ? (totalMarks / totalMaxMarks) * 100 : 0.0;

    print('=== Final Consolidated Report ===');
    print('Total Marks: $totalMarks/$totalMaxMarks');
    print('Overall Percentage: $overallPercentage');

    return ConsolidatedReport(
      subjects: subjects,
      totalMarks: totalMarks,
      totalMaxMarks: totalMaxMarks,
      overallPercentage: double.parse(overallPercentage.toStringAsFixed(2)),
      overallGrade: calculateGrade(overallPercentage),
      examDates: examDates,
    );
  }

  Future<void> fetchStudents() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final token = await getToken();
      if (token == null) {
        setState(() => error = 'Token not found. Please login again.');
        return;
      }
      final response = await http.get(
        Uri.parse('$baseUrl/student/findAllStudent'),
        headers: getHeaders(token),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final studentList = data.map((json) => Student.fromJson(json)).toList();
        setState(() {
          students = studentList;
          filteredStudents = studentList;
        });
      } else {
        throw Exception('Failed to fetch students: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => error = 'Error fetching students: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> fetchStudentReport(String studentId) async {
    setState(() {
      loading = true;
      error = null;
      reportCards = [];
      consolidatedReport = null;
    });
    try {
      final token = await getToken();
      if (token == null) {
        setState(() => error = 'Token not found. Please login again.');
        return;
      }
      final url = '$baseUrl/report/getStudentReport?id=$studentId';
      final response = await http.get(
        Uri.parse(url),
        headers: getHeaders(token),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isEmpty) {
          setState(() {
            reportCards = [];
            consolidatedReport = null;
          });
          return;
        }
        
        // Process reports using the model's fromJson method
        final reports = data.map((json) => ReportCard.fromJson(json)).toList();
        
        setState(() => reportCards = reports);
        
        // Create consolidated report
        final uniqueReports = getUniqueExams(reports);
        if (uniqueReports.isNotEmpty) {
          try {
            final consolidated = createConsolidatedReport(uniqueReports);
            setState(() => consolidatedReport = consolidated);
          } catch (e) {
            print('Error creating consolidated report: $e');
            setState(() => consolidatedReport = null);
          }
        } else {
          setState(() => consolidatedReport = null);
        }
      } else if (response.statusCode == 404) {
        setState(() {
          reportCards = [];
          consolidatedReport = null;
        });
      } else {
        throw Exception('Failed to fetch report: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching student report: $e');
      setState(() {
        reportCards = [];
        consolidatedReport = null;
        if (!e.toString().contains('404')) {
          error = 'Error fetching student report: $e';
        }
      });
    } finally {
      setState(() => loading = false);
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      try {
        var status = await Permission.manageExternalStorage.status;
        if (status.isGranted) {
          return true;
        }
        status = await Permission.manageExternalStorage.request();
        if (status.isGranted) {
          return true;
        }
        var storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) {
          return true;
        }
        storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          return true;
        }
        return true;
      } catch (e) {
        print('Permission error: $e');
        return true;
      }
    }
    return true;
  }

  // EXACTLY matching web version's PDF generation
  Future<void> generateConsolidatedPDF() async {
    if (consolidatedReport == null || selectedStudent == null) {
      _showSnackBar('No consolidated report data available', isError: true);
      return;
    }

    setState(() {
      downloading = true;
      error = null;
    });

    try {
      final token = await getToken();
      if (token == null) {
        _showSnackBar('Token not found. Please login again.', isError: true);
        return;
      }

      print('=== DEBUG: PDF Generation Data ===');
      print('Student: ${selectedStudent!.name}');
      print('Consolidated subjects: ${consolidatedReport!.subjects.length}');
      for (final subject in consolidatedReport!.subjects) {
        print('Subject: ${subject.subject}');
        print('  Quarterly: ${subject.quarterly?['marks']} / ${subject.quarterly?['maxMarks']}');
        print('  Half Yearly: ${subject.halfYearly?['marks']} / ${subject.halfYearly?['maxMarks']}');
        print('  Final: ${subject.finalExam?['marks']} / ${subject.finalExam?['maxMarks']}');
        print('  Total: ${subject.total} / ${subject.maxTotal}');
        print('  Grade: ${subject.grade}');
      }

      // EXACTLY matching web version's PDF data structure
      final pdfData = {
        'studentName': safeValue(selectedStudent!.name, 'Unknown Student'),
        'rollNo': safeValue(selectedStudent!.studentCode, 'N/A'),
        'studentClass': safeValue(selectedStudent!.cls, 'N/A'),
        'academicYear': '2024-2025',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'result': 'Grade: ${consolidatedReport!.overallGrade}',
        'remarks': 'Overall Percentage: ${consolidatedReport!.overallPercentage}% - ${consolidatedReport!.overallGrade} Grade',
        'subjects': consolidatedReport!.subjects.map((subject) {
          final quarterlyMarks = subject.quarterly?['marks'] ?? 0;
          final halfYearlyMarks = subject.halfYearly?['marks'] ?? 0;
          final finalMarks = subject.finalExam?['marks'] ?? 0;
          
          print('Mapping subject ${subject.subject}: Q=$quarterlyMarks, H=$halfYearlyMarks, F=$finalMarks');
          
          return {
            'name': subject.subject,
            'quarterly': quarterlyMarks,
            'halfYearly': halfYearlyMarks,
            'final': finalMarks,
            'total': subject.total,
            'grade': calculateGrade(subject.percentage),
          };
        }).toList(),
        'totalMarks': consolidatedReport!.totalMarks,
        'totalMaxMarks': consolidatedReport!.totalMaxMarks,
        'overallPercentage': consolidatedReport!.overallPercentage,
        'overallGrade': consolidatedReport!.overallGrade,
      };

      print('=== Final PDF Data ===');
      print(json.encode(pdfData));

      final dio = Dio();
      final fileName = '${safeValue(selectedStudent!.name, "Student")}_Final_Result';
      
      // Try consolidated endpoint first
      Response? response;
      try {
        response = await dio.post(
          '$baseUrl/marksheet/downloadConsolidated',
          data: pdfData,
          options: Options(
            headers: getHeaders(token),
            responseType: ResponseType.bytes,
          ),
        );
      } catch (e) {
        print('Consolidated endpoint failed, trying fallback: $e');
        // Fallback to regular endpoint exactly like web version
        final fallbackData = {
          'studentName': pdfData['studentName'],
          'rollNo': pdfData['rollNo'],
          'studentClass': pdfData['studentClass'],
          'academicYear': pdfData['academicYear'],
          'date': pdfData['date'],
          'result': pdfData['result'],
          'remarks': pdfData['remarks'],
          'subjects': consolidatedReport!.subjects.map((subject) {
            return {
              'name': subject.subject,
              'q': subject.quarterly?['marks'] ?? 0,
              'h': subject.halfYearly?['marks'] ?? 0,
              'f': subject.finalExam?['marks'] ?? 0,
              'qMax': subject.quarterly?['maxMarks'] ?? 100,
              'hMax': subject.halfYearly?['maxMarks'] ?? 100,
              'fMax': subject.finalExam?['maxMarks'] ?? 100,
              'total': subject.total,
              'maxTotal': subject.maxTotal,
              'percentage': subject.percentage,
              'grade': calculateGrade(subject.percentage),
            };
          }).toList(),
          'totalMarks': consolidatedReport!.totalMarks,
          'totalMaxMarks': consolidatedReport!.totalMaxMarks,
          'overallPercentage': consolidatedReport!.overallPercentage,
          'overallGrade': consolidatedReport!.overallGrade,
        };
        
        print('=== Fallback PDF Data ===');
        print(json.encode(fallbackData));
        
        response = await dio.post(
          '$baseUrl/marksheet/download',
          data: fallbackData,
          options: Options(
            headers: getHeaders(token),
            responseType: ResponseType.bytes,
          ),
        );
      }

      if (kIsWeb) {
        final bytes = Uint8List.fromList(response.data);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', '$fileName.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSnackBar('Download started!');
      } else {
        await _requestStoragePermission();
        final fullFileName = '$fileName.pdf';
        String? filePath;
        
        try {
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            filePath = '${downloadsDir.path}/$fullFileName';
          }
        } catch (e) {
          print('Downloads directory not accessible: $e');
        }
        
        if (filePath == null) {
          try {
            final dir = await getExternalStorageDirectory();
            if (dir != null) {
              final downloadDir = '${dir.path}/Downloads';
              final downloadFolder = Directory(downloadDir);
              if (!await downloadFolder.exists()) {
                await downloadFolder.create(recursive: true);
              }
              filePath = '$downloadDir/$fullFileName';
            }
          } catch (e) {
            print('External storage directory not accessible: $e');
          }
        }
        
        if (filePath == null) {
          final dir = await getApplicationDocumentsDirectory();
          filePath = '${dir.path}/$fullFileName';
        }

        final file = File(filePath);
        await file.writeAsBytes(response.data);
        _showSnackBar('Final Result downloaded successfully to: $filePath');
      }
    } catch (e) {
      print('=== PDF Generation Error ===');
      print('Error: $e');
      _showSnackBar('Error generating PDF: $e', isError: true);
    } finally {
      setState(() => downloading = false);
    }
  }

  void handleStudentSelect(Student student) {
    setState(() {
      selectedStudent = student;
      error = null;
    });
    fetchStudentReport(student.id);
  }

  void filterStudents() {
    List<Student> filtered = students;
    if (selectedClass.isNotEmpty) {
      filtered = filtered.where((student) =>
      safeValue(student.cls) == selectedClass).toList();
    }
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((student) =>
      safeValue(student.name).toLowerCase().contains(searchTerm.toLowerCase()) ||
          safeValue(student.studentCode).contains(searchTerm) ||
          safeValue(student.cls).toLowerCase().contains(searchTerm.toLowerCase())).toList();
    }
    setState(() => filteredStudents = filtered);
  }

  List<String> getUniqueClasses() {
    final classes = students.map((student) => safeValue(student.cls))
        .where((cls) => cls != "N/A").toSet().toList();
    classes.sort();
    return classes;
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Final Result System'),
        backgroundColor: Color(0xFF126666),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<String?>(
        future: getToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Container(
                padding: EdgeInsets.all(32),
                margin: EdgeInsets.all(16),
                constraints: BoxConstraints(maxWidth: 400),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 40, color: Colors.red[400]),
                    SizedBox(height: 16),
                    Text(
                      'Authentication Required',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please login to access the final result system',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
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
                          'Student Final Result System',
                          style: TextStyle(
                            fontSize: isTablet ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF126666),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Consolidated academic performance across all exams',
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isTablet ? 16 : 14
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // Error Display
                  if (error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red[400]),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error!,
                              style: TextStyle(color: Colors.red[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  // Main Content - Responsive Layout
                  isTablet
                      ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Students List (Left Side)
                      Expanded(
                        flex: 1,
                        child: _buildStudentsList(),
                      ),
                      SizedBox(width: 16),
                      // Student Details (Right Side)
                      Expanded(
                        flex: 2,
                        child: _buildStudentDetails(),
                      ),
                    ],
                  )
                      : Column(
                    children: [
                      _buildStudentsList(),
                      SizedBox(height: 16),
                      _buildStudentDetails(),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentsList() {
    return Container(
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
          // Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Color(0xFF126666)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Students (${filteredStudents.length})',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Search Input
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF126666), width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() => searchTerm = value);
                    filterStudents();
                  },
                ),
                SizedBox(height: 12),
                // Class Filter
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedClass.isEmpty ? null : selectedClass,
                      hint: Text('All Classes'),
                      isExpanded: true,
                      items: ['', ...getUniqueClasses()]
                          .map((cls) => DropdownMenuItem(
                        value: cls,
                        child: Text(cls.isEmpty ? 'All Classes' : 'Class $cls'),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedClass = value ?? '');
                        filterStudents();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Students List
          Container(
            height: MediaQuery.of(context).size.width > 768 ? 400 : 300,
            child: loading && selectedStudent == null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF126666)),
                  SizedBox(height: 16),
                  Text('Loading students...', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
                : filteredStudents.isEmpty
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
              padding: EdgeInsets.symmetric(horizontal: 16),
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
                        student.name.isNotEmpty ? student.name.substring(0, 1).toUpperCase() : 'S',
                        style: TextStyle(
                          color: isSelected ? Color(0xFF126666) : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      safeValue(student.name),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Class: ${safeValue(student.cls)} | Roll: ${safeValue(student.studentCode)}',
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                    trailing: Text(
                      safeValue(student.contact),
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => handleStudentSelect(student),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentDetails() {
    if (selectedStudent == null) {
      return Container(
        padding: EdgeInsets.all(40),
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment, size: 64, color: Colors.grey[300]),
              SizedBox(height: 20),
              Text(
                'Select a Student',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Choose a student from the list to view their final result',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Student Info Card
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
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFF126666).withOpacity(0.1),
                    child: Icon(Icons.person, color: Color(0xFF126666)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          safeValue(selectedStudent!.name),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        Text(
                          'Student Information',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text('Roll: ${safeValue(selectedStudent!.studentCode)} | Class: ${safeValue(selectedStudent!.cls)}'),
            ],
          ),
        ),
        SizedBox(height: 16),
        // Consolidated Report Card
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Final Result',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                  ),
                  if (consolidatedReport != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: getGradeColor(consolidatedReport!.overallGrade).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: getGradeColor(consolidatedReport!.overallGrade),
                        ),
                      ),
                      child: Text(
                        '${consolidatedReport!.overallGrade} (${consolidatedReport!.overallPercentage}%)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: getGradeColor(consolidatedReport!.overallGrade),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20),
              if (loading)
                Container(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF126666)),
                        SizedBox(height: 16),
                        Text('Loading final result...', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                )
              else if (consolidatedReport == null)
                Container(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No Data Found',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No final result data available for this student',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Marks Table - Responsive
                Container(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width - 100,
                      ),
                      child: DataTable(
                        border: TableBorder.all(color: Colors.grey[300]!),
                        headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                        columnSpacing: 20,
                        horizontalMargin: 12,
                        columns: [
                          DataColumn(
                            label: Expanded(
                              child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          DataColumn(
                            label: Text('Q', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Text('H', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Text('F', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          DataColumn(
                            label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                        rows: consolidatedReport!.subjects.map((subject) => DataRow(
                          cells: [
                            DataCell(
                              Container(
                                width: 120,
                                child: Text(
                                  subject.subject,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text(subject.quarterly?['marks']?.toString() ?? 'N/A')),
                            DataCell(Text(subject.halfYearly?['marks']?.toString() ?? 'N/A')),
                            DataCell(Text(subject.finalExam?['marks']?.toString() ?? 'N/A')),
                            DataCell(Text(subject.total.toString())),
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: getGradeColor(subject.grade).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  subject.grade,
                                  style: TextStyle(
                                    color: getGradeColor(subject.grade),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )).toList(),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Download Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: downloading ? null : generateConsolidatedPDF,
                    icon: downloading
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : Icon(Icons.download),
                    label: Text(
                      downloading ? 'Generating PDF...' : 'Download Final Result',
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
            ],
          ),
        ),
      ],
    );
  }
}
