import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ClassData model (same as before)
class ClassData {
  final String className;
  final dynamic subject;

  ClassData({required this.className, required this.subject});

  factory ClassData.fromJson(Map<String, dynamic> json) {
    return ClassData(
      className: json['className'] ?? '',
      subject: json['subject'],
    );
  }

  List<String> get subjectList {
    if (subject is String) {
      return subject.split(', ');
    } else if (subject is List) {
      return List<String>.from(subject);
    }
    return [];
  }
  
  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'subject': subject,
    };
  }
}

class ClassSubjectShow extends StatefulWidget {
  const ClassSubjectShow({Key? key}) : super(key: key);

  @override
  State<ClassSubjectShow> createState() => _ClassSubjectShowState();
}

class _ClassSubjectShowState extends State<ClassSubjectShow> {
  List<ClassData> data = [];
  bool loading = true;
  String? error;
  bool showForm = false;
  ClassData? editableRow;

  static const String baseUrl = 'https://s-m-s-keyw.onrender.com';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // Fixed: Check multiple possible token keys
  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token;
      
      // First check for your actual key
      token = prefs.getString('flutter.authToken');
      
      // Fallback to other possible keys
      if (token == null) {
        token = prefs.getString('auth_token');
      }
      if (token == null) {
        token = prefs.getString('token');
      }
      if (token == null) {
        token = prefs.getString('access_token');
      }
      
      return token;
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  Future<void> fetchData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final token = await getAuthToken();
      
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/class/data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> classDataList = jsonData['classData'] ?? [];
        
        setState(() {
          data = classDataList.map((item) => ClassData.fromJson(item)).toList();
          loading = false;
        });
        
