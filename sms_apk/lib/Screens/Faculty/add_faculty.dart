import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/utils/app_colors.dart';
import 'package:sms_apk/widgets/custom_popup.dart';
import 'package:sms_apk/widgets/header.dart';

class FacultyDetailsForm extends StatefulWidget {
  const FacultyDetailsForm({super.key});

  @override
  _FacultyDetailsFormState createState() => _FacultyDetailsFormState();
}

class _FacultyDetailsFormState extends State<FacultyDetailsForm> {
  final _formKey = GlobalKey<FormState>();

  // Form data
  final Map<String, dynamic> _formData = {
    "fullName": "",
    "email": "",
    "factEmail": "",
    "password": "",
    "contact": "",
    "gender": "",
    "address": "",
    "city": "",
    "state": "",
    "factStatus": "",
    "joiningDate": "",
    "leavingDate": "",
    "factQualifications": []
  };

  // Controllers for date fields
  final TextEditingController _joiningDateController = TextEditingController();
  final TextEditingController _leavingDateController = TextEditingController();

  String? token;

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
  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.light(primary: AppColors.primary),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
        _formData[controller == _joiningDateController
            ? "joiningDate"
            : "leavingDate"] = controller.text;
      });
    }
  }

  // Submit Form with Token Authentication
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (token == null) {
        showPopup(
            context,
            "Authentication token is missing. Please log in again.",
            AppColors.primary);
        return;
      }

      final url = Uri.parse("https://s-m-s-keyw.onrender.com/faculty/save");

      Map<String, dynamic> requestData = {
        "fact_id": "",
        "fact_Name": _formData["fullName"],
        "email": _formData["email"],
        "fact_email": _formData["factEmail"],
        "password": _formData["password"],
        "fact_contact": _formData["contact"],
        "fact_gender":
            _formData["gender"].isEmpty ? "Other" : _formData["gender"][0],
        "fact_address": _formData["address"],
        "fact_city": _formData["city"],
        "fact_state": _formData["state"],
        "fact_joiningDate": _formData["joiningDate"],
        "fact_leavingDate": _formData["leavingDate"],
        "fact_qualifications": _formData["factQualifications"],
        "Fact_cls": [],
        "Fact_status": _formData["factStatus"],
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
          showPopup(context, "Form submitted successfully!", AppColors.primary);
        } else {
          showPopup(
              context,
              "Failed to submit. Try again! Error: ${response.statusCode}",
              AppColors.primary);
        }
      } catch (e) {
        showPopup(context, "Error: $e", AppColors.primary);
      }
    }
  }

  void _addQualification() {
    setState(() {
      _formData["factQualifications"].add({
        "type": "Graduation",
        "grd_sub": "",
        "grd_branch": "",
        "grd_grade": "",
        "grd_university": "",
        "grd_yearOfPassing": ""
      });
    });
  }

  Widget _buildQualificationFields() {
    return Column(
      children: List.generate(_formData["factQualifications"].length, (index) {
        return Column(
          children: [
            _buildTextField("Degree Type", "factQualifications[$index][type]"),
            _buildTextField("Subject", "factQualifications[$index][grd_sub]"),
            _buildTextField("Branch", "factQualifications[$index][grd_branch]"),
            _buildTextField("Grade", "factQualifications[$index][grd_grade]"),
            _buildTextField(
                "University", "factQualifications[$index][grd_university]"),
            _buildTextField("Year of Passing",
                "factQualifications[$index][grd_yearOfPassing]"),
            const SizedBox(height: 16),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Color.fromARGB(255, 238, 235, 235),
    appBar: Header(text: "Add Faculty"),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Form(
            key: _formKey,
            child: Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Faculty Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField("Full Name*", "fullName"),
                    _buildTextField("Email*", "email", isEmail: false),
                    _buildTextField("Faculty Email*", "factEmail", isEmail: true),
                    _buildTextField("Password*", "password", isPassword: true),
                    _buildTextField("Contact*", "contact"),
                    _buildDropdownField(
                        "Gender*", ["Male", "Female", "Other"], "gender"),
                    _buildTextField("Address", "address"),
                    _buildTextField("City*", "city"),
                    _buildTextField("State", "state"),
                    _buildDateField("Joining Date*", _joiningDateController),
                    _buildDateField("Leaving Date", _leavingDateController),
                    _buildDropdownField(
                        "Status", ["Active", "Inactive"], "factStatus"),
                    _buildQualificationFields(),
                    ElevatedButton(
                      onPressed: _addQualification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, // Button color
                        foregroundColor: Colors.white, // Text color
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 20), // Button padding
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8), // Rounded corners
                        ),
                      ),
                      child: const Text("+ Add Qualification"),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Submit Button (Outside Card, Full Width)
          SizedBox(
            width: double.infinity, // Full width button
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, // Primary color
                foregroundColor: Colors.white, // White text color
                padding: const EdgeInsets.symmetric(vertical: 16), // More padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Smooth rounded corners
                ),
                elevation: 4, // Shadow for better visibility
              ),
              child: const Text(
                "Submit",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildTextField(String label, String key,
      {bool isEmail = false, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        initialValue: _formData[key],
        obscureText: isPassword,
        cursorColor: AppColors.primary, // Cursor (caret) color
        decoration: InputDecoration(
          labelText: label,
          floatingLabelStyle:
              TextStyle(color: AppColors.primary), // Label color when focused
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: AppColors.primary), // Default border color
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: AppColors.primary, width: 2), // Focused border color
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        onChanged: (value) => _formData[key] = value,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Enter a valid email address';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: _formData[key].isEmpty ? null : _formData[key],
        decoration: InputDecoration(
          labelText: label,
          floatingLabelStyle:
              TextStyle(color: AppColors.primary), // Label color when focused
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: AppColors.primary), // Default border color
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: AppColors.primary, width: 2), // Focused border color
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (value) => setState(() => _formData[key] = value ?? ""),
        validator: (value) =>
            value == null || value.isEmpty ? 'This field is required' : null,
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        cursorColor: AppColors.primary, // Cursor (caret) color
        decoration: InputDecoration(
          labelText: label,
          floatingLabelStyle:
              TextStyle(color: AppColors.primary), // Label color when focused
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide:
                BorderSide(color: AppColors.primary), // Default border color
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: AppColors.primary, width: 2), // Focused border color
            borderRadius: BorderRadius.circular(8),
          ),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap: () => _selectDate(context, controller),
      ),
    );
  }
}
