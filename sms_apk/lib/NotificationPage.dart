import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List notifications = [];
  bool isLoading = true;

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> fetchNotifications() async {
    try {
      final token = await getToken();
      if (token == null) {
        showError("No token found. Please log in.");
        return;
      }

      final response = await http.get(
        Uri.parse(
            "https://s-m-s-keyw.onrender.com/notification/getAllNotification"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          notifications = data;
          isLoading = false;
        });
      } else {
        showError("Failed to load notifications");
      }
    } catch (e) {
      showError("Error fetching notifications: ${e.toString()}");
    }
  }

  Future<void> saveNotification(String startDate, String endDate,
      String category, List<String> classes, String description) async {
    try {
      final token = await getToken();
      if (token == null) {
        showError("No token found. Please log in.");
        return;
      }

      Map<String, dynamic> requestBody = {
        "startDate": startDate,
        "endDate": endDate,
        "description": description,
        "cato": category,
        "className": classes,
      };

      final response = await http.post(
        Uri.parse("https://s-m-s-keyw.onrender.com/notification/save"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        showSuccess("Notification saved successfully!");
        fetchNotifications();
      } else {
        showError("Failed to save notification");
      }
    } catch (e) {
      showError("Error saving notification: ${e.toString()}");
    }
  }

  void openAddNotificationDialog() {
    DateTime? startDate;
    DateTime? endDate;
    String selectedCategory = "All";
    List<String> selectedClasses = [];
    TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Notification"),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Start Date"),
                  TextField(
                    readOnly: true,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => startDate = picked);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: startDate == null
                          ? "Pick a date"
                          : formatDate(startDate!),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("End Date"),
                  TextField(
                    readOnly: true,
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => endDate = picked);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: endDate == null
                          ? "Pick a date"
                          : formatDate(endDate!),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text("Classes"),
                  Column(
                    children: ["LKG", "UKG", "Class 1", "Class 2", "Class 3"]
                        .map((className) => CheckboxListTile(
                              title: Text(className),
                              value: selectedClasses.contains(className),
                              onChanged: (isSelected) {
                                setDialogState(() {
                                  if (isSelected == true) {
                                    selectedClasses.add(className);
                                  } else {
                                    selectedClasses.remove(className);
                                  }
                                });
                              },
                            ))
                        .toList(),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: "Description"),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (startDate == null ||
                  endDate == null ||
                  descriptionController.text.isEmpty) {
                showError("Please fill all fields");
                return;
              }
              saveNotification(
                formatDate(startDate!),
                formatDate(endDate!),
                selectedCategory,
                selectedClasses,
                descriptionController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: openAddNotificationDialog,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(child: Text("No notifications available"))
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return ListTile(
                        title: Text(
                            notification['description'] ?? 'No Description'),
                        subtitle: Text(
                            "Category: ${notification['cato'] ?? 'N/A'}\nClasses: ${(notification['className'] as List?)?.join(', ') ?? 'N/A'}\nDate: ${notification['startDate']} - ${notification['endDate']}"));
                  },
                ),
    );
  }
}
