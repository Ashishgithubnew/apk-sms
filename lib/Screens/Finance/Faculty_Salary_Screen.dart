import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'AddFacultySalaryScreen.dart'; // Import the new screen

class FacultySalaryScreen extends StatefulWidget {
  const FacultySalaryScreen({super.key});

  @override
  State<FacultySalaryScreen> createState() => _FacultySalaryScreenState();
}

class _FacultySalaryScreenState extends State<FacultySalaryScreen> {
  List<dynamic> facultyList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFacultyData();
  }
   Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }


  Future<void> fetchFacultyData() async {
       final token = await getToken();
    final url = Uri.parse("https://s-m-s-keyw.onrender.com/faculty/findAllFaculty");
    final response = await http.get(url,
     headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
    );

    if (response.statusCode == 200) {
      setState(() {
        facultyList = json.decode(response.body);
        isLoading = false;
      });
    } else {
      // Handle error
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faculty Salary')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('S.No')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Faculty Name')),
                  DataColumn(label: Text('Salary')),
                  DataColumn(label: Text('Tax %')),
                  DataColumn(label: Text('Transport Allowance')),
                  DataColumn(label: Text('Deductions')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('View Details')),
                ],
                rows: List.generate(facultyList.length, (index) {
  final faculty = facultyList[index];
  final salaryList = faculty['fact_salary'];
  // Ensure salaryList is not null before checking if it's empty
  final latestSalary = (salaryList != null && salaryList.isNotEmpty) ? salaryList.last : null;

  // Calculate total deduction from facultyDeduction list
  double totalDeduction = 0.0;
  if (latestSalary != null && latestSalary['facultyDeduction'] is List) {
    for (var deduction in latestSalary['facultyDeduction']) {
      if (deduction['amount'] is num) {
        totalDeduction += (deduction['amount'] as num).toDouble();
      }
    }
  }


  return DataRow(cells: [
    DataCell(Text('${index + 1}')),
    DataCell(Text(faculty['fact_email'] ?? '')),
    DataCell(Text(faculty['fact_Name'] ?? '')),
    DataCell(Text(latestSalary != null ? '${latestSalary['facultySalary']}' : '0')),
    DataCell(Text(latestSalary != null ? '${latestSalary['facultyTax']}' : '0')),
    DataCell(Text(latestSalary != null ? '${latestSalary['facultyTransport']}' : '0')),
    DataCell(Text(latestSalary != null ? '${totalDeduction.toStringAsFixed(2)}' : '0')), // Display total deduction
    DataCell(Text(latestSalary != null ? '${latestSalary['total']}' : '0')),
    DataCell(
      IconButton(
        icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Faculty Details"),
              content: Text(
                "Name: ${faculty['fact_Name']}\n"
                "Email: ${faculty['fact_email']}\n"
                "Salary: ${latestSalary?['facultySalary'] ?? 'N/A'}\n"
                "Tax: ${latestSalary?['facultyTax'] ?? 'N/A'}\n"
                "Transport: ${latestSalary?['facultyTransport'] ?? 'N/A'}\n"
                "Deductions: ${totalDeduction.toStringAsFixed(2)}\n" // Show total deduction in details
                "Total: ${latestSalary?['total'] ?? 'N/A'}",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                )
              ],
            ),
          );
        },
      ),
    ),
  ]);
}),

              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddFacultySalaryScreen()),
          );
          if (result == true) {
            // If salary was added successfully, refresh the list
            fetchFacultyData();
          }
        },
        child: const Icon(Icons.add),
        tooltip: "Add Salary",
      ),
    );
  }
}