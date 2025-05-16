import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sms_apk/Screens/homeScreen.dart';
import 'package:sms_apk/widgets/custom_popup.dart';
import 'package:sms_apk/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:sms_apk/widgets/header.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List notifications = [];
  bool isLoading = true;
  List filteredNotifications = [];

  List<String> categories = [
    "Select a category",
    "All Categories",
    "student",
    "teacher",
    "staff",
    "holiday",
    "exam",
    "event"
  ];

  String selectedCategory = "Select a category";

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

      if (DateFormat("dd/MM/yyyy")
          .parse(endDate)
          .isBefore(DateFormat("dd/MM/yyyy").parse(startDate))) {
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
    String selectedCategory = "All ";
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
                  /*----------------------------------------------------------------------------*/
                 const Text("Start Date",
    style: TextStyle(color: AppColors.primary)),
TextField(
  readOnly: true,
  onTap: () async {
    DateTime currentDate = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate, // Start from today
      firstDate: currentDate, // Restrict past dates
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.light(primary: AppColors.primary),
            buttonTheme:
                ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setDialogState(() {
        startDate = picked;
        // Reset endDate if it is before startDate
        if (endDate != null && endDate!.isBefore(startDate!)) {
          endDate = null;
        }
      });
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
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.primary),
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide:
          BorderSide(color: AppColors.primary, width: 2),
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
    if (startDate == null) {
      // Ensure the user selects a start date first
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a start date first!")),
      );
      return;
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate!, // Default to Start Date
      firstDate: startDate!, // Ensure End Date is after Start Date
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.light(primary: AppColors.primary),
            buttonTheme:
                ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
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
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.primary),
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide:
          BorderSide(color: AppColors.primary, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),
  ),
),

                  /*--------------------------------------------------------------------*/
                  const SizedBox(height: 10),
                  const Text("Category",
                      style: TextStyle(color: AppColors.primary)),
                  Column(
                    children: [
                      "All",
                      "Student",
                      "Teacher",
                      "Staff",
                      "Event",
                      "Holiday",
                      "Exam"
                    ]
                        .map((category) => RadioListTile(
                              title: Text(category,
                                  style: const TextStyle(
                                      color: AppColors.primary)),
                              value: category,
                              groupValue: selectedCategory,
                              activeColor:
                                  AppColors.primary, // Set radio button color
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedCategory = value
                                      as String; // Update selected category
                                });
                              },
                            ))
                        .toList(),
                  ),
                  if (selectedCategory == "Student" ||
                      selectedCategory == "Exam") ...[
                    const SizedBox(height: 10),
                    const Text("Classes",
                        style: TextStyle(color: AppColors.primary)),
                    Column(
                      children: [
                        "LKG",
                        "UKG",
                        "Class 1",
                        "Class 2",
                        "Class 3",
                        "Class 4",
                        "Class 5",
                        "Class 6",
                        "Class 7",
                        "Class 8",
                        "Class 9",
                        "Class 10",
                        "Class 11",
                        "Class 12"
                      ]
                          .map((className) => CheckboxListTile(
                                title: Text(className,
                                    style: const TextStyle(
                                        color: AppColors.primary)),
                                value: selectedClasses.contains(className),
                                activeColor:
                                    AppColors.primary, // Set radio button color
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
                  ],
                  TextField(
                    controller: descriptionController,
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      labelText: "Description",
                      labelStyle: const TextStyle(color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.primary, width: 2),
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

  void filterNotifications(String category) {
    setState(() {
      selectedCategory = category;
      if (category == "All Categories") {
        filteredNotifications = notifications;
      } else {
        filteredNotifications = notifications
            .where((notification) =>
                notification['cato'].toString().toLowerCase() ==
                category.toLowerCase())
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: Header(text: "Notifications"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white, // Background color
                borderRadius: BorderRadius.circular(12), // Rounded edges
                border: Border.all(
                  color: Colors.grey.shade300, // Light border for a clean look
                  width: 1, // Full width
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Soft shadow
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField(
                decoration: InputDecoration(
                  border: InputBorder.none, // Remove default border
                  contentPadding: EdgeInsets.zero,
                ),
                value: selectedCategory,
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: category == "Select a category"
                            ? Colors.grey
                            : Colors.black, // Grey for default
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value is String) {
                    filterNotifications(value);
                  }
                },
              ),
            ),
          ),

          // Add Notification Button Container
          GestureDetector(
            onTap: openAddNotificationDialog, // Opens dialog on tap
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white, // Background color
                  borderRadius: BorderRadius.circular(12), // Rounded edges
                  border: Border.all(
                    color:
                        Colors.grey.shade300, // Light border for a clean look
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), // Soft shadow
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Add Notification",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppColors.primary),
                      onPressed:
                          openAddNotificationDialog, // Also triggers on button tap
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Content (Loading, No Notifications, or List)
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filteredNotifications.isEmpty
                    ? const Center(
                        child: Text("No notifications available",
                            style: TextStyle(color: AppColors.primary)),
                      )
                    : ListView.builder(
                        itemCount: filteredNotifications.length,
                        itemBuilder: (context, index) {
                          final notification = filteredNotifications[index];
                          return _buildNotificationCard(notification);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Card(
      elevation: 4, // Shadow effect
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary, // Container background color
          borderRadius: BorderRadius.circular(12), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // Shadow color
              blurRadius: 6, // Shadow blur
              offset: const Offset(0, 3), // Shadow position
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            notification['description'] ?? 'No Description',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20, // Larger font size for title
              color: Colors.white, // Title color white
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Category: ${notification['cato'] ?? 'N/A'}",
                style: const TextStyle(
                  color: Colors.white, // Content color white
                  fontSize: 14, // Smaller font size for content
                ),
              ),
              const SizedBox(height: 4), // Spacing between lines
              Text(
                "Classes: ${(notification['className'] as List?)?.join(', ') ?? 'N/A'}",
                style: const TextStyle(
                  color: Colors.white, // Content color white
                  fontSize: 14, // Smaller font size for content
                ),
              ),
              const SizedBox(height: 4), // Spacing between lines
              Text(
                "Date: ${formatDate(DateTime.parse(notification['startDate']))} - ${formatDate(DateTime.parse(notification['endDate']))}",
                style: const TextStyle(
                  color: Colors.white, // Content color white
                  fontSize: 14, // Smaller font size for content
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
