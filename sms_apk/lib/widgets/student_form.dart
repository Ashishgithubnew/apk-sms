import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/widgets/custom_popup.dart';
import '../utils/app_colors.dart';
import 'package:intl/intl.dart'; // For date formatting

class StudentForm extends StatefulWidget {
  const StudentForm({super.key});

  @override
  _StudentFormState createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // Controllers for form fields
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
        showPopup(context, 'No token found. Please log in.', AppColors.primary);
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

          // Sorting using the custom comparator
          classes.sort(
              (a, b) => compareClassNames(a['className'], b['className']));
        });
      } else if (response.statusCode == 400) {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody["detail"] ??
            "Invalid request. Please check your input.";
        showPopup(context, errorMessage, AppColors.primary);
      } else {
        showPopup(context, 'Failed to load classes', AppColors.primary);
      }
    } catch (e) {
      showPopup(context, 'Error fetching classes: $e', AppColors.primary);
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

  void onClassSelected(String? className) {
    if (className == null) return;
    setState(() {
      selectedClass = className;
      // totalFeeController.text = classes
      //     .firstWhere((e) => e['className'] == className)['totalFee']
      //     .toString();
      totalFeeController.text = classes
          .firstWhere((e) => e['className'] == className,
              orElse: () => {'totalFee': 0})['totalFee']
          .toString();
    });
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await getToken();
    if (token == null) {
      showPopup(context, 'No token found. Please log in.', AppColors.primary);
      return;
    }

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
      'totalFee': totalFeeController.text.isNotEmpty
          ? int.tryParse(totalFeeController.text)?.toString() ?? '0'
          : '0',
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
      final response = await http.post(
        Uri.parse('https://s-m-s-keyw.onrender.com/student/save'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(studentData),
      );

      if (response.statusCode == 200) {
        await showPopup(
            context, 'Student added successfully!', AppColors.primary);
        resetForm();
        if (mounted) Navigator.pop(context);
      } else {
        final errorMessage =
            jsonDecode(response.body)["detail"] ?? "Invalid request.";
        showPopup(context, errorMessage, AppColors.primary);
      }
    } catch (e) {
      showPopup(context, 'Error: $e', AppColors.primary);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
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
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        dobController.text = formattedDate;
      });
    }
  }

  void resetForm() {
    nameController.clear();
    addressController.clear();
    cityController.clear();
    stateController.clear();
    contactController.clear();
    dobController.clear();
    emailController.clear();
    categoryController.clear();
    totalFeeController.clear();
    genderController.clear();
    fatherNameController.clear();
    motherNameController.clear();
    primaryContactController.clear();
    secondaryContactController.clear();
    familyCityController.clear();
    familyStateController.clear();
    familyEmailController.clear();
    setState(() {
      selectedClass = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AbsorbPointer(
          absorbing: isLoading,
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                buildCard('Student Details', [
                  buildInputField(
                      nameController, 'Full Name*', true, "Full Name",
                      isName: true),
                  buildInputField(
                      addressController, 'Address*', true, "Address",
                      isAddress: true),
                  buildInputField(cityController, 'City*', true, "City",
                      isCity: true),
                  buildDropdownField(
                    label: 'Gender*',
                    options: ['Male', 'Female', 'Other'],
                    controller: genderController,
                    validator: (value) =>
                        value == null ? 'Please select a gender' : null,
                  ),
                  buildDropdownField(
                    label: 'Category*',
                    options: ['General', 'SC', 'ST', 'OBC', 'Other'],
                    controller: categoryController,
                    validator: (value) =>
                        value == null ? 'Please select a category' : null,
                  ),
                  // buildInputField(stateController, 'State*', true, "State",
                  //     isState: true),
                  buildDropdownField(
                    label: "State*",
                    options: [
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
                    controller: stateController,
                    validator: (value) =>
                        value == null ? 'Please select a category' : null,
                  ),
                  buildInputField(
                      contactController, 'Contact*', true, "Contact",
                      isContact: true),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: buildInputField(dobController, 'Date of Birth*',
                          true, "Date of Birth"),
                    ),
                  ),
                  buildInputField(emailController, 'Email', false, "",
                      isEmail: true),
                  buildDropdownField(
                    label: 'Select Class*',
                    options:
                        classes.map((e) => e['className'] as String).toList(),
                    controller: TextEditingController(text: selectedClass),
                    validator: (value) =>
                        value == null ? 'Please select a class' : null,
                    onChanged: onClassSelected,
                  ),
                  buildInputField(totalFeeController, 'Total Fee*', false, "",
                      isNumber: true, readOnly: true),
                ]),
                buildCard('Family Details', [
                  buildInputField(fatherNameController, "Father's Name*", true,
                      "Father's Name",
                      isName: true),
                  buildInputField(
                      motherNameController, "Mother's Name", false, "",
                      isName: true),
                  buildInputField(primaryContactController, "Primary Contact*",
                      true, "Primary Contact",
                      isContact: true),
                  buildInputField(secondaryContactController,
                      "Secondary Contact", false, "",
                      isContact: true),
                  buildInputField(
                      familyCityController, "Family City", false, "",
                      isCity: true),
                  // buildInputField(
                  //     familyStateController, "Family State", false, "",
                  //     isState: true),
                  buildDropdownField(
                    label: "State*",
                    options: [
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
                    controller: familyStateController,
                    validator: (value) =>
                        value == null ? 'Please select a state' : null,
                  ),
                  buildInputField(familyEmailController, "Family Email*", true,
                      "Family Email",
                      isEmail: true),
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
      ),
    );
  }

  Widget buildDropdownField({
    required String label,
    required List<String> options,
    required TextEditingController controller,
    required String? Function(String?) validator,
    Function(String?)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: controller.text.isNotEmpty ? controller.text : null,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelStyle: TextStyle(color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged ??
            (String? newValue) {
              setState(() {
                controller.text = newValue!;
              });
            },
        validator: validator,
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

  Widget buildInputField(
    TextEditingController controller,
    String label,
    bool isRequired,
    String s, {
    bool isNumber = false,
    bool readOnly = false,
    bool isEmail = false,
    bool isPassword = false,
    bool isName = false,
    bool isContact = false,
    bool isAddress = false,
    bool isCity = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber
            ? TextInputType.number
            : isEmail
                ? TextInputType.emailAddress
                : TextInputType.text,
        readOnly: readOnly,
        obscureText: isPassword,
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelStyle: TextStyle(color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return isRequired ? '$s is required' : null;
          }
          if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
            return 'Enter a valid email address';
          }
          if (isContact && !RegExp(r'^\d{10}$').hasMatch(value)) {
            return 'Contact must be exactly 10 digits';
          }
          if (isName &&
              (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value) ||
                  value.length <= 2)) {
            return 'Name should contain only alphabets and spaces';
          }

          if (isAddress && value.length < 5) {
            return 'Address should be at least 5 characters long';
          }
          if (isCity && !RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(value)) {
            return 'City should contain only alphabets, spaces, and hyphens';
          }
          return null;
        },
      ),
    );
  }
}
