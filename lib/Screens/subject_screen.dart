import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SaveSubjectsToClasses extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onSave;
  final Map<String, dynamic>? editableRowData;
  final Future<String?> Function()? getAuthToken;

  const SaveSubjectsToClasses({
    Key? key,
    this.onClose,
    this.onSave,
    this.editableRowData,
    this.getAuthToken,
  }) : super(key: key);

  @override
  State<SaveSubjectsToClasses> createState() => _SaveSubjectsToClassesState();
}

class _SaveSubjectsToClassesState extends State<SaveSubjectsToClasses> {
  String selectedClass = "";
  List<String> selectedSubjects = [];
  String customSubject = "";
  String newClass = "";
  bool loading = false;
  
  List<String> classOptions = [
    "Nursery", "LKG", "UKG", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"
  ];
  
  List<String> availableSubjects = [
    "Maths", "Science", "English", "History", "Geography",
    "Physics", "Chemistry", "Biology", "Algebra", "Geometry",
  ];

  static const String baseUrl = 'https://s-m-s-keyw.onrender.com';

  @override
  void initState() {
    super.initState();
    print('SaveSubjectsToClasses initialized');
    if (widget.editableRowData != null) {
      selectedClass = widget.editableRowData!['className'] ?? '';
      
      final subject = widget.editableRowData!['subject'];
      if (subject is String) {
        selectedSubjects = subject.split(', ');
      } else if (subject is List) {
        selectedSubjects = List<String>.from(subject);
      }
    }
  }

  void handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void handleSaveCallback() {
    if (widget.onSave != null) {
      widget.onSave!();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> saveClass() async {
    final payload = {
      'classData': [
        {
          'className': selectedClass.trim(),
          'subject': selectedSubjects.map((subject) => subject.trim()).toSet().toList(),
        }
      ]
    };

    String? token;
    if (widget.getAuthToken != null) {
      token = await widget.getAuthToken!();
    }
    
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    print('Saving class with payload: ${json.encode(payload)}');

    final response = await http.post(
      Uri.parse('$baseUrl/class/save'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(payload),
    );

    print('Save API Response Status: ${response.statusCode}');
    print('Save API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to save class: ${response.statusCode}\nResponse: ${response.body}');
    }
  }

  Future<void> updateClass() async {
    final payload = {
      'classData': [
        {
          'className': selectedClass.trim(),
          'subject': selectedSubjects.map((subject) => subject.trim()).toSet().toList(),
        }
      ]
    };

    String? token;
    if (widget.getAuthToken != null) {
      token = await widget.getAuthToken!();
    }
    
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final className = widget.editableRowData?['className'] ?? '';
    
    print('Updating class with payload: ${json.encode(payload)}');

    final response = await http.post(
      Uri.parse('$baseUrl/class/edit?className=${Uri.encodeComponent(className)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(payload),
    );

    print('Update API Response Status: ${response.statusCode}');
    print('Update API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to update class: ${response.statusCode}\nResponse: ${response.body}');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void handleAddNewClass() {
    final trimmedClass = newClass.trim();
    if (trimmedClass.isEmpty) {
      _showSnackBar("Please enter a class name!", isError: true);
      return;
    }

    if (classOptions.contains(trimmedClass)) {
      _showSnackBar("Class already exists!", isError: true);
      return;
    }

    setState(() {
      classOptions.add(trimmedClass);
      newClass = "";
    });
    _showSnackBar("New class added successfully!");
  }

  void handleSubjectToggle(String subject) {
    setState(() {
      if (selectedSubjects.contains(subject)) {
        selectedSubjects.remove(subject);
      } else {
        selectedSubjects.add(subject);
      }
    });
  }

  void handleAddCustomSubject() {
    final trimmedSubject = customSubject.trim();
    if (trimmedSubject.isEmpty) {
      _showSnackBar("Please enter a subject name!", isError: true);
      return;
    }

    if (availableSubjects.contains(trimmedSubject)) {
      _showSnackBar("Subject already exists!", isError: true);
      return;
    }

    setState(() {
      availableSubjects.add(trimmedSubject);
      selectedSubjects.add(trimmedSubject);
      customSubject = "";
    });
    _showSnackBar("New subject added successfully!");
  }

  bool validateInputs() {
    if (selectedClass.isEmpty) {
      _showSnackBar("Please select a class!", isError: true);
      return false;
    }

    if (selectedSubjects.isEmpty) {
      _showSnackBar("Please select at least one subject!", isError: true);
      return false;
    }

    return true;
  }

  Future<void> handleSaveNewClass() async {
    if (!validateInputs()) return;
    
    setState(() => loading = true);

    try {
      await saveClass();
      _showSnackBar("Class and subjects saved successfully!");
      handleSaveCallback();
    } catch (error) {
      _showSnackBar("Failed to save data: ${error.toString()}", isError: true);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> handleUpdateClass() async {
    if (!validateInputs()) return;
    
    setState(() => loading = true);

    try {
      await updateClass();
      _showSnackBar("Class and subjects updated successfully!");
      handleSaveCallback();
    } catch (error) {
      _showSnackBar("Failed to update data: ${error.toString()}", isError: true);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editableRowData != null ? "Update Subjects" : "Save Subjects to Classes"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: handleClose,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Selection
            const Text("Select Class:", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedClass.isEmpty ? null : selectedClass,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Select a Class",
              ),
              items: classOptions.map((classOption) {
                return DropdownMenuItem(
                  value: classOption,
                  child: Text("Class $classOption"),
                );
              }).toList(),
              onChanged: widget.editableRowData != null ? null : (value) {
                setState(() => selectedClass = value ?? "");
              },
            ),
            const SizedBox(height: 16),

            // Add New Class (only in create mode)
            if (widget.editableRowData == null) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Add New Class",
                      ),
                      onChanged: (value) => setState(() => newClass = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: handleAddNewClass,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Add Class"),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Subject Selection
            if (selectedClass.isNotEmpty) ...[
              Text(
                "Select Subjects for Class $selectedClass:",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: availableSubjects.length,
                  itemBuilder: (context, index) {
                    final subject = availableSubjects[index];
                    return CheckboxListTile(
                      title: Text(subject),
                      value: selectedSubjects.contains(subject),
                      onChanged: (bool? value) => handleSubjectToggle(subject),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Add Custom Subject
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter new subject name",
                      ),
                      onChanged: (value) => setState(() => customSubject = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: handleAddCustomSubject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Add Subject"),
                  ),
                ],
              ),
            ] else ...[
              const Expanded(
                child: Center(
                  child: Text(
                    "Please select a class to continue",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: handleClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: loading || selectedClass.isEmpty || selectedSubjects.isEmpty
                      ? null
                      : (widget.editableRowData != null ? handleUpdateClass : handleSaveNewClass),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    loading 
                        ? "Saving..." 
                        : (widget.editableRowData != null ? "Update" : "Save"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
