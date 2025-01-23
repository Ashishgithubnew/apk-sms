import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddStudentForm extends StatefulWidget {
  @override
  _AddStudentFormState createState() => _AddStudentFormState();
}

class _AddStudentFormState extends State<AddStudentForm> {
  final _formKey = GlobalKey<FormState>();

  // Form field controllers
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
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController motherNameController = TextEditingController();
  final TextEditingController primaryContactController = TextEditingController();
  final TextEditingController secondaryContactController = TextEditingController();
  final TextEditingController familyCityController = TextEditingController();
  final TextEditingController familyStateController = TextEditingController();
  final TextEditingController familyEmailController = TextEditingController();
  final TextEditingController genderController = TextEditingController();

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> submitForm() async {
    if (_formKey.currentState!.validate()) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No token found. Please log in.')),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Student added successfully!')),
          );
          Navigator.pop(context); // Close the form
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add student: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Student')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Student Name'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the student name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Address'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: cityController,
                decoration: InputDecoration(labelText: 'City'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: genderController,
                decoration: InputDecoration(labelText: 'Gender'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter gender';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: stateController,
                decoration: InputDecoration(labelText: 'State'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter state';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: contactController,
                decoration: InputDecoration(labelText: 'Contact'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter contact number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: dobController,
                decoration: InputDecoration(labelText: 'Date of Birth'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter date of birth';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: classController,
                decoration: InputDecoration(labelText: 'Class'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter class';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: departmentController,
                decoration: InputDecoration(labelText: 'Department'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter department';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: categoryController,
                decoration: InputDecoration(labelText: 'Category'),
              ),
              TextFormField(
                controller: totalFeeController,
                decoration: InputDecoration(labelText: 'Total Fee'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter total fee';
                  }
                  return null;
                },
              ),
              Divider(),
              Text('Family Details', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: fatherNameController,
                decoration: InputDecoration(labelText: "Father's Name"),
              ),
              TextFormField(
                controller: motherNameController,
                decoration: InputDecoration(labelText: "Mother's Name"),
              ),
              TextFormField(
                controller: primaryContactController,
                decoration: InputDecoration(labelText: 'Primary Contact'),
              ),
              TextFormField(
                controller: secondaryContactController,
                decoration: InputDecoration(labelText: 'Secondary Contact'),
              ),
              TextFormField(
                controller: familyCityController,
                decoration: InputDecoration(labelText: 'Family City'),
              ),
              TextFormField(
                controller: familyStateController,
                decoration: InputDecoration(labelText: 'Family State'),
              ),
              TextFormField(
                controller: familyEmailController,
                decoration: InputDecoration(labelText: 'Family Email'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitForm,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
