import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  String contact = "";
  String gender = "";
  String address = "";
  String city = "";
  String state = "";
  String joiningDate = "";
  String leavingDate = "";

  List<Map<String, String>> qualifications = [
    {"type": "", "subject": "", "branch": "", "grade": "", "university": "", "year": ""}
  ];

  // Date picker helper
  Future<void> _selectDate(BuildContext context, Function(String) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      final formattedDate = DateFormat('dd/MM/yyyy').format(picked);
      onDateSelected(formattedDate);
    }
  }

  // Add new qualification row
  void _addQualification() {
    setState(() {
      qualifications.add({"type": "", "subject": "", "branch": "", "grade": "", "university": "", "year": ""});
    });
  }

  // Remove qualification row
  void _removeQualification(int index) {
    setState(() {
      qualifications.removeAt(index);
    });
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
                  _buildDateField("Joining Date", joiningDate, (date) => setState(() => joiningDate = date)),
                  _buildDateField("Leaving Date", leavingDate, (date) => setState(() => leavingDate = date)),
                ],
              ),
              SizedBox(height: 32),
              Text("Qualifications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Column(
                children: [
                  for (int i = 0; i < qualifications.length; i++)
                    Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: _buildTextField("Type", (value) => qualifications[i]['type'] = value)),
                            Expanded(flex: 2, child: _buildTextField("Subject", (value) => qualifications[i]['subject'] = value)),
                            Expanded(flex: 2, child: _buildTextField("Branch", (value) => qualifications[i]['branch'] = value)),
                            Expanded(flex: 2, child: _buildTextField("Grade", (value) => qualifications[i]['grade'] = value)),
                            Expanded(flex: 2, child: _buildTextField("University", (value) => qualifications[i]['university'] = value)),
                            Expanded(
                              flex: 2,
                              child: _buildDateField(
                                "Year",
                                qualifications[i]['year'] ?? "",
                                (date) => setState(() => qualifications[i]['year'] = date),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeQualification(i),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addQualification,
                    icon: Icon(Icons.add),
                    label: Text("Add Qualification"),
                  ),
                ],
              ),
              SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      print("Full Name: $fullName");
                      print("Email: $email");
                      print("Contact: $contact");
                      print("Gender: $gender");
                      print("Address: $address");
                      print("City: $city");
                      print("State: $state");
                      print("Joining Date: $joiningDate");
                      print("Leaving Date: $leavingDate");
                      print("Qualifications: $qualifications");
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Form submitted successfully!")));
                    }
                  },
                  child: Text("Submit"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, Function(String) onChanged, {String initialValue = "", bool isEmail = false}) {
    return TextFormField(
      initialValue: initialValue,
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

  Widget _buildDateField(String label, String initialValue, Function(String) onDateSelected) {
    return TextFormField(
      readOnly: true,
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          final formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
          onDateSelected(formattedDate);
        }
      },
    );
  }
}
