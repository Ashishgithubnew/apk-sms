import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'add_student_form.dart';

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
      home: LoginScreen(),
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
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

        // Save token in SharedPreferences
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
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: login,
                    child: Text('Login'),
                  ),
          ],
        ),
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
                    MaterialPageRoute(builder: (context) => StudentTableScreen()),
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
          SnackBar(content: Text('Failed to load students: ${response.statusCode}')),
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
          SnackBar(content: Text('Failed to delete student: ${response.statusCode}')),
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
          SnackBar(content: Text('Failed to update student: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void showEditDialog(Map<String, dynamic> student) {
    final nameController = TextEditingController(text: student['name']);
    final cityController = TextEditingController(text: student['city']);
    final stateController = TextEditingController(text: student['state']);
    final contactController = TextEditingController(text: student['contact']);
    final departmentController = TextEditingController(text: student['department']);
    final clsController = TextEditingController(text: student['cls']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Student'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
                TextField(controller: cityController, decoration: InputDecoration(labelText: 'City')),
                TextField(controller: stateController, decoration: InputDecoration(labelText: 'State')),
                TextField(controller: contactController, decoration: InputDecoration(labelText: 'Contact')),
                TextField(controller: departmentController, decoration: InputDecoration(labelText: 'Department')),
                TextField(controller: clsController, decoration: InputDecoration(labelText: 'Class')),
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
                student['state'] = stateController.text;
                student['contact'] = contactController.text;
                student['department'] = departmentController.text;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Table')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? Center(child: Text('No data available'))
              : SingleChildScrollView(
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
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => showEditDialog(student),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => deleteStudent(student['id']),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}