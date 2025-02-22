import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';

class StudentForm extends StatefulWidget {
  const StudentForm({super.key});

  @override
  _StudentFormState createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController classController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController totalFeeController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController motherNameController = TextEditingController();
  final TextEditingController primaryContactController =
      TextEditingController();
  final TextEditingController secondaryContactController =
      TextEditingController();
  final TextEditingController familyCityController = TextEditingController();
  final TextEditingController familyStateController = TextEditingController();
  final TextEditingController familyEmailController = TextEditingController();

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final studentData = {
      'name': nameController.text,
      'address': addressController.text,
      'city': cityController.text,
      'state': stateController.text,
      'contact': contactController.text,
      'dob': dobController.text,
      'email': emailController.text,
      'cls': classController.text,
      'department': departmentController.text,
      'category': categoryController.text,
      'totalFee': totalFeeController.text,
      'gender': genderController.text,
      'familyDetails': {
        'stdo_FatherName': fatherNameController.text,
        'stdo_MotherName': motherNameController.text,
        'stdo_primaryContact': primaryContactController.text,
        'stdo_secondaryContact': secondaryContactController.text,
        'stdo_city': familyCityController.text,
        'stdo_state': familyStateController.text,
        'stdo_email': familyEmailController.text,
      }
    };
    

    try {
      final token = await getToken();
      if (token == null) {
        showSnackbar('No token found. Please log in.');
        return;
      }

      final response = await http.post(
        Uri.parse('https://s-m-s-keyw.onrender.com/student/save'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(studentData),
      );

      if (response.statusCode == 200) {
        showSnackbar('Student added successfully!');
        Navigator.pop(context);
      } else {
        showSnackbar('Failed to add student: ${response.body}');
      }
    } catch (e) {
      showSnackbar('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildCard('Student Details', [
                buildInputField(nameController, 'Student Name', true),
                buildInputField(addressController, 'Address', true),
                buildInputField(cityController, 'City', true),
                buildInputField(genderController, 'Gender', true),
                buildInputField(stateController, 'State', true),
                buildInputField(contactController, 'Contact', true),
                buildInputField(dobController, 'Date of Birth', true),
                buildInputField(emailController, 'Email', true),
                buildInputField(classController, 'Class', true),
                buildInputField(departmentController, 'Department', true),
                buildInputField(categoryController, 'Category', false),
                buildInputField(totalFeeController, 'Total Fee', true,
                    isNumber: true),
              ]),
              buildCard('Family Details', [
                buildInputField(fatherNameController, "Father's Name", false),
                buildInputField(motherNameController, "Mother's Name", false),
                buildInputField(
                    primaryContactController, 'Primary Contact', false),
                buildInputField(
                    secondaryContactController, 'Secondary Contact', false),
                buildInputField(familyCityController, 'Family City', false),
                buildInputField(familyStateController, 'Family State', false),
                buildInputField(familyEmailController, 'Family Email', false),
              ]),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isLoading ? null : submitForm,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Submit', style: TextStyle(color: Colors.white,fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInputField(
      TextEditingController controller, String label, bool required,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget buildCard(String title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}