        _showSnackBar('Data loaded successfully!');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token may be expired. Please login again.');
      } else if (response.statusCode == 403) {
        final responseBody = response.body;
        if (responseBody.contains('JWT expired')) {
          throw Exception('Session expired. Please login again.');
        } else {
          throw Exception('Access denied. Please check your permissions.');
        }
      } else {
        throw Exception('Failed to load class data: ${response.statusCode}');
      }
    } catch (err) {
      setState(() {
        error = err.toString();
        loading = false;
      });
      _showSnackBar('Error: ${err.toString()}', isError: true);
    }
  }

  Future<void> deleteClass(String className) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete class "$className"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final token = await getAuthToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/class/delete?className=${Uri.encodeComponent(className)}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await fetchData();
        _showSnackBar('Class $className has been deleted successfully!');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Token may be expired. Please login again.');
      } else {
        throw Exception('Failed to delete class: ${response.statusCode}');
      }
    } catch (error) {
      _showSnackBar('Failed to delete the class: ${error.toString()}', isError: true);
    }
  }

  void handleEdit(ClassData row) {
    setState(() {
      showForm = true;
      editableRow = row;
    });
  }

  Future<void> handleSave() async {
    await fetchData();
    setState(() {
      showForm = false;
      editableRow = null;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  // Method to handle form close
  void _closeForm() {
    setState(() {
      showForm = false;
      editableRow = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.teal),
              SizedBox(height: 16),
              Text('Loading class data...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      // DYNAMIC AppBar - title changes based on showForm
      appBar: AppBar(
        title: Text(
          showForm 
            ? (editableRow != null ? 'Update Class & Subjects' : 'Add New Class & Subjects')
            : 'Class & Subjects'
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        // DYNAMIC leading - only show back button when form is open
        leading: showForm 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _closeForm,
              tooltip: 'Back to Class List',
            )
          : null, // null means default behavior (drawer/back based on navigation)
        actions: showForm 
          ? [] // No actions when form is open
          : [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: fetchData,
                tooltip: 'Refresh Data',
              ),
            ],
      ),
      body: showForm
          ? SaveSubjectsToClasses(
              onClose: _closeForm,
              onSave: handleSave,
              editableRowData: editableRow?.toMap(),
              getAuthToken: getAuthToken,
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Class & Subjects',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => setState(() {
                          showForm = true;
                          editableRow = null;
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Subject'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            error!,
                            style: TextStyle(color: Colors.red.shade700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: fetchData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: data.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No classes found',
                                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Click "Add Subject" to create a new class.',
                                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            )
                          : Card(
                              elevation: 2,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(Colors.teal.shade50),
                                  columns: const [
                                    DataColumn(
                                      label: Text('Class Name', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    DataColumn(
                                      label: Text('Subjects', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    DataColumn(
                                      label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                  rows: data.map((item) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            item.className,
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            constraints: const BoxConstraints(maxWidth: 300),
                                            child: Text(
                                              item.subjectList.join(', '),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.orange),
                                                onPressed: () => handleEdit(item),
                                                tooltip: 'Edit Class',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () => deleteClass(item.className),
                                                tooltip: 'Delete Class',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                    ),
                ],
              ),
            ),
    );
  }
}

// Updated SaveSubjectsToClasses without its own header
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
    }
  }

  void handleSaveCallback() {
    if (widget.onSave != null) {
      widget.onSave!();
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

    final response = await http.post(
      Uri.parse('$baseUrl/class/save'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to save class: ${response.statusCode}');
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

    final response = await http.post(
      Uri.parse('$baseUrl/class/edit?className=${Uri.encodeComponent(className)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized: Please login again');
    } else {
      throw Exception('Failed to update class: ${response.statusCode}');
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
      selectedClass = trimmedClass; // Auto-select the new class
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
    // NO HEADER - sirf form content
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class Selection
          const Text(
            "Select Class:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedClass.isEmpty ? null : selectedClass,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: "Select a Class",
              prefixIcon: const Icon(Icons.class_, color: Colors.teal),
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
            const Text(
              "Or Add New Class:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: "Enter new class name",
                      prefixIcon: const Icon(Icons.add, color: Colors.teal),
                    ),
                    onChanged: (value) => setState(() => newClass = value),
                    onSubmitted: (_) => handleAddNewClass(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: handleAddNewClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Add"),
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
            
            // Selected subjects preview
            if (selectedSubjects.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  border: Border.all(color: Colors.teal.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Selected Subjects (${selectedSubjects.length}):",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: selectedSubjects.map((subject) {
                        return Chip(
                          label: Text(subject),
                          backgroundColor: Colors.teal.shade100,
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => handleSubjectToggle(subject),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Available subjects grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: availableSubjects.length,
                      itemBuilder: (context, index) {
                        final subject = availableSubjects[index];
                        final isSelected = selectedSubjects.contains(subject);
                        return InkWell(
                          onTap: () => handleSubjectToggle(subject),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.teal.shade100 : Colors.grey.shade100,
                              border: Border.all(
                                color: isSelected ? Colors.teal : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (bool? value) => handleSubjectToggle(subject),
                                  activeColor: Colors.teal,
                                ),
                                Expanded(
                                  child: Text(
                                    subject,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                      color: isSelected ? Colors.teal.shade700 : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Add Custom Subject
                    const Text(
                      "Add Custom Subject:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: "Enter new subject name",
                              prefixIcon: const Icon(Icons.subject, color: Colors.teal),
                            ),
                            onChanged: (value) => setState(() => customSubject = value),
                            onSubmitted: (_) => handleAddCustomSubject(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: handleAddCustomSubject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text("Add"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.class_, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "Please select a class to continue",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: handleClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.cancel),
                  label: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: loading || selectedClass.isEmpty || selectedSubjects.isEmpty
                      ? null
                      : (widget.editableRowData != null ? handleUpdateClass : handleSaveNewClass),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: loading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(widget.editableRowData != null ? Icons.update : Icons.save),
                  label: Text(
                    loading 
                        ? "Saving..." 
                        : (widget.editableRowData != null ? "Update" : "Save"),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}