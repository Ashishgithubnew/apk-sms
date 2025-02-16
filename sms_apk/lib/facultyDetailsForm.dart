import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FacultyDetailsForm extends StatefulWidget {
  const FacultyDetailsForm({super.key});

  @override
  _FacultyDetailsFormState createState() => _FacultyDetailsFormState();
}

class _FacultyDetailsFormState extends State<FacultyDetailsForm> {
  final _formKey = GlobalKey<FormState>();

  // Form data
  String fullName = "";
  String email = "";
  String factEmail = "";
  String password = "";
  String contact = "";
  String gender = "";
  String address = "";
  String city = "";
  String state = "";
  String factStatus = "";
  String? token;

  // Controllers for date fields
  final TextEditingController _joiningDateController = TextEditingController();
  final TextEditingController _leavingDateController = TextEditingController();

  List<Map<String, String>> qualifications = [
    {"type": "", "grd_sub": "", "grd_branch": "", "grd_grade": "", "grd_university": "", "grd_yearOfPassing": ""}
  ];

  List<Map<String, dynamic>> factClasses = [
    {"cls_name": "", "cls_sub": [""]}
  ];

  @override
  void initState() {
    super.initState();
    fetchToken();
  }

  // Fetch token from SharedPreferences
  Future<void> fetchToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('authToken');
    });
  }

  // Date picker helper
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Submit Form with Token Authentication
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Authentication token is missing. Please log in again.")),
        );
        return;
      }

      final url = Uri.parse("https://s-m-s-keyw.onrender.com/faculty/save");

      Map<String, dynamic> requestData = {
        "fact_id": "",
        "fact_Name": fullName,
        "email": email,
        "fact_email": factEmail,
        "password": password,
        "fact_contact": contact,
        "fact_gender": gender.isEmpty ? "Other" : gender[0],
        "fact_address": address,
        "fact_city": city,
        "fact_state": state,
        "fact_joiningDate": _joiningDateController.text,
        "fact_leavingDate": _leavingDateController.text.isEmpty ? "" : _leavingDateController.text,
        "fact_qualifications": qualifications,
        "Fact_cls": factClasses,
        "Fact_status": factStatus,
      };

      try {
        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(requestData),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Form submitted successfully!")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to submit. Try again! Error: ${response.statusCode}")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Faculty Registration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Faculty Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildTextField("Full Name", (value) => fullName = value, initialValue: fullName),
                  _buildTextField("Email", (value) => email = value, initialValue: email, isEmail: true),
                  _buildTextField("Faculty Email", (value) => factEmail = value, initialValue: factEmail, isEmail: true),
                  _buildTextField("Password", (value) => password = value, initialValue: password, isPassword: true),
                  _buildTextField("Contact", (value) => contact = value, initialValue: contact),
                  _buildDropdownField(
                    "Gender",
                    ["Male", "Female", "Other"],
                    (value) => setState(() => gender = value ?? ""),
                    selectedValue: gender.isEmpty ? null : gender,
                  ),
                  _buildTextField("Address", (value) => address = value, initialValue: address),
                  _buildTextField("City", (value) => city = value, initialValue: city),
                  _buildTextField("State", (value) => state = value, initialValue: state),
                  _buildDateField("Joining Date", _joiningDateController),
                  _buildDateField("Leaving Date", _leavingDateController),
                ],
              ),
              SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: Text("Submit"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String) onChanged, {String initialValue = "", bool isEmail = false, bool isPassword = false}) {
    return TextFormField(
      initialValue: initialValue,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField(String label, List<String> items, Function(String?) onChanged, {String? selectedValue}) {
    return DropdownButtonFormField<String>(
      value: selectedValue?.isEmpty ?? true ? null : selectedValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      onTap: () => _selectDate(context, controller),
    );
  }
}
