import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../widgets/user_icon.dart';
import '../widgets/class_subject_selection.dart';

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key});

  @override
  _ViewAttendanceScreenState createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  bool masterAttendance = false;
  String? selectedClass;
  String? selectedSubject;
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  List<dynamic> attendanceData = [];
  bool isFetchingClasses = false;
  bool isFetchingAttendance = false;
  List<Map<String, dynamic>> classData = [];
  String? userName;

  @override
  void initState() {
    super.initState();
    fetchClassData();
    fetchUserName();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> fetchUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName');
    });
  }

  Future<void> fetchClassData() async {
    setState(() => isFetchingClasses = true);
    final token = await getToken();
    if (token == null) {
      showPopup("No token found. Please log in.");
      return;
    }
    final String apiUrl = "https://s-m-s-keyw.onrender.com/class/data";
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          classData = List<Map<String, dynamic>>.from(data['classData'] ?? []);
          if (classData.isNotEmpty) {
            selectedClass = classData[0]['className'];
          }
        });
      } else {
        showPopup("Failed to fetch class data.");
      }
    } catch (e) {
      showPopup("Error: $e");
    } finally {
      setState(() => isFetchingClasses = false);
    }
  }

  List<String> getSubjects() {
    if (selectedClass == null) return [];
    var selectedClassData = classData.firstWhere(
      (c) => c['className'] == selectedClass,
      orElse: () => {'subject': []},
    );
    return List<String>.from(selectedClassData['subject'] ?? []);
  }

  Future<void> fetchAttendance() async {
    if (selectedClass == null) {
      showPopup("Please select a class.");
      return;
    }
    setState(() => isFetchingAttendance = true);
    final token = await getToken();
    if (token == null) {
      showPopup("No token found. Please log in.");
      return;
    }
    String formattedFromDate = DateFormat("dd/MM/yyyy").format(fromDate);
    String formattedToDate = DateFormat("dd/MM/yyyy").format(toDate);
    final String apiUrl =
        "https://s-m-s-keyw.onrender.com/attendance/getAttendance"
        "?cls=$selectedClass"
        "&fromDate=$formattedFromDate"
        "&toDate=$formattedToDate"
        "&subject=${masterAttendance ? '' : selectedSubject}"
        "&masterAttendance=$masterAttendance";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        setState(() => attendanceData = jsonDecode(response.body));
      } else {
        showPopup("Failed to fetch attendance.");
      }
    } catch (e) {
      showPopup("Error: $e");
    } finally {
      setState(() => isFetchingAttendance = false);
    }
  }

  Future<void> selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? fromDate : toDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.dark(primary: AppColors.primary),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
          if (toDate.isBefore(fromDate)) {
            toDate = fromDate; // Adjust To Date if needed
          }
        } else {
          if (picked.isBefore(fromDate)) {
            showPopup("To Date cannot be earlier than From Date.");
          } else {
            toDate = picked;
          }
        }
      });
    }
  }

  void showPopup(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents accidental dismissals
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: AppColors.primary,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info, color: Colors.white, size: 40),
                SizedBox(height: 10),
                Text(
                  "Notification",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child:
                      Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("View Attendance", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: UserIconWidget(userName: "Aditya Sharma"),
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClassSubjectSelection(),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: fromDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() => fromDate = pickedDate);
                    }
                  },
                  child: Text(
                    "From: ${DateFormat('dd/MM/yyyy').format(fromDate)}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: toDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() => toDate = pickedDate);
                    }
                  },
                  child: Text(
                    "To: ${DateFormat('dd/MM/yyyy').format(toDate)}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  elevation: 5,
                ),
                onPressed: isFetchingAttendance ? null : fetchAttendance,
                child: isFetchingAttendance
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        "Fetch Attendance",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: attendanceData.isEmpty
                  ? Center(child: Text("No attendance records found."))
                  : ListView.builder(
                      itemCount: attendanceData.length,
                      itemBuilder: (context, index) {
                        final entry = attendanceData[index];
                        return Card(
                          child: ListTile(
                            title: Text("Date: ${entry['date']}",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
