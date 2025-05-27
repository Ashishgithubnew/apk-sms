import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Import the new screen (now they are in the same directory)
import 'add_fees_screen.dart';

class StudentFeesScreen extends StatefulWidget {
  const StudentFeesScreen({Key? key}) : super(key: key);

  @override
  State<StudentFeesScreen> createState() => _StudentFeesScreenState();
}

class _StudentFeesScreenState extends State<StudentFeesScreen> {
  late Future<List<Student>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _studentsFuture = fetchStudents();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<List<Student>> fetchStudents() async {
    final token = await getToken();
    final url = Uri.parse('https://s-m-s-keyw.onrender.com/student/findAllStudent');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Student.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load students');
    }
  }

  void _navigateToAddFeesScreen() async {
    // Before navigating, ensure any active text field loses focus
    FocusScope.of(context).unfocus();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFeesScreen()),
    );

    // If a fee was successfully added (result is true), refresh the student list
    if (result == true) {
      setState(() {
        _studentsFuture = fetchStudents();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Fees'),
      ),
      body: FutureBuilder<List<Student>>(
        future: _studentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No students found'));
          }

          final students = snapshot.data!;
          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: ListTile(
                  title: Text(student.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Class: ${student.cls ?? 'N/A'}'),
                      Text('Total Fee: ₹${student.totalFee.toStringAsFixed(2)}'),
                      Text('Remaining Fees: ₹${student.remainingFees.toStringAsFixed(2)}'),
                      Text('Status: ${student.status}'),
                    ],
                  ),
                  trailing: const Icon(Icons.payment),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddFeesScreen,
        label: const Text('Add Student Fees'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// Student and FamilyDetails classes remain in this file
class Student {
  final String id;
  final DateTime creationDateTime;
  final String name;
  final String? address;
  final String? city;
  final String? state;
  final FamilyDetails? familyDetails;
  final String? contact;
  final String? gender;
  final DateTime? dob;
  final String? email;
  final String? cls;
  final String? department;
  final String? category;
  final String? admissionClass;
  final DateTime? endDate;
  final double totalFee;
  final double remainingFees;
  final String? studentCode;
  final String? status;
  // feeInfo and reportCardEntities are empty lists in your example, so omitted here

  Student({
    required this.id,
    required this.creationDateTime,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.familyDetails,
    this.contact,
    this.gender,
    this.dob,
    this.email,
    this.cls,
    this.department,
    this.category,
    this.admissionClass,
    this.endDate,
    required this.totalFee,
    required this.remainingFees,
    this.studentCode,
    this.status,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      creationDateTime: DateTime.parse(json['creationDateTime']),
      name: json['name'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      familyDetails: json['familyDetails'] != null
          ? FamilyDetails.fromJson(json['familyDetails'])
          : null,
      contact: json['contact'],
      gender: json['gender'],
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      email: json['email'],
      cls: json['cls'],
      department: json['department'],
      category: json['category'],
      admissionClass: json['admissionClass'],
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      totalFee: (json['totalFee'] is int) ? (json['totalFee'] as int).toDouble() : (json['totalFee'] ?? 0).toDouble(),
      remainingFees: (json['remainingFees'] is int) ? (json['remainingFees'] as int).toDouble() : (json['remainingFees'] ?? 0).toDouble(),
      studentCode: json['studentCode'],
      status: json['status'],
    );
  }
}

class FamilyDetails {
  final String? stdo_FatherName;
  final String? stdo_MotherName;
  final String? stdo_primaryContact;
  final String? stdo_secondaryContact;
  final String? stdo_address;
  final String? stdo_city;
  final String? stdo_state;
  final String? stdo_email;

  FamilyDetails({
    this.stdo_FatherName,
    this.stdo_MotherName,
    this.stdo_primaryContact,
    this.stdo_secondaryContact,
    this.stdo_address,
    this.stdo_city,
    this.stdo_state,
    this.stdo_email,
  });

  factory FamilyDetails.fromJson(Map<String, dynamic> json) {
    return FamilyDetails(
      stdo_FatherName: json['stdo_FatherName'],
      stdo_MotherName: json['stdo_MotherName'],
      stdo_primaryContact: json['stdo_primaryContact'],
      stdo_secondaryContact: json['stdo_secondaryContact'],
      stdo_address: json['stdo_address'],
      stdo_city: json['stdo_city'],
      stdo_state: json['stdo_state'],
      stdo_email: json['stdo_email'],
    );
  }
}