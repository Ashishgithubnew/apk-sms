import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sms_apk/utils/app_colors.dart';
import 'package:sms_apk/widgets/custom_popup.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html; // Web के लिए
import 'package:flutter_downloader/flutter_downloader.dart'; // Android के लिए
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart'; // For Android

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) await FlutterDownloader.initialize();
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

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  List<dynamic> notifications = [];
  List<dynamic> notes = [];
  bool isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
      showPopup(context, 'Please enter a code', AppColors.primary);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Fetch notifications
      final String notificationUrl =
          'https://s-m-s-keyw.onrender.com/notification/getNotification?code=$code';
      final notificationResponse = await http.get(Uri.parse(notificationUrl));

      // Fetch notes
      final String notesUrl = 'https://s-m-s-keyw.onrender.com/doc/getNotes?code=$code';
      final notesResponse = await http.post(Uri.parse(notesUrl));

      if (notificationResponse.statusCode == 200) {
        setState(() {
          notifications = json.decode(notificationResponse.body);
        });
      }

      if (notesResponse.statusCode == 200) {
        setState(() {
          notes = json.decode(notesResponse.body);
        });
      }

      if (notificationResponse.statusCode != 200 && notesResponse.statusCode != 200) {
        showPopup(context, 'Failed to load data', AppColors.primary);
      }
    } catch (e) {
      showPopup(context, 'Error fetching data: $e', AppColors.primary);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
 
  Future<void> downloadPdf(String noteId, String fileName) async {
    try {
      final url = 'https://s-m-s-keyw.onrender.com/doc/download/$noteId';
      
      if (kIsWeb) {
        // Web Version - Direct download
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', '$fileName.pdf')
          ..click();
        showPopup(context, 'Download started!', AppColors.primary);
      } else {
        // Android Version - Download with notifications
        final status = await Permission.storage.request();
        if (status.isGranted) {
          final dir = await getExternalStorageDirectory();
          await FlutterDownloader.enqueue(
            url: url,
            savedDir: dir!.path,
            fileName: '$fileName.pdf',
            showNotification: true,
            openFileFromNotification: true,
          );
          showPopup(context, 'Download started in background', AppColors.primary);
        } else {
          showPopup(context, 'Storage permission denied', AppColors.primary);
        }
      }
    } catch (e) {
      showPopup(context, 'Download failed: ${e.toString()}', AppColors.primary);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications & Notes',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: NotificationBody(
          fetchNotifications: fetchNotifications,
          codeController: _codeController,
          notifications: notifications,
          notes: notes,
          formatDate: _formatDate,
          downloadPdf: downloadPdf,
          isLoading: isLoading,
          tabController: _tabController,
        ),
      ),
    );
  }
}

class NotificationBody extends StatelessWidget {
  final Function fetchNotifications;
  final TextEditingController codeController;
  final List<dynamic> notifications;
  final List<dynamic> notes;
  final String Function(String) formatDate;
  final Function(String, String) downloadPdf;
  final bool isLoading;
  final TabController tabController;

  const NotificationBody({
    super.key,
    required this.fetchNotifications,
    required this.codeController,
    required this.notifications,
    required this.notes,
    required this.formatDate,
    required this.downloadPdf,
    required this.isLoading,
    required this.tabController,
  });

  Widget _buildNotificationsList() {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No notifications available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Card(
          color: Colors.white,
          margin: EdgeInsets.symmetric(vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            title: Text(
              notification['description'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'Start: ${formatDate(notification['startDate'])}\nEnd: ${formatDate(notification['endDate'])}\nClasses: ${notification['className']}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(
                Icons.event,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesList() {
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No study notes available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          color: Colors.white,
          margin: EdgeInsets.symmetric(vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            title: Text(
              note['tittle'] ?? 'No Title',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  'Class: ${note['cls']} | Subject: ${note['subject']?.toUpperCase()}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'File: ${note['name']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.green.withOpacity(0.1),
              child: Icon(
                Icons.picture_as_pdf,
                color: Colors.green[700],
              ),
            ),
            trailing: ElevatedButton.icon(
              onPressed: () => downloadPdf(note['id'], note['name']),
              icon: Icon(Icons.download, size: 16),
              label: Text('Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Input Section
          TextField(
            controller: codeController,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              labelText: 'Enter Code',
              floatingLabelStyle: TextStyle(color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.code),
              helperText:
                  'Note : Write 4 characters of your name and last 4 digits of your contact number',
            ),
          ),
          SizedBox(height: 10),
          
          // Fetch Button
          ElevatedButton(
            onPressed: isLoading ? null : () => fetchNotifications(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Fetch Data",
                    style: TextStyle(fontSize: 16),
                  ),
          ),
          SizedBox(height: 20),
          
          // Tabs Section
          if (notifications.isNotEmpty || notes.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_active, size: 20),
                        SizedBox(width: 8),
                        Text('Notifications'),
                        if (notifications.isNotEmpty) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: notifications.isNotEmpty 
                                  ? (tabController.index == 0 ? Colors.white : AppColors.primary)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${notifications.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: tabController.index == 0 ? AppColors.primary : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_books, size: 20),
                        SizedBox(width: 8),
                        Text('Study Notes'),
                        if (notes.isNotEmpty) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: notes.isNotEmpty 
                                  ? (tabController.index == 1 ? Colors.white : AppColors.primary)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${notes.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: tabController.index == 1 ? AppColors.primary : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  _buildNotificationsList(),
                  _buildNotesList(),
                ],
              ),
            ),
          ] else ...[
            // No Data State
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No data available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Enter your code and fetch data to see notifications and study notes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
