import 'package:flutter/material.dart';
import '../../widgets/student_form.dart';
import '../../utils/app_colors.dart';
import '../../widgets/user_icon.dart';

class AddStudentScreen extends StatelessWidget {
  const AddStudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Add Student',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: UserIconWidget(userName: "Aditya Sharma"),
          ),
        ],
      ),
      body: const StudentForm(),
    );
  }
}
