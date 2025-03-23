import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/widgets/header.dart';
import '../../auth_screen/login.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_popup.dart';

class StudentTableScreen extends StatefulWidget {
  const StudentTableScreen({super.key});

  @override
  _StudentTableScreenState createState() => _StudentTableScreenState();
}

class _StudentTableScreenState extends State<StudentTableScreen> {
  List<dynamic> students = [];
  List<dynamic> filteredStudents = [];
  bool isLoading = true;
  String? token;
  String? selectedClass;
  List<String> classes = [];

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
      showPopup(context, 'Token not found. Please log in again.', Colors.red);
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
        List<dynamic> studentList = json.decode(response.body);

        setState(() {
          students = studentList;
          filteredStudents = students;
          classes = studentList
              .map<String>((student) => student['cls'].toString())
              .toSet()
              .toList();
          classes.sort((a, b) => compareClassNames(a, b)); // Sort classes here
        });
      } else {
        showPopup(context, 'Failed to load students', Colors.red);
      }
    } catch (e) {
      showPopup(context, 'Error: $e', Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Custom sorting function for class names
  int compareClassNames(String classA, String classB) {
    // Define priority order for special classes
    List<String> priorityClasses = ["Nursery", "LKG", "UKG"];

    int indexA = priorityClasses.indexOf(classA);
    int indexB = priorityClasses.indexOf(classB);

    // If both classes are in the priority list, sort by their order in the list
    if (indexA != -1 && indexB != -1) {
      return indexA.compareTo(indexB);
    }

    // If only classA is in the priority list, it should come first
    if (indexA != -1) return -1;

    // If only classB is in the priority list, it should come first
    if (indexB != -1) return 1;

    // Regular sorting for remaining classes
    RegExp regex = RegExp(r'(\d+)|(\D+)');
    Iterable<RegExpMatch> matchesA = regex.allMatches(classA);
    Iterable<RegExpMatch> matchesB = regex.allMatches(classB);

    List<String> partsA = matchesA.map((m) => m.group(0)!).toList();
    List<String> partsB = matchesB.map((m) => m.group(0)!).toList();

    int minLength =
        partsA.length < partsB.length ? partsA.length : partsB.length;

    for (int i = 0; i < minLength; i++) {
      if (RegExp(r'^\d+$').hasMatch(partsA[i]) &&
          RegExp(r'^\d+$').hasMatch(partsB[i])) {
        int numA = int.parse(partsA[i]);
        int numB = int.parse(partsB[i]);
        if (numA != numB) return numA.compareTo(numB);
      } else {
        int result = partsA[i].compareTo(partsB[i]);
        if (result != 0) return result;
      }
    }

    return partsA.length.compareTo(partsB.length);
  }

  void filterStudentsByClass(String? selectedClass) {
    setState(() {
      this.selectedClass = selectedClass;
      if (selectedClass == null || selectedClass.isEmpty) {
        filteredStudents = students;
      } else {
        filteredStudents = students
            .where((student) => student['cls'] == selectedClass)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: Header(text: "Student Table"),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
              color: AppColors.primary,
            ))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedClass,
                    decoration: InputDecoration(
                      labelText: "Select Class",
                      labelStyle:
                          TextStyle(color: Colors.grey), // Default label color
                      floatingLabelStyle: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                            color: AppColors.primary), // Use your theme color
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                            color: AppColors.secondary,
                            width: 2), // Highlight effect
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                    ),
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    icon: Icon(Icons.arrow_drop_down,
                        color: AppColors.primary), // Custom dropdown icon
                    items: classes.map((String cls) {
                      return DropdownMenuItem<String>(
                        value: cls,
                        child: Text(
                          cls,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                    onChanged: filterStudentsByClass,
                  ),
                ),
                Expanded(
                  child: filteredStudents.isEmpty
                      ? Center(child: Text('No data available'))
                      : ListView.builder(
                          itemCount: filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = filteredStudents[index];
                            return Card(
                              color: Colors.white,
                              shadowColor: AppColors.primary,
                              elevation: 4,
                              margin: EdgeInsets.all(8.0),
                              child: ListTile(
                                title: Text(student['name'] ?? 'N/A',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('City: ${student['city'] ?? 'N/A'}'),
                                    Text(
                                        'Contact: ${student['contact'] ?? 'N/A'}'),
                                    Text('Class: ${student['cls'] ?? 'N/A'}'),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete,
                                      color: AppColors.primary),
                                  onPressed: () =>
                                      confirmDeleteStudent(student['id']),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> confirmDeleteStudent(String id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Student"),
          content: Text("Are you sure you want to delete this student?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: AppColors.primary)),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pop(context);
                deleteStudent(id);
              },
              child: Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
          filterStudentsByClass(selectedClass);
        });
        showPopup(context, 'Student deleted successfully', Colors.green);
      } else {
        showPopup(context, 'Failed to delete student', Colors.red);
      }
    } catch (e) {
      showPopup(context, 'Error: $e', Colors.red);
    }
  }
}
