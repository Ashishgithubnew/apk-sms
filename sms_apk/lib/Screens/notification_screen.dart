import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/Screens/homeScreen.dart';
import 'package:sms_apk/widgets/custom_popup.dart';
import 'package:sms_apk/utils/app_colors.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List notifications = [];
  bool isLoading = true;

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<void> fetchNotifications() async {
    try {
      final token = await getToken();
      if (token == null) {
        showPopup(context, "No token found. Please log in.", AppColors.error);
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
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            notifications = data;
            isLoading = false;
          });
        } else {
          showPopup(context, "Invalid response format", AppColors.error);
        }
      } else {
        showPopup(context, "Failed to load notifications", AppColors.error);
      }
    } catch (e) {
      showPopup(context, "Error fetching notifications: ${e.toString()}",
          AppColors.error);
    }
  }

  Future<void> saveNotification(String startDate, String endDate,
      String category, List<String> classes, String description) async {
    try {
      final token = await getToken();
      if (token == null) {
        showPopup(context, "No token found. Please log in.", AppColors.error);
        return;
      }

      if (DateTime.parse(endDate).isBefore(DateTime.parse(startDate))) {
        showPopup(
            context, "End date cannot be before start date", AppColors.error);
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
        showPopup(
            context, "Notification saved successfully!", AppColors.success);
        fetchNotifications();
      } else {
        showPopup(context, "Failed to save notification", AppColors.error);
      }
    } catch (e) {
      showPopup(context, "Error saving notification: ${e.toString()}",
          AppColors.error);
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
        title: const Text("Add Notification",
            style: TextStyle(color: AppColors.primary)),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Start Date",
                      style: TextStyle(color: AppColors.primary)),
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
                      suffixIcon: const Icon(Icons.calendar_today,
                          color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("End Date",
                      style: TextStyle(color: AppColors.primary)),
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
                      suffixIcon: const Icon(Icons.calendar_today,
                          color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Classes",
                      style: TextStyle(color: AppColors.primary)),
                  Column(
                    children: ["LKG", "UKG", "Class 1", "Class 2", "Class 3"]
                        .map((className) => CheckboxListTile(
                              title: Text(className,
                                  style: const TextStyle(
                                      color: AppColors.primary)),
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
                    decoration: InputDecoration(
                      labelText: "Description",
                      labelStyle: const TextStyle(color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",
                style: TextStyle(color: AppColors.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (startDate == null ||
                  endDate == null ||
                  descriptionController.text.isEmpty) {
                showPopup(context, "Please fill all fields", AppColors.error);
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
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
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context); // Navigate back if possible
            } else {
              // Fallback navigation (e.g., navigate to home screen)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: openAddNotificationDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : notifications.isEmpty
              ? const Center(
                  child: Text("No notifications available",
                      style: TextStyle(color: AppColors.primary)),
                )
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(notification);
                  },
                ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          notification['description'] ?? 'No Description',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.primary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Category: ${notification['cato'] ?? 'N/A'}",
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              "Classes: ${(notification['className'] as List?)?.join(', ') ?? 'N/A'}",
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              "Date: ${notification['startDate']} - ${notification['endDate']}",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
