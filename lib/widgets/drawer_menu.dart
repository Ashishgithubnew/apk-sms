import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/Screens/Faculty/FacultyTableScreen.dart';
import 'package:sms_apk/Screens/Faculty/add_faculty.dart';
import 'package:sms_apk/Screens/Faculty/mark_attendance.dart';
import 'package:sms_apk/Screens/Faculty/view_attendance.dart';
import 'package:sms_apk/Screens/Finance/fees_page.dart';
import 'package:sms_apk/Screens/Finance/student_fees_screen.dart';
import 'package:sms_apk/Screens/Finance/Faculty_Salary_Screen.dart';
import 'package:sms_apk/Screens/notification_screen.dart';
import 'package:sms_apk/Screens/holiday_screen.dart';
import 'package:sms_apk/Screens/studentreport_screen.dart';
import '../Screens/Student/add_student.dart';
import '../Screens/homeScreen.dart';
import '../Screens/Student/studentTableScreen.dart';
import '../Screens/subject_show_screen.dart';
import '../Screens/Student/viewAttendance.dart';
import '../Screens/Student/markAttendance.dart';
import '../Screens/finance/permission_management.dart';
import '../Screens/Syllabus/UploadSyllabus_screen.dart';
import '../auth_screen/login.dart';
import '../utils/app_colors.dart';

// Added this minimal StatefulWidget wrapper for your existing state class:
class DrawerMenu extends StatefulWidget {
  const DrawerMenu({Key? key}) : super(key: key);

  @override
  _DrawerMenuState createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  bool isStudentDropdownOpen = false;
  bool isStudentAttendanceDropdownOpen = false;
  bool isFacultyDropdownOpen = false;
  bool isFacultyAttendanceDropdownOpen = false;
  bool isFinanceDropdownOpen = false; // <-- added this
  bool isSyllabusDropdownOpen = false; // <-- added this

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
              _buildExpandableSection(
                title: 'Student',
                isExpanded: isStudentDropdownOpen,
                onTap: () {
                  setState(() {
                    isStudentDropdownOpen = !isStudentDropdownOpen;
                  });
                },
                children: [
                  _buildDrawerSubItem(Icons.table_rows, 'Student Table', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentTableScreen(),
                      ),
                    );
                  }),
                  _buildDrawerSubItem(Icons.person_add, 'Add Student', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddStudentScreen(),
                      ),
                    );
                  }),
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
                      _buildDrawerSubItem(Icons.visibility, 'View Attendance',
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewAttendanceScreen(),
                          ),
                        );
                      }),
                      _buildDrawerSubItem(Icons.edit, 'Mark Attendance', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MarkAttendanceScreen(),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
              _buildExpandableSection(
                title: 'Faculty',
                isExpanded: isFacultyDropdownOpen,
                onTap: () {
                  setState(() {
                    isFacultyDropdownOpen = !isFacultyDropdownOpen;
                  });
                },
                children: [
                  _buildDrawerSubItem(Icons.table_rows, 'Faculty Table', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FacultyTableScreen(),
                      ),
                    );
                  }),
                  _buildDrawerSubItem(Icons.person_add, 'Add Faculty', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FacultyDetailsForm(),
                      ),
                    );
                  }),
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
                      _buildDrawerSubItem(Icons.visibility, 'View Attendance',
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewAttendance(),
                          ),
                        );
                      }),
                      _buildDrawerSubItem(Icons.edit, 'Mark Attendance', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MarkAttendance(),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
              _buildExpandableSection(
                title: 'Finance',
                isExpanded: isFinanceDropdownOpen, // <-- use finance bool here
                onTap: () {
                  setState(() {
                    isFinanceDropdownOpen =
                        !isFinanceDropdownOpen; // toggle finance
                  });
                },
                children: [
                  _buildDrawerSubItem(Icons.table_rows, 'Class Fees', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FeesPage(),
                      ),
                    );
                  }),
                  _buildDrawerSubItem(Icons.table_rows, 'Student Fees', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentFeesScreen(),
                      ),
                    );
                  }),
                  _buildDrawerSubItem(Icons.table_rows, 'Faculty Salary', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FacultySalaryScreen(),
                      ),
                    );
                  }),
                  _buildDrawerSubItem(Icons.table_rows, 'Permission', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PermissionManagement(),
                      ),
                    );
                  }),
                ],
              ),
              _buildExpandableSection(
                title: 'Syllabus',
                isExpanded: isSyllabusDropdownOpen, // <-- use finance bool here
                onTap: () {
                  setState(() {
                    isSyllabusDropdownOpen =
                        !isSyllabusDropdownOpen; // toggle finance
                  });
                },
                children: [
                  _buildDrawerSubItem(Icons.table_rows, 'Upload Syllabus', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UploadSyllabusScreen(),
                      ),
                    );
                  }),
                  _buildDrawerSubItem(Icons.table_rows, 'View Syllabus', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FacultySalaryScreen(),
                      ),
                    );
                  }),
                ],
              ),
              _buildDrawerItem(Icons.notification_add, 'Notifications', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationPage()),
                );
              }),
              _buildDrawerItem(Icons.beach_access, 'Holiday', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HolidayPage()),
                );
              }),
              _buildDrawerItem(Icons.book, 'Subject', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ClassSubjectShow()),
                );
              }),
              _buildDrawerItem(Icons.assessment, 'Student Report', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudentReportForm()),
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
                    color: AppColors.logout,
                  ),
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
