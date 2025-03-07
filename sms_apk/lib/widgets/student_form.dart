import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/widgets/custom_popup.dart';
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

  List<Map<String, dynamic>> classes = [];
  String? selectedClass;

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    try {
      final token = await getToken();
      if (token == null) {
        showPopup(context,'No token found. Please log in.',AppColors.primary);
        return;
      }
      final response = await http.get(
        Uri.parse('https://s-m-s-keyw.onrender.com/admin/getAll'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        setState(() {
          classes = data
              .map((e) => {
                    'className': e['className'],
                    'totalFee': e['totalFee'],
                  })
              .toList();
        });
      } else {
        showPopup(context,'Failed to load classes',AppColors.primary);
      }
    } catch (e) {
      showPopup(context,'Error fetching classes: $e',AppColors.primary);
    }
  }

  void onClassSelected(String? className) {
    if (className == null) return;
    setState(() {
      selectedClass = className;
      totalFeeController.text = classes
          .firstWhere((e) => e['className'] == className)['totalFee']
          .toString();
    });
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
      'cls': selectedClass,
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
        showPopup(context,'No token found. Please log in.',AppColors.primary);
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
        showPopup(context,'Student added successfully!',AppColors.primary);
        Navigator.pop(context);
      } else if (response.statusCode == 400) {
        // Parse the response body to extract the error message
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody["detail"] ??
            "Invalid request. Please check your input.";
        showPopup(context, errorMessage, AppColors.primary);
      } else {
        showPopup(context,'Failed to add student: ${response.body}',AppColors.primary);
      }
    } catch (e) {
      showPopup(context,'Error: $e',AppColors.primary);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
        dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
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
                buildInputField(nameController, 'Student Name*', true),
                buildInputField(addressController, 'Address*', true),
                buildInputField(cityController, 'City*', true),
                buildDropdownGenderField(),
                buildDropdownCategoryField(),
                buildInputField(stateController, 'State*', true),
                buildInputField(contactController, 'Contact*', true),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child:
                        buildInputField(dobController, 'Date of Birth*', true),
                  ),
                ),
                buildInputField(emailController, 'Email', false),
                buildDropdownField(),
                buildInputField(totalFeeController, 'Total Fee', true,
                    isNumber: true, readOnly: true),
              ]),
              buildCard('Family Details', [
                buildInputField(fatherNameController, "Father's Name*", true),
                buildInputField(motherNameController, "Mother's Name", false),
                buildInputField(
                    primaryContactController, "Primary Contact*", true,
                    isNumber: true),
                buildInputField(
                    secondaryContactController, "Secondary Contact", false,
                    isNumber: true),
                buildInputField(familyCityController, "Family City", false),
                buildInputField(familyStateController, "Family State", false),
                buildInputField(familyEmailController, "Family Email*", true),
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
                    : Text('Submit',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedClass,
        decoration: InputDecoration(
          labelText: 'Select Class',
          floatingLabelStyle:
              TextStyle(color: AppColors.primary), // Label color when focused
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
        items: classes.map<DropdownMenuItem<String>>((e) {
          return DropdownMenuItem<String>(
            value: e['className'] as String, // Ensure this is a String
            child: Text(e['className']),
          );
        }).toList(),
        onChanged: onClassSelected,
        validator: (value) => value == null ? 'Please select a class' : null,
      ),
    );
  }

  Widget buildCard(String title, List<Widget> children) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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

  Widget buildDropdownGenderField() {
    List<String> genderOptions = ['Male', 'Female', 'Other'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: genderController.text.isNotEmpty ? genderController.text : null,
        decoration: InputDecoration(
          labelText: 'Gender*',
          floatingLabelStyle:
              TextStyle(color: AppColors.primary), // Label color when focused
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
        items: genderOptions.map((String gender) {
          return DropdownMenuItem<String>(
            value: gender,
            child: Text(gender),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            genderController.text = newValue!;
          });
        },
        validator: (value) => value == null ? 'Please select a gender' : null,
      ),
    );
  }

  Widget buildDropdownCategoryField() {
    List<String> categoryOptions = ['General', 'SC', 'ST', 'OBC', 'Other'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value:
            categoryController.text.isNotEmpty ? categoryController.text : null,
        decoration: InputDecoration(
          labelText: 'Category*',
          floatingLabelStyle:
              TextStyle(color: AppColors.primary), // Label color when focused
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
        items: categoryOptions.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            categoryController.text = newValue!;
          });
        },
        validator: (value) => value == null ? 'Please select a category' : null,
      ),
    );
  }

  Widget buildInputField(
      TextEditingController controller, String label, bool isRequired,
      {bool isNumber = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        readOnly: readOnly,
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
        validator: isRequired
            ? (value) =>
                value == null || value.isEmpty ? 'This field is required' : null
            : null,
      ),
    );
  }
}
