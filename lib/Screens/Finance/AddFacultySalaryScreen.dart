import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddFacultySalaryScreen extends StatefulWidget {
  const AddFacultySalaryScreen({super.key});

  @override
  State<AddFacultySalaryScreen> createState() => _AddFacultySalaryScreenState();
}

class _AddFacultySalaryScreenState extends State<AddFacultySalaryScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedFacultyEmail;
  String _facultyId = '';
  String _facultyName = '';
  TextEditingController _salaryAmountController = TextEditingController();
  TextEditingController _taxController = TextEditingController();
  TextEditingController _transportAllowanceController = TextEditingController();
  String _paymentMode = 'Cash'; // Default value

  List<dynamic> _facultyEmails = [];
  bool _isLoadingEmails = true;
  bool _isSavingSalary = false;
  String? _taxErrorText;

  // New: List to hold controllers for dynamic deduction fields
  List<DeductionField> _deductionFields = [];

  @override
  void initState() {
    super.initState();
    _fetchFacultyEmails();

    _taxController.addListener(_validateTaxInput);
    // Initialize with one deduction field
    _addDeductionField();
  }

  @override
  void dispose() {
    _salaryAmountController.dispose();
    _taxController.dispose();
    _transportAllowanceController.dispose();
    // Dispose all dynamic deduction controllers
    for (var field in _deductionFields) {
      field.nameController.dispose();
      field.amountController.dispose();
    }
    super.dispose();
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> _fetchFacultyEmails() async {
    setState(() {
      _isLoadingEmails = true;
    });
    final token = await _getToken();
    final url = Uri.parse("https://s-m-s-keyw.onrender.com/faculty/findAllFaculty");
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _facultyEmails = data;
          _isLoadingEmails = false;
        });
      } else {
        print('Failed to load faculty emails: ${response.statusCode}');
        setState(() {
          _isLoadingEmails = false;
        });
      }
    } catch (e) {
      print('Error fetching faculty emails: $e');
      setState(() {
        _isLoadingEmails = false;
      });
    }
  }

  void _onEmailSelected(String? email) {
    setState(() {
      _selectedFacultyEmail = email;
      if (email != null) {
        final selectedFaculty = _facultyEmails.firstWhere(
          (faculty) => faculty['fact_email'] == email,
          orElse: () => null,
        );
        if (selectedFaculty != null) {
          _facultyId = selectedFaculty['fact_id'] ?? '';
          _facultyName = selectedFaculty['fact_Name'] ?? '';
        } else {
          _facultyId = '';
          _facultyName = '';
        }
      } else {
        _facultyId = '';
        _facultyName = '';
      }
    });
  }

  void _validateTaxInput() {
    final text = _taxController.text;
    if (text.isNotEmpty) {
      try {
        final value = double.parse(text);
        if (value < 0) {
          setState(() {
            _taxErrorText = 'Tax cannot be negative';
          });
        } else {
          setState(() {
            _taxErrorText = null;
          });
        }
      } catch (e) {
        setState(() {
          _taxErrorText = 'Invalid number';
        });
      }
    } else {
      setState(() {
        _taxErrorText = null;
      });
    }
  }

  void _addDeductionField() {
    setState(() {
      _deductionFields.add(DeductionField());
    });
  }

  void _removeDeductionField(int index) {
    setState(() {
      _deductionFields[index].nameController.dispose();
      _deductionFields[index].amountController.dispose();
      _deductionFields.removeAt(index);
    });
  }

  Future<void> _saveFacultySalary() async {
    if (_formKey.currentState!.validate() && _taxErrorText == null) {
      setState(() {
        _isSavingSalary = true;
      });

      final token = await _getToken();
      final url = Uri.parse("https://s-m-s-keyw.onrender.com/faculty/salary/save");

      List<Map<String, dynamic>> deductions = [];
      for (var field in _deductionFields) {
        if (field.nameController.text.isNotEmpty && field.amountController.text.isNotEmpty) {
          deductions.add({
            "name": field.nameController.text,
            "amount": double.tryParse(field.amountController.text) ?? 0.0,
          });
        }
      }

      final body = json.encode({
        "facultyID": _facultyId,
        "facultySalary": double.tryParse(_salaryAmountController.text) ?? 0.0,
        "facultyTax": double.tryParse(_taxController.text) ?? 0.0,
        "facultyTransport": double.tryParse(_transportAllowanceController.text) ?? 0.0,
        "facultyDeduction": deductions,
        "paymentMode": _paymentMode,
      });

      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: body,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Faculty salary added successfully!')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add faculty salary: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving faculty salary: $e')),
        );
      } finally {
        setState(() {
          _isSavingSalary = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Faculty Salary'),
           backgroundColor: Color(0xFF3a8686),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _isLoadingEmails
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Email',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedFacultyEmail,
                      items: _facultyEmails.map<DropdownMenuItem<String>>((faculty) {
                        return DropdownMenuItem<String>(
                          value: faculty['fact_email'],
                          child: Text(faculty['fact_email'] ?? 'N/A'),
                        );
                      }).toList(),
                      onChanged: _onEmailSelected,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an email';
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: TextEditingController(text: _facultyId),
                decoration: const InputDecoration(
                  labelText: 'Faculty ID',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: TextEditingController(text: _facultyName),
                decoration: const InputDecoration(
                  labelText: 'Faculty Name',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _salaryAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Salary Amount',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter salary amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) < 0) {
                    return 'Salary cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _taxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tax (%)',
                  border: const OutlineInputBorder(),
                  errorText: _taxErrorText,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter tax percentage';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _transportAllowanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Transport Allowance',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter transport allowance';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) < 0) {
                    return 'Transport allowance cannot be negative';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              const Text('Other Fees (Deductions):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              ListView.builder(
                shrinkWrap: true, // Important for nested list views
                physics: const NeverScrollableScrollPhysics(), // To prevent scrolling issues
                itemCount: _deductionFields.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _deductionFields[index].nameController,
                            decoration: InputDecoration(
                              labelText: 'Deduction Name ${index + 1}',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_deductionFields[index].amountController.text.isNotEmpty && (value == null || value.isEmpty)) {
                                return 'Enter name for deduction';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: TextFormField(
                            controller: _deductionFields[index].amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Amount ${index + 1}',
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_deductionFields[index].nameController.text.isNotEmpty && (value == null || value.isEmpty)) {
                                return 'Enter amount for deduction';
                              }
                              if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                return 'Invalid amount';
                              }
                              if (value != null && value.isNotEmpty && double.parse(value) < 0) {
                                return 'Amount cannot be negative';
                              }
                              return null;
                            },
                          ),
                        ),
                        if (_deductionFields.length > 1) // Only show remove button if there's more than one field
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeDeductionField(index),
                          ),
                      ],
                    ),
                  );
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _addDeductionField,
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  label: const Text('Add More Deduction'),
                ),
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                  border: OutlineInputBorder(),
                ),
                value: _paymentMode,
                items: <String>['Cash', 'Bank Transfer', 'Cheque']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _paymentMode = newValue!;
                  });
                },
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16.0),
                  ElevatedButton(
                    onPressed: _isSavingSalary ? null : _saveFacultySalary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSavingSalary
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save'),
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

// Helper class to hold controllers for each deduction field
class DeductionField {
  final TextEditingController nameController;
  final TextEditingController amountController;

  DeductionField()
      : nameController = TextEditingController(),
        amountController = TextEditingController();
}