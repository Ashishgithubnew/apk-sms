import 'package:flutter/material.dart';
import 'package:sms_apk/widgets/header.dart';
import '../../widgets/student_form.dart';

class AddStudentScreen extends StatelessWidget {
  const AddStudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: Header(text: "Add Student"),
      body: const StudentForm(),
    );
  }
}
