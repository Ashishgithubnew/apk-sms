import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Import student_fees_screen.dart to access Student and FamilyDetails classes
import 'student_fees_screen.dart';

class AddFeesScreen extends StatefulWidget {
  const AddFeesScreen({Key? key}) : super(key: key);

  @override
  State<AddFeesScreen> createState() => _AddFeesScreenState();
}

class _AddFeesScreenState extends State<AddFeesScreen> {
  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  Student? _selectedStudent;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _feeAmountController = TextEditingController();
  String? _selectedPaymentMode = 'UPI'; // Default payment mode
  final List<String> _paymentModes = ['UPI', 'Cash', 'Card', 'Bank Transfer'];
  String? _selectedClassFilter;
  final List<String> _classFilters = [
    'Nursery',
    'LKG',
    'UKG',
    '1st',
    '2nd',
    '3rd',
    '4th',
    '5th',
    '6th',
    '7th',
    '8th',
    '9th',
    '10th',
    '11th',
    '12th'
  ]; // Example classes

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStudents);
    _searchController.dispose();
    _feeAmountController.dispose();
    super.dispose();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> _fetchStudents() async {
    try {
      final token = await getToken();
      final url = Uri.parse('https://s-m-s-keyw.onrender.com/student/findAllStudent');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        setState(() {
          _allStudents =
              jsonList.map((json) => Student.fromJson(json)).toList();
          _filteredStudents =
              _allStudents; // Initialize filtered students with all students
        });
      } else {
        throw Exception('Failed to load students: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) { // Check if the widget is still mounted before showing SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load students: $e')),
        );
      }
    }
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final matchesName = student.name.toLowerCase().contains(query);
        final matchesClass = _selectedClassFilter == null ||
            student.cls?.toLowerCase() == _selectedClassFilter!.toLowerCase();
        return matchesName && matchesClass;
      }).toList();
      // If the selected student is no longer in the filtered list, deselect them
      if (_selectedStudent != null &&
          !_filteredStudents.contains(_selectedStudent)) {
        _selectedStudent = null;
      }
    });
  }

  void _applyClassFilter(String? className) {
    setState(() {
      _selectedClassFilter = className;
      _filterStudents(); // Re-filter based on the new class selection
    });
  }

  Future<void> _submitFee() async {
    // Dismiss the keyboard if it's open
    FocusScope.of(context).unfocus();

    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student.')),
      );
      return;
    }
    if (_feeAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter fee amount.')),
      );
      return;
    }
    if (_selectedPaymentMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment mode.')),
      );
      return;
    }

    final feeAmount = double.tryParse(_feeAmountController.text);
    if (feeAmount == null || feeAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid fee amount.')),
      );
      return;
    }

    final token = await getToken();
    final url = Uri.parse('https://s-m-s-keyw.onrender.com/student/saveFees');
    final payload = json.encode({
      "id": _selectedStudent!.id,
      "fee": feeAmount,
      "paymentMode": _selectedPaymentMode,
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: payload,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fee submitted successfully!')),
          );
          Navigator.pop(context, true); // Pop with true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to submit fee: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting fee: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Fees Page'),
        backgroundColor: Color(0xFF3a8686),
        foregroundColor: Colors.white, // Teal color
        centerTitle: true,
      
      ),
      body: GestureDetector( // Added GestureDetector to dismiss keyboard on tap outside
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search by Name',
                        hintText: 'Search student name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedClassFilter,
                      decoration: const InputDecoration(
                        labelText: 'Filter by Class',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Classes'),
                        ),
                        ..._classFilters.map((cls) => DropdownMenuItem(
                              value: cls,
                              child: Text(cls),
                            )),
                      ],
                      onChanged: (value) {
                        // Dismiss keyboard before changing dropdown value
                        FocusScope.of(context).unfocus();
                        _applyClassFilter(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Student>(
                value: _selectedStudent,
                decoration: const InputDecoration(
                  labelText: 'Select Student',
                  border: OutlineInputBorder(),
                ),
                onChanged: (Student? newValue) {
                  // Dismiss keyboard before changing dropdown value
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _selectedStudent = newValue;
                  });
                },
                items: _filteredStudents.map<DropdownMenuItem<Student>>(
                  (Student student) {
                    return DropdownMenuItem<Student>(
                      value: student,
                      child: Text('${student.name} (${student.email ?? 'No Email'})'),
                    );
                  },
                ).toList(),
                isExpanded: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMode,
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  border: OutlineInputBorder(),
                ),
                onChanged: (String? newValue) {
                  // Dismiss keyboard before changing dropdown value
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _selectedPaymentMode = newValue;
                  });
                },
                items: _paymentModes.map<DropdownMenuItem<String>>(
                  (String mode) {
                    return DropdownMenuItem<String>(
                      value: mode,
                      child: Text(mode),
                    );
                  },
                ).toList(),
                isExpanded: true,
              ),
              const SizedBox(height: 24),
              if (_selectedStudent != null) ...[
                Text('Student Name: ${_selectedStudent!.name}',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                    'Father Name: ${_selectedStudent!.familyDetails?.stdo_FatherName ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                    'Remaining Fees: ₹${_selectedStudent!.remainingFees.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _feeAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fee Amount',
                  hintText: 'Enter fee amount',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _submitFee,
                    style: ElevatedButton.styleFrom( // Corrected style
                      backgroundColor: Colors.teal[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Submit Fee'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () {
                      // Dismiss keyboard before navigating back
                      FocusScope.of(context).unfocus();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}