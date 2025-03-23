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
  bool isLoading = false;

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
  DateTime? initialDate = DateTime.now();
  DateTime? firstDate = DateTime(2000);

  // If selecting leaving date, ensure it comes after the joining date
  if (controller == _leavingDateController) {
    if (_joiningDateController.text.isEmpty) {
      showPopup(context, "Please select a joining date first!", AppColors.primary);
      return;
    }
    
    DateTime joiningDate = DateFormat('dd/MM/yyyy').parse(_joiningDateController.text);
    initialDate = joiningDate;
    firstDate = joiningDate;
  }

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
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
      String formattedDate = DateFormat('dd/MM/yyyy').format(picked);
      
      // Ensure leaving date is after joining date
      if (controller == _leavingDateController) {
        DateTime joiningDate = DateFormat('dd/MM/yyyy').parse(_joiningDateController.text);
        if (picked.isBefore(joiningDate)) {
          showPopup(context, "Leaving date cannot be before joining date!", AppColors.primary);
          return;
        }
      }

      controller.text = formattedDate;
      _formData[controller == _joiningDateController
          ? "joiningDate"
          : "leavingDate"] = formattedDate;
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
        AppColors.primary,
      );
      return;
    }

    setState(() => isLoading = true); // Start loading

    final url = Uri.parse("https://s-m-s-keyw.onrender.com/faculty/save");

    // Convert `factQualifications` controllers to their text values
    List<Map<String, dynamic>> factQualifications =
        _formData["factQualifications"].map<Map<String, dynamic>>((qualification) {
      return {
        "id": qualification["id"],
        "type": qualification["type"],
        "grd_sub": qualification["grd_sub"],
        "grd_branch": qualification["grd_branch"],
        "grd_grade": qualification["grd_grade"],
        "grd_university": qualification["grd_university"],
        "grd_yearOfPassing": qualification["yearOfPassingController"]?.text ?? "",
      };
    }).toList();

    Map<String, dynamic> requestData = {
      "fact_id": "",
      "fact_Name": _formData["fullName"],
      "email": _formData["email"],
      "fact_email": _formData["factEmail"],
      "password": _formData["password"],
      "fact_contact": _formData["contact"],
      "fact_gender": _formData["gender"] ?? "Other",
      "fact_address": _formData["address"],
      "fact_city": _formData["city"],
      "fact_state": _formData["state"],
      "fact_joiningDate": _formData["joiningDate"],
      "fact_leavingDate": _formData["leavingDate"],
      "fact_qualifications": factQualifications,
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
        await showPopup(context, "Form submitted successfully!", AppColors.primary);
        if (mounted) {
          Navigator.pop(context);
        }
      } else if (response.statusCode == 400) {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody["detail"] ?? "Invalid request. Please check your input.";
        showPopup(context, errorMessage, AppColors.primary);
      } else {
        showPopup(context, "Failed to submit. Try again! Error: ${response.statusCode}", AppColors.primary);
      }
    } catch (e) {
      showPopup(context, "Error: $e", AppColors.primary);
    } finally {
      if (mounted) {
        setState(() => isLoading = false); // Stop loading in all cases
      }
    }
  }
}


  void _addQualification() {
    setState(() {
      _formData["factQualifications"].add({
        "id": DateTime.now()
            .millisecondsSinceEpoch, // Unique ID for each qualification
        "type": "Graduation",
        "grd_sub": "",
        "grd_branch": "",
        "grd_grade": "",
        "grd_university": "",
        "grd_yearOfPassing": "",
        "yearOfPassingController": TextEditingController(), // Add controller
      });
    });
  }

  Widget _buildQualificationFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_formData["factQualifications"]
            .isNotEmpty) // Conditionally show "Qualifications" text
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.close,
                    color: Colors.black, size: 24), // Cross icon
                padding: EdgeInsets.zero, // Remove default padding
                onPressed: () {
                  setState(() {
                    _formData["factQualifications"]
                        .clear(); // Remove all qualification sets
                  });
                },
              ),
              Text(
                "Qualifications",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ...List.generate(_formData["factQualifications"].length, (index) {
          // Ensure each qualification entry has a controller for the date field
          _formData["factQualifications"][index]["yearOfPassingController"] ??=
              TextEditingController();

          return Column(
            children: [
              Column(
                children: [
                  _buildTextField("Degree Type",
                      "factQualifications[$index][type]",false, "Degree Type"),
                  _buildTextField("Subject",
                      "factQualifications[$index][grd_sub]",false, "Subject"),
                  _buildTextField("Branch",
                      "factQualifications[$index][grd_branch]",false, "Branch"),
                  _buildTextField("Grade",
                      "factQualifications[$index][grd_grade]",false, "Grade"),
                  _buildTextField(
                      "University",
                      "factQualifications[$index][grd_university]",false,
                      "University"),
                  _buildDateField(
                    "Year of Passing",
                    _formData["factQualifications"][index]
                        ["yearOfPassingController"], // Pass the controller
                  ), // Fixed typo
                ],
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 238, 235, 235),
      appBar: Header(text: "Add Faculty"),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
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
                      _buildTextField("Full Name*", "fullName",true , "Full Name",
                          isName: true),
                      _buildTextField(
                          "Email*", "email", isEmail: true,true , "Email"),
                      _buildTextField("Contact*", "contact",true , "Contact",
                          isContact: true),
                      _buildDropdownField("Gender*",
                          ["Male", "Female", "Other"], "gender", "Gender"),
                      _buildTextField("Address", "address",true , "Address",
                          isAddress: true),
                      _buildTextField("City*", "city",true , "City", isCity: true),
                      // _buildTextField("State", "state", "State", isState: true),
                      _buildDropdownField(
                          "State*",
                          [
                            "Andhra Pradesh",
                            "Arunachal Pradesh",
                            "Assam",
                            "Bihar",
                            "Chattisgarh",
                            "Goa",
                            "Gujarat",
                            "Haryana",
                            "Himachal Pradesh",
                            "Jharkhand",
                            "Karnataka",
                            "Kerala",
                            "Madhya Pradesh",
                            "Maharashtra",
                            "Manipur",
                            "Meghalaya",
                            "Mizoram",
                            "Nagaland",
                            "Odisha",
                            "Punjab",
                            "Rajasthan",
                            "Sikkim",
                            "Tamil Nadu",
                            "Telangana",
                            "Tripura",
                            "Uttar Pradesh",
                            "Uttarakhand",
                            "West Bengal"
                          ],
                          "state",
                          "State"),
                      _buildDateField("Joining Date*", _joiningDateController),
                      _buildDateField("Leaving Date", _leavingDateController),
                      _buildDropdownField("Status", ["Active", "Inactive"],
                          "factStatus", "Status"),
                      _buildTextField(
                          "Faculty Email*", "factEmail",true , "Faculty Email",
                          isEmail: true),
                      _buildTextField("Password*", "password",true , "Password",
                          isPassword: true),
                      _buildQualificationFields(), // Render qualification fields
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
              const SizedBox(height: 24),
              // Submit Button (Outside Card, Full Width)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Primary color
                  foregroundColor: Colors.white, // White text color
                  padding:
                      const EdgeInsets.symmetric(vertical: 16), // More padding
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12), // Smooth rounded corners
                  ),
                  elevation: 4, // Shadow for better visibility
                ),
                onPressed: isLoading ? null : _submitForm,
                child: isLoading
                    ? CircularProgressIndicator(color: AppColors.primary)
                    : Text('Submit',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key,bool isRequired, String s,
      {bool isEmail = false,
      bool isPassword = false,
      bool isName = false,
      bool isContact = false,
      bool isAddress = false,
      bool isCity = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        initialValue: _formData[key],
        obscureText: isPassword,
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelStyle: TextStyle(color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        keyboardType: isEmail
            ? TextInputType.emailAddress
            : isContact
                ? TextInputType.phone
                : TextInputType.text,
        onChanged: (value) => _formData[key] = value,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return isRequired ? '$s is required' : null;
          }
          if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Enter a valid email address';
          }
          if (isPassword && value.length < 6) {
            return 'Address should be at least 5 characters long';
          }
          if (isName &&
              (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value) ||
                  value.length <= 2)) {
            return 'Name should contain only alphabets and spaces';
          }

          if (isContact && !RegExp(r'^[0-9]{10}$').hasMatch(value)) {
            return 'Enter a valid 10-digit contact number';
          }
          if (isAddress && value.length < 5) {
            return 'Address should be at least 5 characters long';
          }
          if (isCity && !RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
            return 'State should contain only alphabets and spaces';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField(
      String label, List<String> items, String key, String s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: (_formData[key] != "") ? _formData[key] : null,
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
            value == null || value.isEmpty ? '$s is required' : null,
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
