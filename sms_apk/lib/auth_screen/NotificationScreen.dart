import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
      _showSnackbar('Please enter a code');
      return;
    }
    
    final String url = 'https://s-m-s-keyw.onrender.com/notification/getNotification?code=$code';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          notifications = json.decode(response.body);
        });
      } else {
        _showSnackbar('Failed to load notifications');
      }
    } catch (e) {
      _showSnackbar('Error fetching notifications');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
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

  NotificationBody({
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
            decoration: InputDecoration(
              labelText: 'Enter Code',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.code),
              helperText: 'Note : Write 4 characters of your name and last 4 digits of your contact number',
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => fetchNotifications(),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Fetch Notifications', style: TextStyle(fontSize: 16)),
          ),
          SizedBox(height: 20),
          Expanded(
            child: notifications.isEmpty
                ? Center(child: Text('No notifications available', style: TextStyle(fontSize: 16)))
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      var notification = notifications[index];
                      return Card(
                        color: Colors.white,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(notification['description'],
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text(
                            'Start: ${formatDate(notification['startDate'])}\nEnd: ${formatDate(notification['endDate'])}\nClasses: ${notification['className']}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          leading: Icon(Icons.notifications_active, color: Colors.blue),
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
