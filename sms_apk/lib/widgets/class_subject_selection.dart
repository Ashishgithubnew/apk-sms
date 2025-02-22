import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ClassSubjectSelection extends StatefulWidget {
  final Function(String selectedClass, String? selectedSubject)?
      onSelectionChanged;

  const ClassSubjectSelection({super.key, this.onSelectionChanged});

  @override
  _ClassSubjectSelectionState createState() => _ClassSubjectSelectionState();
}

class _ClassSubjectSelectionState extends State<ClassSubjectSelection> {
  String? selectedClass;
  String? selectedSubject;
  String? selectedDepartment;

  final List<String> classes = [
    "Class I",
    "Class II",
    "Class III",
    "Class IV",
    "Class V",
    "Class VI",
    "Class VII",
    "Class VIII",
    "Class IX",
    "Class X",
    "Class XI",
    "Class XII"
  ];

  final List<String> departments = [
    "Arts",
    "Biology",
    "Mathematics",
    "Commerce",
    "Agriculture"
  ];

  final Map<String, List<String>> departmentSubjects = {
    "Arts": ["History", "Political Science", "Geography", "Economics"],
    "Biology": ["Physics", "Chemistry", "Biology"],
    "Mathematics": ["Physics", "Chemistry", "Mathematics"],
    "Commerce": ["Accountancy", "Business Studies", "Economics"],
    "Agriculture": ["Agronomy", "Horticulture", "Animal Husbandry"]
  };

  final List<String> generalSubjects = [
    "English",
    "Hindi",
    "Sanskrit",
    "Science",
    "Social Science",
    "Mathematics"
  ];

  void showSelectionPopup(
      List<String> options, String title, Function(String) onSelect) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: AppColors.primary,
          child: Container(
            padding: EdgeInsets.all(16),
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(options[index],
                            style: TextStyle(color: Colors.white)),
                        onTap: () {
                          onSelect(options[index]);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _onClassSelected(String value) {
    setState(() {
      selectedClass = value;
      selectedSubject = null;
      selectedDepartment = null;
    });

    // Notify parent widget
    widget.onSelectionChanged?.call(selectedClass!, selectedSubject);
  }

  void _onDepartmentSelected(String value) {
    setState(() {
      selectedDepartment = value;
      selectedSubject = null;
    });

    // Notify parent widget
    widget.onSelectionChanged?.call(selectedClass!, selectedSubject);
  }

  void _onSubjectSelected(String value) {
    setState(() {
      selectedSubject = value;
    });

    // Notify parent widget
    widget.onSelectionChanged?.call(selectedClass!, selectedSubject);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Select Class
        GestureDetector(
          onTap: () =>
              showSelectionPopup(classes, "Select Class", _onClassSelected),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(selectedClass ?? "Select Class",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Icon(Icons.arrow_drop_down, color: Colors.white)
              ],
            ),
          ),
        ),
        SizedBox(height: 20),

        // Department (Only for XI & XII)
        if (selectedClass == "Class XI" || selectedClass == "Class XII")
          GestureDetector(
            onTap: () => showSelectionPopup(
                departments, "Select Department", _onDepartmentSelected),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(selectedDepartment ?? "Select Department",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  Icon(Icons.arrow_drop_down, color: Colors.white)
                ],
              ),
            ),
          ),
        if (selectedClass == "Class XI" || selectedClass == "Class XII")
          SizedBox(height: 20),

        // Select Subject
        GestureDetector(
          onTap: () {
            List<String> subjects =
                (selectedClass == "Class XI" || selectedClass == "Class XII")
                    ? (selectedDepartment != null
                        ? departmentSubjects[selectedDepartment!] ?? []
                        : [])
                    : generalSubjects;
            showSelectionPopup(subjects, "Select Subject", _onSubjectSelected);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(selectedSubject ?? "Select Subject",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Icon(Icons.arrow_drop_down, color: Colors.white)
              ],
            ),
          ),
        ),
      ],
    );
  }
}
