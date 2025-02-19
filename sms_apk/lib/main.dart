import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/AttendanceScreen.dart';
import 'package:sms_apk/FacultyAttendanceApp.dart';
import 'package:sms_apk/WatchAttendanceScreen.dart';
import 'add_student_form.dart';
import 'FacultyTableScreen.dart';
import 'facultyDetailsForm.dart';
import 'package:sms_apk/StudentAttendanceScreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyWaySolution',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WelcomePage(),
    );
  }
}

//home Screen
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              '../assets/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Blur Effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          // Welcome Text and Button
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Welcome to Easy Way Solution",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://s-m-s-keyw.onrender.com/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Successful')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              '../assets/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      hintText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      hintText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Login',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Home Screen
class HomeScreen extends StatelessWidget {
  Future<void> logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken'); // Remove the token from storage

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged out successfully!')),
    );

    // Redirect the user to the Login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('EasyWaySolution')),
      body: Row(
        children: [
          NavigationDrawer(onLogout: () => logout(context)),
          Expanded(
            child: Center(child: Text('Welcome to EasyWaySolution!')),
          ),
        ],
      ),
    );
  }
}

// Navigation Drawer

class NavigationDrawer extends StatelessWidget {
  final VoidCallback onLogout;

  NavigationDrawer({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(child: Text('EasyWaySolution')),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ExpansionTile(
            leading: Icon(Icons.person),
            title: Text('Student'),
            children: [
              ListTile(
                leading: Icon(Icons.table_chart),
                title: Text('Student Table'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => StudentTableScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Add Student'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddStudentForm()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Student Attendance view'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => StudentAttendanceScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Student  AttendanceScreen'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AttendanceScreen()),
                  );
                },
              ),
            ],
          ),
          ExpansionTile(
            leading: Icon(Icons.person),
            title: Text('Faculty'),
            children: [
              ListTile(
                leading: Icon(Icons.group),
                title: Text('Faculty'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FacultyTableScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Add faculty'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FacultyDetailsForm()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Faculty Attendance'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FacultyAttendanceApp()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.add),
                title: Text('Faculty Attendence View'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => WatchAttendanceScreen()),
                  );
                },
              ),
            ],
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

// Student Table Screen
class StudentTableScreen extends StatefulWidget {
  @override
  _StudentTableScreenState createState() => _StudentTableScreenState();
}

class _StudentTableScreenState extends State<StudentTableScreen> {
  List<dynamic> students = [];
  bool isLoading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    fetchTokenAndStudents();
  }

  Future<void> fetchTokenAndStudents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('authToken');
    if (token != null) {
      fetchStudents();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token not found. Please log in again.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  Future<void> fetchStudents() async {
    try {
      final response = await http.get(
        Uri.parse('https://s-m-s-keyw.onrender.com/student/findAllStudent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          students = json.decode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load students: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      final response = await http.post(
        Uri.parse('https://s-m-s-keyw.onrender.com/student/delete?id=$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          students.removeWhere((student) => student['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to delete student: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> editStudent(Map<String, dynamic> student) async {
    try {
      final response = await http.post(
        Uri.parse('https://s-m-s-keyw.onrender.com/student/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(student),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Student updated successfully')),
        );
        fetchStudents(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to update student: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Table')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? Center(child: Text('No data available'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Check screen width to adjust layout
                    if (constraints.maxWidth < 600) {
                      // Small screen (e.g., mobile)
                      return ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return Card(
                            margin: EdgeInsets.all(8.0),
                            child: ListTile(
                              title: Text(student['name'] ?? 'N/A'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('City: ${student['city'] ?? 'N/A'}'),
                                  Text(
                                      'Contact: ${student['contact'] ?? 'N/A'}'),
                                  Text('Class: ${student['cls'] ?? 'N/A'}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => showEditDialog(student),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () =>
                                        deleteStudent(student['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      // Large screen (e.g., tablet, desktop)
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('City')),
                            DataColumn(label: Text('Contact')),
                            DataColumn(label: Text('Class')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: students.map((student) {
                            return DataRow(
                              cells: [
                                DataCell(Text(student['id'] ?? 'N/A')),
                                DataCell(Text(student['name'] ?? 'N/A')),
                                DataCell(Text(student['city'] ?? 'N/A')),
                                DataCell(Text(student['contact'] ?? 'N/A')),
                                DataCell(Text(student['cls'] ?? 'N/A')),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () =>
                                            showEditDialog(student),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            deleteStudent(student['id']),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    }
                  },
                ),
    );
  }

  void showEditDialog(Map<String, dynamic> student) {
    final nameController = TextEditingController(text: student['name']);
    final cityController = TextEditingController(text: student['city']);
    final contactController = TextEditingController(text: student['contact']);
    final clsController = TextEditingController(text: student['cls']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Student'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name')),
                TextField(
                    controller: cityController,
                    decoration: InputDecoration(labelText: 'City')),
                TextField(
                    controller: contactController,
                    decoration: InputDecoration(labelText: 'Contact')),
                TextField(
                    controller: clsController,
                    decoration: InputDecoration(labelText: 'Class')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                student['name'] = nameController.text;
                student['city'] = cityController.text;
                student['contact'] = contactController.text;
                student['cls'] = clsController.text;
                editStudent(student);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
