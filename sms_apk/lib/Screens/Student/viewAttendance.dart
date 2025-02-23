import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/widgets/custom_popup.dart';
import '../../utils/app_colors.dart';
import '../../widgets/user_icon.dart';

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key});

  @override
  _ViewAttendanceScreenState createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  bool masterAttendance = true;
  String? selectedClass;
  String? selectedSubject;
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  List<dynamic> attendanceData = [];
  bool isFetchingClasses = false;
  bool isFetchingAttendance = false;
  List<Map<String, dynamic>> classData = [];
  String? userName;
  String? token;

  static const String baseUrl = "s-m-s-keyw.onrender.com";

  @override
  void initState() {
    super.initState();
    fetchTokenAndData();
  }

  Future<void> fetchTokenAndData() async {
    token = await getToken();
    if (token != null) {
      fetchClassData();
      fetchUserName();
    } else {
      showPopup(context, "No token found. Please log in.", AppColors.primary);
    }
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

    if (token == null) {
      setState(() => isFetchingClasses = false);
      showPopup(context, "No token found. Please log in.", AppColors.primary);
      return;
    }

    final String apiUrl = "https://$baseUrl/class/data";
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          classData = List<Map<String, dynamic>>.from(data['classData'] ?? []);
          if (selectedClass != null &&
              !classData.any((c) => c['className'] == selectedClass)) {
            selectedClass =
                null; // Reset if previously selected class is invalid
          }
        });
      } else if (response.statusCode == 401) {
        showPopup(
            context, "Unauthorized. Please log in again.", AppColors.primary);
      } else {
        showPopup(
            context,
            "Failed to fetch class data. Status: ${response.statusCode}",
            AppColors.primary);
      }
    } catch (e) {
      showPopup(context, "Network error: $e", AppColors.primary);
    } finally {
      setState(() => isFetchingClasses = false);
    }
  }

  List<String> getSubjects() {
    if (selectedClass == null) return [];
    var selectedClassData = classData.firstWhere(
      (c) => c['className'] == selectedClass,
      orElse: () => {'subject': <String>[]},
    );
    return List<String>.from(selectedClassData['subject'] ?? []);
  }

  Future<void> fetchAttendance() async {
    if (selectedClass == null) {
      showPopup(context, "Please select a class.", AppColors.primary);
      return;
    }

    setState(() => isFetchingAttendance = true);

    if (token == null) {
      setState(() => isFetchingAttendance = false);
      showPopup(context, "No token found. Please log in.", AppColors.primary);
      return;
    }

    String formattedFromDate = DateFormat("dd/MM/yyyy").format(fromDate);
    String formattedToDate = DateFormat("dd/MM/yyyy").format(toDate);

    final Uri apiUrl = Uri.https(
      baseUrl,
      "/attendance/getAttendance",
      {
        "cls": selectedClass!,
        "fromDate": formattedFromDate,
        "toDate": formattedToDate,
        "subject": masterAttendance ? '' : (selectedSubject ?? ''),
        "masterAttendance": masterAttendance.toString(),
      },
    );

    try {
      final response = await http.post(
        apiUrl,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() => attendanceData = jsonDecode(response.body));
      } else {
        showPopup(context, "Failed to fetch attendance.", AppColors.primary);
      }
    } catch (e) {
      showPopup(context, "Error: $e", AppColors.primary);
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
          updateFromDate(picked);
        } else {
          updateToDate(picked);
        }
      });
    }
  }

  void updateFromDate(DateTime newDate) {
    setState(() {
      fromDate = newDate;
      if (toDate.isBefore(fromDate)) {
        toDate = fromDate;
      }
    });
  }

  void updateToDate(DateTime newDate) {
    if (newDate.isBefore(fromDate)) {
      showPopup(context, "To Date cannot be earlier than From Date.",
          AppColors.primary);
    } else {
      setState(() => toDate = newDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("View Attendance",
            style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: AppColors.primary,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: UserIconWidget(userName: userName ?? "Guest"),
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  masterAttendance
                      ? "Master Attendance"
                      : "Subject-wise Attendance",
                  style: TextStyle(fontSize: 18),
                ),
                Switch(
                  value: masterAttendance,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() {
                      masterAttendance = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 10),

            // Class Selection Container
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade300, blurRadius: 6)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select Class",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButton<String>(
                      value: selectedClass?.isNotEmpty == true
                          ? selectedClass
                          : null, // ✅ Safe check
                      isExpanded: true,
                      items: classData.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['className'],
                          child: Text("Class ${c['className']}"),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedClass = newValue;
                          selectedSubject =
                              null; // Reset subject when class changes
                        });
                      },
                      hint: Text(
                          "Select a class"), // ✅ Shows hint when nothing is selected
                      dropdownColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Subject Selection (only when masterAttendance is false)
            if (!masterAttendance)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade300, blurRadius: 6)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Select Subject",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: DropdownButton<String>(
                        value: selectedSubject,
                        isExpanded: true,
                        items: getSubjects().map((subject) {
                          return DropdownMenuItem<String>(
                            value: subject,
                            child: Text(subject),
                          );
                        }).toList(),
                        onChanged: selectedClass == null
                            ? null
                            : (String? newValue) {
                                setState(() {
                                  selectedSubject = newValue;
                                });
                              },
                        hint: Text("Choose a subject"),
                        dropdownColor: Colors.white,
                        disabledHint: Text("Select a class first"),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 20),

            // Date Pickers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: dateButtonStyle,
                  onPressed: () => selectDate(context, true),
                  child: Text(
                    "From: ${DateFormat('dd/MM/yyyy').format(fromDate)}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  style: dateButtonStyle,
                  onPressed: () => selectDate(context, false),
                  child: Text(
                    "To: ${DateFormat('dd/MM/yyyy').format(toDate)}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            SizedBox(height: 30),

            // Fetch Attendance Button
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

            // Attendance List
            Expanded(
              child: attendanceData.isEmpty
                  ? Center(
                      child: Text(
                        "No attendance records found.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      itemCount: attendanceData.length,
                      itemBuilder: (context, index) {
                        final entry = attendanceData[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 6),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(12),
                            title: Text(
                              "Date: ${entry['date']}",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle:
                                Text("Status: ${entry['status'] ?? 'N/A'}"),
                            leading: Icon(
                              Icons.calendar_today,
                              color: AppColors.primary,
                            ),
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
