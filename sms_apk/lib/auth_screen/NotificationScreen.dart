import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sms_apk/utils/app_colors.dart';
import 'package:sms_apk/widgets/custom_popup.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: NotificationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  List<dynamic> notifications = [];

  String _formatDate(String date) {
    try {
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  Future<void> fetchNotifications() async {
    final String code = _codeController.text.trim();
    if (code.isEmpty) {
      showPopup(context,'Please enter a code',AppColors.primary);
      return;
    }

    final String url =
        'https://s-m-s-keyw.onrender.com/notification/getNotification?code=$code';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          notifications = json.decode(response.body);
        });
      } else {
        showPopup(context,'Failed to load notifications',AppColors.primary);
      }
    } catch (e) {
      showPopup(context,'Error fetching notifications',AppColors.primary);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary, // Ensures app bar matches theme
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Colors.white), // Back arrow icon
          onPressed: () =>
              Navigator.pop(context), // Navigate back to the previous screen
        ),
      ),
      body: Container(
        color: Colors.white,
        child: NotificationBody(
          fetchNotifications: fetchNotifications,
          codeController: _codeController,
          notifications: notifications,
          formatDate: _formatDate,
        ),
      ),
    );
  }
}

class NotificationBody extends StatelessWidget {
  final Function fetchNotifications;
  final TextEditingController codeController;
  final List<dynamic> notifications;
  final String Function(String) formatDate;

  const NotificationBody({
    super.key,
    required this.fetchNotifications,
    required this.codeController,
    required this.notifications,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: codeController,
            cursorColor: AppColors.primary, // Cursor (caret) color
            decoration: InputDecoration(
              labelText: 'Enter Code',
              floatingLabelStyle: TextStyle(
                  color: AppColors.primary), // Label color when focused
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: AppColors.primary), // Default border color
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                    color: AppColors.primary, width: 2), // Focused border color
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.code),
              helperText:
                  'Note : Write 4 characters of your name and last 4 digits of your contact number',
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => fetchNotifications(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, // Button color
              foregroundColor: Colors.white, // Text color
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 20), // Button padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Rounded corners
              ),
            ),
            child: const Text(
              "Fetch Notifications",
              style: TextStyle(fontSize: 16),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Text('No notifications available',
                        style: TextStyle(fontSize: 16)))
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      var notification = notifications[index];
                      return Card(
                        color: Colors.white,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(notification['description'],
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text(
                            'Start: ${formatDate(notification['startDate'])}\nEnd: ${formatDate(notification['endDate'])}\nClasses: ${notification['className']}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          leading: Icon(Icons.notifications_active,
                              color: AppColors.primary),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
