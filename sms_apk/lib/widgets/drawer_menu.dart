import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For logout functionality
import 'package:sms_apk/Screens/notification_screen.dart';
import '../Screens/add_student.dart';
import '../Screens/homeScreen.dart';
import '../Screens/studentTableScreen.dart'; // Import StudentTableScreen
import '../Screens/viewAttendance.dart'; // Import View Attendance Screen
import '../Screens/markAttendance.dart'; // Import Mark Attendance Screen
import '../auth_screen/login.dart'; // Import LoginScreen
import '../utils/app_colors.dart'; // Import AppColors

class DrawerMenu extends StatefulWidget {
  const DrawerMenu({super.key});

  @override
  _DrawerMenuState createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  bool isStudentDropdownOpen =
      false; // State to toggle student dropdown visibility
  bool isStudentAttendanceDropdownOpen =
      false; // State to toggle attendance dropdown visibility
  bool isFacultyDropdownOpen =
      false; // State to toggle student dropdown visibility
  bool isFacultyAttendanceDropdownOpen =
      false; // State to toggle attendance dropdown visibility

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Drawer Header
            DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primary),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    'School Attendance',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Home Item
            _buildDrawerItem(Icons.home, 'Home', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            }),

            // Students Dropdown
            ListTile(
              leading: Icon(Icons.person, color: AppColors.primary),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Student',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Icon(isStudentDropdownOpen
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down),
                ],
              ),
              onTap: () {
                setState(() {
                  isStudentDropdownOpen = !isStudentDropdownOpen;
                });
              },
            ),

            // Dropdown Items with Animation
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: isStudentDropdownOpen
                  ? (isStudentAttendanceDropdownOpen ? 250 : 150)
                  : 0,
              curve: Curves.easeInOut,
              child: SingleChildScrollView(
                child: Column(
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
                    ListTile(
                      leading: Icon(Icons.fact_check, color: AppColors.primary),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Student Attendance',
                            style: TextStyle(fontSize: 14),
                          ),
                          Icon(isStudentAttendanceDropdownOpen
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          isStudentAttendanceDropdownOpen = !isStudentAttendanceDropdownOpen;
                        });
                      },
                    ),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: isStudentAttendanceDropdownOpen ? 100 : 0,
                      curve: Curves.easeInOut,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildDrawerSubItem(
                                Icons.visibility, 'View Attendance', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewAttendanceScreen(),
                                ),
                              );
                            }),
                            _buildDrawerSubItem(Icons.edit, 'Mark Attendance',
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MarkAttendanceScreen(),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Faculty Item

            ListTile(
              leading: Icon(Icons.people, color: AppColors.primary),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Faculty',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Icon(isFacultyDropdownOpen
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down),
                ],
              ),
              onTap: () {
                setState(() {
                  isFacultyDropdownOpen = !isFacultyDropdownOpen;
                });
              },
            ),

            // Dropdown Items with Animation
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: isFacultyDropdownOpen
                  ? (isFacultyAttendanceDropdownOpen ? 250 : 150)
                  : 0,
              curve: Curves.easeInOut,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDrawerSubItem(Icons.table_rows, 'Faculty Table', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentTableScreen(),
                        ),
                      );
                    }),
                    _buildDrawerSubItem(Icons.person_add, 'Add Faculty', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddStudentScreen(),
                        ),
                      );
                    }),
                    ListTile(
                      leading: Icon(Icons.fact_check, color: AppColors.primary),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Faculty Attendance',
                            style: TextStyle(fontSize: 14),
                          ),
                          Icon(isFacultyAttendanceDropdownOpen
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          isFacultyAttendanceDropdownOpen = !isFacultyAttendanceDropdownOpen;
                        });
                      },
                    ),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: isFacultyAttendanceDropdownOpen ? 100 : 0,
                      curve: Curves.easeInOut,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildDrawerSubItem(
                                Icons.visibility, 'View Attendance', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewAttendanceScreen(),
                                ),
                              );
                            }),
                            _buildDrawerSubItem(Icons.edit, 'Mark Attendance',
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MarkAttendanceScreen(),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

             // Notification
            _buildDrawerItem(Icons.notification_add, 'Notifications', () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            }),

            Divider(),

            // Logout Button
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
                SharedPreferences prefs = await SharedPreferences.getInstance();
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
    );
  }

  // Reusable Drawer Item
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

  // Reusable Drawer Sub-Item
  Widget _buildDrawerSubItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(left: 40),
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
}
