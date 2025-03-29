import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:sms_apk/Screens/Faculty/FacultyTableScreen.dart';
import 'package:sms_apk/Screens/Faculty/add_faculty.dart';
import 'package:sms_apk/Screens/Faculty/mark_attendance.dart';
import 'package:sms_apk/Screens/Faculty/view_attendance.dart';
import 'package:sms_apk/Screens/notification_screen.dart';
import '../Screens/Student/add_student.dart';
import '../Screens/homeScreen.dart';
import '../Screens/Student/studentTableScreen.dart';
import '../Screens/Student/viewAttendance.dart';
import '../Screens/Student/markAttendance.dart';
import '../auth_screen/login.dart';
import '../utils/app_colors.dart';

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({super.key});

  @override
  _DrawerMenuState createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  bool isStudentDropdownOpen = false;
  bool isStudentAttendanceDropdownOpen = false;
  bool isFacultyDropdownOpen = false;
  bool isFacultyAttendanceDropdownOpen = false;

  // Permissions variables
  bool canViewStudentTable = false;
  bool canAddStudent = false;
  bool canViewStudentAttendance = false;
  bool canMarkStudentAttendance = false;

  bool canViewFacultyTable = false;
  bool canAddFaculty = false;
  bool canViewFacultyAttendance = false;
  bool canMarkFacultyAttendance = false;

  bool canViewNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? permissionsJson = prefs.getString('permissions');

    if (permissionsJson != null) {
      Map<String, dynamic> permissions = json.decode(permissionsJson);

      setState(() {
        // Student Permissions
        canViewStudentTable =
            permissions['student']?['studentDetails'] ?? false;
        canAddStudent =
            permissions['student']?['studentRegistrationController'] ?? false;
        canViewStudentAttendance =
            permissions['student']?['studentAttendanceShow'] ?? false;
        canMarkStudentAttendance =
            permissions['student']?['studentAttendance'] ?? false;

        // Faculty Permissions
        canViewFacultyTable =
            permissions['faculty']?['facultyDetails'] ?? false;
        canAddFaculty =
            permissions['faculty']?['facultyRegistrationForm'] ?? false;
        canViewFacultyAttendance =
            permissions['faculty']?['facultyAttendanceShow'] ?? false;
        canMarkFacultyAttendance =
            permissions['faculty']?['facultyAttendanceSave'] ?? false;

        // Notification Permissions
        canViewNotifications =
            permissions['notification']?['notificationList'] ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E7878),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/ews-full-white.png',
                        height: 70,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerItem(Icons.home, 'Home', () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              }),

              // Student Section
              if (canViewStudentTable ||
                  canAddStudent ||
                  canViewStudentAttendance ||
                  canMarkStudentAttendance)
                _buildExpandableSection(
                  title: 'Student',
                  isExpanded: isStudentDropdownOpen,
                  onTap: () {
                    setState(() {
                      isStudentDropdownOpen = !isStudentDropdownOpen;
                    });
                  },
                  children: [
                    if (canViewStudentTable)
                      _buildDrawerSubItem(Icons.table_rows, 'Student Table',
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => StudentTableScreen()),
                        );
                      }),
                    if (canAddStudent)
                      _buildDrawerSubItem(Icons.person_add, 'Add Student', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AddStudentScreen()),
                        );
                      }),
                    if (canViewStudentAttendance || canMarkStudentAttendance)
                      _buildExpandableSection(
                        title: 'Student Attendance',
                        isExpanded: isStudentAttendanceDropdownOpen,
                        onTap: () {
                          setState(() {
                            isStudentAttendanceDropdownOpen =
                                !isStudentAttendanceDropdownOpen;
                          });
                        },
                        children: [
                          if (canViewStudentAttendance)
                            _buildDrawerSubItem(
                                Icons.visibility, 'View Attendance', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ViewAttendanceScreen()),
                              );
                            }),
                          if (canMarkStudentAttendance)
                            _buildDrawerSubItem(Icons.edit, 'Mark Attendance',
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        MarkAttendanceScreen()),
                              );
                            }),
                        ],
                      ),
                  ],
                ),

              // Faculty Section
              if (canViewFacultyTable ||
                  canAddFaculty ||
                  canViewFacultyAttendance ||
                  canMarkFacultyAttendance)
                _buildExpandableSection(
                  title: 'Faculty',
                  isExpanded: isFacultyDropdownOpen,
                  onTap: () {
                    setState(() {
                      isFacultyDropdownOpen = !isFacultyDropdownOpen;
                    });
                  },
                  children: [
                    if (canViewFacultyTable)
                      _buildDrawerSubItem(Icons.table_rows, 'Faculty Table',
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FacultyTableScreen()),
                        );
                      }),
                    if (canAddFaculty)
                      _buildDrawerSubItem(Icons.person_add, 'Add Faculty', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const FacultyDetailsForm()),
                        );
                      }),
                    if (canViewFacultyAttendance || canMarkFacultyAttendance)
                      _buildExpandableSection(
                        title: 'Faculty Attendance',
                        isExpanded: isFacultyAttendanceDropdownOpen,
                        onTap: () {
                          setState(() {
                            isFacultyAttendanceDropdownOpen =
                                !isFacultyAttendanceDropdownOpen;
                          });
                        },
                        children: [
                          if (canViewFacultyAttendance)
                            _buildDrawerSubItem(
                                Icons.visibility, 'View Attendance', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ViewAttendance()),
                              );
                            }),
                          if (canMarkFacultyAttendance)
                            _buildDrawerSubItem(Icons.edit, 'Mark Attendance',
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => MarkAttendance()),
                              );
                            }),
                        ],
                      ),
                  ],
                ),

              // Notification Section
              if (canViewNotifications)
                _buildDrawerItem(Icons.notification_add, 'Notifications', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationPage()),
                  );
                }),

              const Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: AppColors.logout),
                title: Text(
                  'Logout',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.logout),
                ),
                onTap: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.remove('authToken');
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDrawerSubItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: TextStyle(fontSize: 14),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.person, color: AppColors.primary),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Icon(isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down),
            ],
          ),
          onTap: onTap,
        ),
        if (isExpanded) ...children,
      ],
    );
  }
}
