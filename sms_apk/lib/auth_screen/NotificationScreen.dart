import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
  TextEditingController _codeController = TextEditingController();
  List<dynamic> notifications = [];

  Future<void> fetchNotifications() async {
    final String code = _codeController.text;
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a code')),
      );
      return;
    }
    
    final String url = 'http://localhost:8080/notification/getNotification?code=$code';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          notifications = json.decode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching notifications')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: NotificationBody(fetchNotifications: fetchNotifications, codeController: _codeController, notifications: notifications),
    );
  }
}

class NotificationBody extends StatelessWidget {
  final Function fetchNotifications;
  final TextEditingController codeController;
  final List<dynamic> notifications;

  NotificationBody({required this.fetchNotifications, required this.codeController, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: codeController,
            decoration: InputDecoration(
              labelText: 'Enter Code',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => fetchNotifications(),
            child: Text('Fetch Notifications'),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                var notification = notifications[index];
                return Card(
                  child: ListTile(
                    title: Text(notification['description']),
                    subtitle: Text(
                        'Start: ${notification['startDate']}, End: ${notification['endDate']}'),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
            child: Text('Get Notifications'),
          ),
        ],
      ),
    );
  }
}
