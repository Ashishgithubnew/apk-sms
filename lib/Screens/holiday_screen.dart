import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HolidayPage extends StatefulWidget {
  const HolidayPage({super.key});

  @override
  _HolidayPageState createState() => _HolidayPageState();
}

class _HolidayPageState extends State<HolidayPage> {
  List<Holiday> holidays = [];
  bool isLoading = true;
  bool showForm = false;

  final List<String> classes = [
    'Nursery',
    'LKG',
    'UKG',
    ...List.generate(12, (index) => 'Class ${index + 1}'),
  ];

  @override
  void initState() {
    super.initState();
    loadHolidays();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> loadHolidays() async {
    try {
      setState(() => isLoading = true);
      final token = await getToken();
      
      final response = await http.get(
        Uri.parse("https://s-m-s-keyw.onrender.com/holiday/get"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Holiday> loadedHolidays = [];
        
        for (var holiday in data) {
          for (var dateEntry in holiday['date']) {
            loadedHolidays.add(Holiday(
              id: dateEntry['id'] ?? 'N/A',
              startDate: formatDate(DateTime.parse(dateEntry['startDate'])),
              endDate: formatDate(DateTime.parse(dateEntry['endDate'])),
              description: dateEntry['description'] ?? 'No description',
              className: (holiday['className'] as List).join(', '),
            ));
          }
        }
        
        setState(() {
          holidays = loadedHolidays;
          isLoading = false;
        });
      } else {
        showError("Failed to load holidays");
      }
    } catch (e) {
      showError("Error: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveHoliday({
    required List<String> selectedClasses,
    required DateTime startDate,
    required DateTime endDate,
    required String description,
  }) async {
    try {
      final token = await getToken();

      if (endDate.isBefore(startDate)) {
        showError("End date cannot be before start date");
        return;
      }

      String formatDate(DateTime date) {
        return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
      }

      final payload = {
        "className": selectedClasses,
        "date": [
          {
            "id": "",
            "startDate": formatDate(startDate),
            "endDate": formatDate(endDate),
            "description": description,
          }
        ],
      };

      final response = await http.post(
        Uri.parse("https://s-m-s-keyw.onrender.com/holiday/save"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        showSuccess("Holiday saved successfully!");
        await loadHolidays();
        setState(() => showForm = false);
      } else {
        showError("Failed to save holiday: ${response.body}");
      }
    } catch (e) {
      showError("Error: ${e.toString()}");
    }
  }

  Future<void> deleteHoliday(String id) async {
    try {
      final token = await getToken();
      
      final url = Uri.parse("https://s-m-s-keyw.onrender.com/holiday/delete").replace(
        queryParameters: {'id': id},
      );
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: null,
      );

      if (response.statusCode == 200) {
        showSuccess("Holiday deleted successfully!");
        await loadHolidays();
      } else {
        showError("Failed to delete holiday: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      showError("Error: ${e.toString()}");
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(showForm ? "Add Holiday" : "Holidays"),
        backgroundColor: const Color(0xFF126666), // Teal color
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 30,
        ),
        toolbarHeight: 70,
        // Only show the add button when not in form view
        actions: [
          if (!showForm)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => setState(() => showForm = true),
            ),
        ],
        // Show back button when in form view
        leading: showForm 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => showForm = false),
              )
            : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : showForm
              ? HolidayForm(
                  classes: classes,
                  onSave: saveHoliday,
                  onCancel: () => setState(() => showForm = false),
                )
              : holidays.isEmpty
                  ? const Center(child: Text("No holidays found"))
                  : ListView.builder(
                      itemCount: holidays.length,
                      itemBuilder: (context, index) {
                        final holiday = holidays[index];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(holiday.description),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Class: ${holiday.className}"),
                                Text("Start: ${holiday.startDate}"),
                                Text("End: ${holiday.endDate}"),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Delete Holiday"),
                                    content: Text("Delete ${holiday.description}?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          deleteHoliday(holiday.id);
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
                        );
                      },
                    ),
      floatingActionButton: !showForm && holidays.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => setState(() => showForm = true),
              backgroundColor: const Color(0xFF126666), // Teal color
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

class HolidayForm extends StatefulWidget {
  final List<String> classes;
  final Function({
    required List<String> selectedClasses,
    required DateTime startDate,
    required DateTime endDate,
    required String description,
  }) onSave;
  final VoidCallback onCancel;

  const HolidayForm({
    required this.classes,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  @override
  _HolidayFormState createState() => _HolidayFormState();
}

class _HolidayFormState extends State<HolidayForm> {
  List<String> selectedClasses = [];
  DateTime? startDate;
  DateTime? endDate;
  final descriptionController = TextEditingController();
  bool selectAll = false;

  @override
  Widget build(BuildContext context) {
    // Removed the Scaffold and AppBar from here
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ExpansionTile(
            title: const Text("Select Classes", style: TextStyle(fontSize: 16)),
            initiallyExpanded: true,
            children: [
              CheckboxListTile(
                title: const Text("All Classes"),
                value: selectAll,
                onChanged: (value) {
                  setState(() {
                    selectAll = value!;
                    selectedClasses = selectAll ? [...widget.classes] : [];
                  });
                },
              ),
              SizedBox(
                height: 200,
                child: ListView(
                  children: widget.classes.map((className) => CheckboxListTile(
                    title: Text(className),
                    value: selectedClasses.contains(className),
                    onChanged: (value) {
                      setState(() {
                        if (value!) {
                          selectedClasses.add(className);
                        } else {
                          selectedClasses.remove(className);
                          selectAll = false;
                        }
                      });
                    },
                  )).toList(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Start Date",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: startDate != null 
                        ? DateFormat('dd/MM/yyyy').format(startDate!) 
                        : '',
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => startDate = picked);
                      if (endDate != null && endDate!.isBefore(picked)) {
                        setState(() => endDate = null);
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "End Date",
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: endDate != null 
                        ? DateFormat('dd/MM/yyyy').format(endDate!) 
                        : '',
                  ),
                  onTap: () async {
                    if (startDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select start date first")),
                      );
                      return;
                    }
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate!,
                      firstDate: startDate!,
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => endDate = picked);
                    }
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: "Description",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text("CANCEL"),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  if (selectedClasses.isEmpty ||
                      startDate == null ||
                      endDate == null ||
                      descriptionController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }
                  widget.onSave(
                    selectedClasses: selectedClasses,
                    startDate: startDate!,
                    endDate: endDate!,
                    description: descriptionController.text,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF126666), // Teal color
                ),
                child: const Text("SAVE", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Holiday {
  final String id;
  final String startDate;
  final String endDate;
  final String description;
  final String className;

  Holiday({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.className,
  });
}
