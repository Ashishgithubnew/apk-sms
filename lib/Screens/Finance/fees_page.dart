import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FeesPage extends StatefulWidget {
  const FeesPage({super.key});

  @override
  _FeesPageState createState() => _FeesPageState();
}

class _FeesPageState extends State<FeesPage> {
  List<Fee> fees = [];
  bool isLoading = true;

  final List<String> classes = [
    'Nursery',
    'LKG',
    'UKG',
    ...List.generate(12, (index) => 'Class ${index + 1}'),
  ];

  @override
  void initState() {
    super.initState();
    loadFees();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> loadFees() async {
    try {
      setState(() => isLoading = true);
      final token = await getToken();

      final response = await http.get(
        Uri.parse("https://s-m-s-keyw.onrender.com/admin/getAll"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Fee> loadedFees = [];

        for (var fee in data) {
          loadedFees.add(Fee.fromJson(fee));
        }

        setState(() {
          fees = loadedFees;
          isLoading = false;
        });
      } else {
        showError("Failed to load fees (Status: ${response.statusCode})");
      }
    } catch (e) {
      showError("Error: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveFee({
    required String className,
    required double schoolFee,
    required double sportsFee,
    required double bookFee,
    required double transportation,
    required List<OtherAmount> otherAmounts,
  }) async {
    try {
      final token = await getToken();

      final Map<String, dynamic> payload = {
        "className": className,
        "schoolFee": schoolFee,
        "sportsFee": sportsFee,
        "bookFee": bookFee,
        "transportation": transportation,
        "otherAmount": otherAmounts.map((e) => e.toJson()).toList(),
        "totalFee": schoolFee +
            sportsFee +
            bookFee +
            transportation +
            otherAmounts.fold(0, (sum, e) => sum + e.amount),
      };

      final response = await http.post(
        Uri.parse("https://s-m-s-keyw.onrender.com/admin/save"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        showSuccess("Fee added successfully!");
        await loadFees();
      } else {
        showError("Failed to add fee: ${response.body}");
      }
    } catch (e) {
      showError("Error: ${e.toString()}");
    }
  }

  Future<void> deleteFee(String id) async {
    try {
      final token = await getToken();

      final url = Uri.parse("https://s-m-s-keyw.onrender.com/admin/delete")
          .replace(queryParameters: {'id': id});

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        showSuccess("Fee deleted successfully!");
        await loadFees();
      } else {
        showError("Failed to delete fee: ${response.body}");
      }
    } catch (e) {
      showError("Error: ${e.toString()}");
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // Navigate to form page
  void _navigateToForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeesFormPage(
          classes: classes,
          onSave: saveFee,
        ),
      ),
    );
    
    // Refresh the list if a fee was added
    if (result == true) {
      loadFees();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fees"),
        backgroundColor: Color(0xFF3a8686),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _navigateToForm,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : fees.isEmpty
              ? const Center(child: Text("No fees found"))
              : ListView.builder(
                  itemCount: fees.length,
                  itemBuilder: (context, index) {
                    final fee = fees[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Class: ${fee.className}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            const SizedBox(height: 6),
                            Text("School Fee: ₹${fee.schoolFee}"),
                            Text("Sports Fee: ₹${fee.sportsFee}"),
                            Text("Book Fee: ₹${fee.bookFee}"),
                            Text("Transportation Fee: ₹${fee.transportation}"),
                            if (fee.otherAmount.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              const Text("Other Amounts:",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              ...fee.otherAmount.map((other) => Text(
                                  " - ${other.name.isEmpty ? '(no name)' : other.name}: ₹${other.amount}")),
                            ],
                            const SizedBox(height: 6),
                            Text("Total Fee: ₹${fee.totalFee}",
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold)),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Delete Fee"),
                                      content:
                                          Text("Delete fees for ${fee.className}?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            deleteFee(fee.id);
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text("Delete"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: fees.isNotEmpty
          ? FloatingActionButton(
              onPressed: _navigateToForm,
              backgroundColor: const Color(0xFF126666),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// Separate page for the form
class FeesFormPage extends StatefulWidget {
  final List<String> classes;
  final Function({
    required String className,
    required double schoolFee,
    required double sportsFee,
    required double bookFee,
    required double transportation,
    required List<OtherAmount> otherAmounts,
  }) onSave;

  const FeesFormPage({
    required this.classes,
    required this.onSave,
    super.key,
  });

  @override
  _FeesFormPageState createState() => _FeesFormPageState();
}

class _FeesFormPageState extends State<FeesFormPage> {
  String? selectedClass;
  final TextEditingController schoolFeeController = TextEditingController();
  final TextEditingController sportsFeeController = TextEditingController();
  final TextEditingController bookFeeController = TextEditingController();
  final TextEditingController transportationController = TextEditingController();

  List<OtherAmountField> otherAmountFields = [];

  @override
  void initState() {
    super.initState();
    otherAmountFields.add(OtherAmountField());
  }

  @override
  void dispose() {
    schoolFeeController.dispose();
    sportsFeeController.dispose();
    bookFeeController.dispose();
    transportationController.dispose();
    for (var field in otherAmountFields) {
      field.nameController.dispose();
      field.amountController.dispose();
    }
    super.dispose();
  }

  double _parseDouble(String text) {
    return double.tryParse(text) ?? 0;
  }

  void _addOtherAmountField() {
    setState(() {
      otherAmountFields.add(OtherAmountField());
    });
  }

  void _removeOtherAmountField(int index) {
    setState(() {
      otherAmountFields[index].nameController.dispose();
      otherAmountFields[index].amountController.dispose();
      otherAmountFields.removeAt(index);
    });
  }

  void _saveFee() async {
    if (selectedClass == null || schoolFeeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    List<OtherAmount> otherAmounts = [];
    for (var field in otherAmountFields) {
      String name = field.nameController.text.trim();
      double amount = _parseDouble(field.amountController.text);
      if (name.isNotEmpty || amount > 0) {
        otherAmounts.add(OtherAmount(name: name, amount: amount));
      }
    }

    await widget.onSave(
      className: selectedClass!,
      schoolFee: _parseDouble(schoolFeeController.text),
      sportsFee: _parseDouble(sportsFeeController.text),
      bookFee: _parseDouble(bookFeeController.text),
      transportation: _parseDouble(transportationController.text),
      otherAmounts: otherAmounts,
    );

    // Return true to indicate success
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Fee"),
        backgroundColor: Color(0xFF3a8686),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedClass,
              decoration: const InputDecoration(
                labelText: "Select Class",
                border: OutlineInputBorder(),
              ),
              items: widget.classes.map((className) {
                return DropdownMenuItem(
                  value: className,
                  child: Text(className),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedClass = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: schoolFeeController,
              decoration: const InputDecoration(
                labelText: "School Fee (₹)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: sportsFeeController,
              decoration: const InputDecoration(
                labelText: "Sports Fee (₹)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bookFeeController,
              decoration: const InputDecoration(
                labelText: "Book Fee (₹)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: transportationController,
              decoration: const InputDecoration(
                labelText: "Transportation Fee (₹)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Other Amounts",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: _addOtherAmountField,
                  icon: const Icon(Icons.add),
                  label: const Text("Add"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 224, 236, 236),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: otherAmountFields.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: TextField(
                          controller: otherAmountFields[index].nameController,
                          decoration: const InputDecoration(
                            labelText: "Name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: otherAmountFields[index].amountController,
                          decoration: const InputDecoration(
                            labelText: "Amount (₹, optional)",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          _removeOtherAmountField(index);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _saveFee,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 224, 236, 236),
                  ),
                  child: const Text("SAVE"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Keep the existing classes unchanged
class OtherAmountField {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
}

class Fee {
  final String id;
  final String className;
  final double schoolFee;
  final double sportsFee;
  final double bookFee;
  final double transportation;
  final List<OtherAmount> otherAmount;
  final double totalFee;

  Fee({
    required this.id,
    required this.className,
    required this.schoolFee,
    required this.sportsFee,
    required this.bookFee,
    required this.transportation,
    required this.otherAmount,
    required this.totalFee,
  });

  factory Fee.fromJson(Map<String, dynamic> json) {
    var others = <OtherAmount>[];
    if (json['otherAmount'] != null) {
      others = (json['otherAmount'] as List)
          .map((e) => OtherAmount.fromJson(e))
          .toList();
    }
    return Fee(
      id: json['id'] ?? '',
      className: json['className'] ?? '',
      schoolFee: (json['schoolFee'] ?? 0).toDouble(),
      sportsFee: (json['sportsFee'] ?? 0).toDouble(),
      bookFee: (json['bookFee'] ?? 0).toDouble(),
      transportation: (json['transportation'] ?? 0).toDouble(),
      otherAmount: others,
      totalFee: (json['totalFee'] ?? 0).toDouble(),
    );
  }
}

class OtherAmount {
  final String name;
  final double amount;

  OtherAmount({required this.name, required this.amount});

  Map<String, dynamic> toJson() => {
        "name": name,
        "amount": amount,
      };

  factory OtherAmount.fromJson(Map<String, dynamic> json) {
    return OtherAmount(
      name: json['name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}