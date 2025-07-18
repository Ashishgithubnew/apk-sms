import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sms_apk/school/utils/app_colors.dart';
import 'package:sms_apk/school/widgets/custom_popup.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  Map<String, dynamic>? studentData;
  List<String> selectedMonths = [];
  bool selectedOtherFee = false;
  double paymentAmount = 0.0;

  bool isLoading = false;
  bool downloading = false;
  late TabController _tabController;

  final List<String> monthOrder = [
    'July', 'August', 'September', 'October',
    'November', 'December', 'January',
    'February', 'March', 'April'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  Future<void> fetchAllData() async {
    final String code = _codeController.text.trim();
    if (code.isEmpty) {
      showPopup(context, 'Please enter a code', AppColors.primary);
      return;
    }

    setState(() {
      isLoading = true;
      notifications.clear();
      notes.clear();
      studentData = null;
      selectedMonths.clear();
      selectedOtherFee = false;
      paymentAmount = 0.0;
    });

    try {
      final List<Future> futures = [
        http.get(Uri.parse('https://s-m-s-keyw.onrender.com/notification/getNotification?code=$code')),
        http.post(Uri.parse('https://s-m-s-keyw.onrender.com/doc/getNotes?code=$code')),
        http.get(Uri.parse('https://s-m-s-keyw.onrender.com/student/getByCode?code=$code')),
      ];

      final responses = await Future.wait(futures);

      if (responses[0].statusCode == 200) {
        setState(() {
          notifications = json.decode(responses[0].body);
        });
      }

      if (responses[1].statusCode == 200) {
        setState(() {
          notes = json.decode(responses[1].body);
        });
      }

      if (responses[2].statusCode == 200) {
        setState(() {
          studentData = json.decode(responses[2].body);
        });
        _calculatePaymentAmount();
      }

      if (responses[0].statusCode != 200 &&
          responses[1].statusCode != 200 &&
          responses[2].statusCode != 200) {
        showPopup(context, 'No data found for this code', AppColors.primary);
      }
    } catch (e) {
      showPopup(context, 'Error fetching data: $e', AppColors.primary);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _calculatePaymentAmount() {
    if (studentData == null) return;

    double totalFees = (studentData!['totalFees'] ?? 0).toDouble();
    double remainingFees = (studentData!['remainingFees'] ?? 0).toDouble();
    double perMonthFee = totalFees / 10;

    double paidAmount = totalFees - remainingFees;
    int paidMonths = (paidAmount / perMonthFee).floor();

    double selectedAmount = 0.0;
    for (String month in selectedMonths) {
      int monthIndex = monthOrder.indexOf(month);
      if (monthIndex >= paidMonths) {
        selectedAmount += perMonthFee;
      }
    }

    double otherFees = remainingFees - ((10 - paidMonths) * perMonthFee);
    if (otherFees < 0) otherFees = 0;

    setState(() {
      paymentAmount = selectedAmount + (selectedOtherFee ? otherFees : 0);
    });
  }

  void _toggleMonthSelection(String month) {
    setState(() {
      if (selectedMonths.contains(month)) {
        selectedMonths.remove(month);
      } else {
        selectedMonths.add(month);
      }
    });
    _calculatePaymentAmount();
  }

  void _toggleOtherFee() {
    setState(() {
      selectedOtherFee = !selectedOtherFee;
    });
    _calculatePaymentAmount();
  }

  // Simplified permission handling method (same as Transfer Certificate screen)
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Try multiple permission approaches for different Android versions
      try {
        // First try the newer permissions for Android 11+
        var status = await Permission.manageExternalStorage.status;
        if (status.isGranted) {
          return true;
        }
        // If not granted, try to request it
        status = await Permission.manageExternalStorage.request();
        if (status.isGranted) {
          return true;
        }
        // If manage external storage is not available, try storage permission
        var storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) {
          return true;
        }
        storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) {
          return true;
        }
        // If both fail, we'll use app-specific directory which doesn't need permission
        return true;
      } catch (e) {
        print('Permission error: $e');
        // If permission handling fails, we'll use app-specific directory
        return true;
      }
    }
    return true; // For iOS or other platforms
  }

  // Updated download method with the same logic as Transfer Certificate screen
  Future<void> downloadPdf(String noteId, String fileName) async {
    setState(() => downloading = true);

    try {
      final url = 'https://s-m-s-keyw.onrender.com/doc/download/$noteId';

      if (kIsWeb) {
        // Web version
        final dio = Dio();
        final response = await dio.get(
          url,
          options: Options(
            responseType: ResponseType.bytes,
          ),
        );

        final fullFileName = '$fileName.pdf';
        final blob = html.Blob([response.data], 'application/pdf');
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: blobUrl)
          ..setAttribute('download', fullFileName)
          ..click();
        html.Url.revokeObjectUrl(blobUrl);

        showPopup(context, 'Study note download started!', AppColors.primary);
      } else {
        // Mobile version with simplified permission handling
        await _requestStoragePermission();

        final dio = Dio();
        final fullFileName = '$fileName.pdf';

        // Try different storage locations in order of preference
        String? filePath;

        try {
          // First try: Downloads folder (works on most devices)
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            filePath = '${downloadsDir.path}/$fullFileName';
          }
        } catch (e) {
          print('Downloads directory not accessible: $e');
        }

        if (filePath == null) {
          try {
            // Second try: External storage directory
            final dir = await getExternalStorageDirectory();
            if (dir != null) {
              final downloadDir = '${dir.path}/Downloads';
              final downloadFolder = Directory(downloadDir);
              if (!await downloadFolder.exists()) {
                await downloadFolder.create(recursive: true);
              }
              filePath = '$downloadDir/$fullFileName';
            }
          } catch (e) {
            print('External storage directory not accessible: $e');
          }
        }

        if (filePath == null) {
          // Final fallback: App documents directory (always works)
          final dir = await getApplicationDocumentsDirectory();
          filePath = '${dir.path}/$fullFileName';
        }

        await dio.download(
          url,
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              print('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
            }
          },
        );

        showPopup(context, 'Study note downloaded successfully to: $filePath', AppColors.primary);
      }
    } catch (e) {
      showPopup(context, 'Failed to download study note: $e', AppColors.primary);
    } finally {
      setState(() => downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Portal',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: NotificationBody(
          fetchAllData: fetchAllData,
          codeController: _codeController,
          notifications: notifications,
          notes: notes,
          studentData: studentData,
          selectedMonths: selectedMonths,
          selectedOtherFee: selectedOtherFee,
          paymentAmount: paymentAmount,
          monthOrder: monthOrder,
          formatDate: _formatDate,
          downloadPdf: downloadPdf,
          toggleMonthSelection: _toggleMonthSelection,
          toggleOtherFee: _toggleOtherFee,
          isLoading: isLoading,
          downloading: downloading,
          tabController: _tabController,
        ),
      ),
    );
  }
}

class NotificationBody extends StatelessWidget {
  final Function fetchAllData;
  final TextEditingController codeController;
  final List<dynamic> notifications;
  final List<dynamic> notes;
  final Map<String, dynamic>? studentData;
  final List<String> selectedMonths;
  final bool selectedOtherFee;
  final double paymentAmount;
  final List<String> monthOrder;
  final String Function(String) formatDate;
  final Function(String, String) downloadPdf;
  final Function(String) toggleMonthSelection;
  final Function() toggleOtherFee;
  final bool isLoading;
  final bool downloading;
  final TabController tabController;

  const NotificationBody({
    super.key,
    required this.fetchAllData,
    required this.codeController,
    required this.notifications,
    required this.notes,
    required this.studentData,
    required this.selectedMonths,
    required this.selectedOtherFee,
    required this.paymentAmount,
    required this.monthOrder,
    required this.formatDate,
    required this.downloadPdf,
    required this.toggleMonthSelection,
    required this.toggleOtherFee,
    required this.isLoading,
    required this.downloading,
    required this.tabController,
  });

  Widget _buildNotificationsList() {
    if (notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No notifications available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.event,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['description'] ?? 'No description',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start: ${formatDate(notification['startDate'] ?? '')}\nEnd: ${formatDate(notification['endDate'] ?? '')}\nClasses: ${notification['className'] ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_books_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No study notes available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        child: Icon(
                          Icons.picture_as_pdf,
                          color: Colors.green[700],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note['tittle'] ?? 'No Title',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Class: ${note['cls'] ?? 'N/A'} | Subject: ${note['subject']?.toString().toUpperCase() ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'File: ${note['name'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: downloading ? null : () => downloadPdf(note['id'], note['name']),
                      icon: downloading
                          ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.download, size: 16),
                      label: Text(downloading ? 'Downloading...' : 'Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeesManagement() {
    if (studentData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No fees data available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your code above to view fees information',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Information Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Student ID', studentData!['id']?.toString() ?? 'N/A'),
                  _buildInfoRow('Name', studentData!['name']?.toString() ?? 'N/A'),
                  _buildInfoRow('Class', studentData!['cls']?.toString() ?? 'N/A'),
                  _buildInfoRow('Email', studentData!['email']?.toString() ?? 'N/A'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Total Fees',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹${(studentData!['totalFees'] ?? 0).toString()}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Remaining Fees',
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹${(studentData!['remainingFees'] ?? 0).toString()}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Fee Payment Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fee Payment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Monthly Fees Grid
                  const Text(
                    'Monthly Fees',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMonthlyFeesGrid(),

                  const SizedBox(height: 20),

                  // Other Fees
                  _buildOtherFeesCard(),

                  const SizedBox(height: 20),

                  // Payment Summary
                  if (selectedMonths.isNotEmpty || selectedOtherFee)
                    _buildPaymentSummary(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyFeesGrid() {
    if (studentData == null) return const SizedBox.shrink();

    double totalFees = (studentData!['totalFees'] ?? 0).toDouble();
    double remainingFees = (studentData!['remainingFees'] ?? 0).toDouble();
    double perMonthFee = totalFees / 10;

    double paidAmount = totalFees - remainingFees;
    int paidMonths = (paidAmount / perMonthFee).floor();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate cross axis count based on available width
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: monthOrder.length,
          itemBuilder: (context, index) {
            String month = monthOrder[index];
            bool isPaid = index < paidMonths;
            bool isSelected = selectedMonths.contains(month);

            return GestureDetector(
              onTap: isPaid ? null : () => toggleMonthSelection(month),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.green[50]
                      : isSelected
                      ? Colors.blue[50]
                      : Colors.grey[50],
                  border: Border.all(
                    color: isPaid
                        ? Colors.green[200]!
                        : isSelected
                        ? Colors.blue[300]!
                        : Colors.grey[200]!,
                    width: isPaid || isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      month,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${perMonthFee.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isPaid ? Colors.green[700] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaid ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPaid ? 'Paid' : 'Pending',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isPaid ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOtherFeesCard() {
    if (studentData == null) return const SizedBox.shrink();

    double totalFees = (studentData!['totalFees'] ?? 0).toDouble();
    double remainingFees = (studentData!['remainingFees'] ?? 0).toDouble();
    double perMonthFee = totalFees / 10;

    double paidAmount = totalFees - remainingFees;
    int paidMonths = (paidAmount / perMonthFee).floor();
    double otherFees = remainingFees - ((10 - paidMonths) * perMonthFee);

    if (otherFees <= 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => toggleOtherFee(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selectedOtherFee ? Colors.blue[50] : Colors.grey[50],
          border: Border.all(
            color: selectedOtherFee ? Colors.blue[300]! : Colors.grey[200]!,
            width: selectedOtherFee ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Other Fees',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Additional charges',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${otherFees.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.yellow[800],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              if (selectedMonths.isNotEmpty) ...[
                const Text(
                  'Selected Months:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedMonths.join(', '),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
              ],
              if (selectedOtherFee) ...[
                const Text(
                  'Other Fees: Included',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
              ],
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${paymentAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: paymentAmount > 0 ? () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Payment'),
                        content: Text('Payment integration will be implemented here.\nAmount: ₹${paymentAmount.toStringAsFixed(0)}'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Pay Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Input Section with proper padding
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: codeController,
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    labelText: 'Enter Code',
                    floatingLabelStyle: TextStyle(color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.code),
                    helperText: 'Note: Write 4 characters of your name and last 4 digits of your contact number',
                    helperMaxLines: 2,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => fetchAllData(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      "Fetch All Data",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabs Section with proper constraints
          if (notifications.isNotEmpty || notes.isNotEmpty || studentData != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primary,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: [
                  Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_active, size: 16),
                          const SizedBox(width: 4),
                          const Flexible(
                            child: Text(
                              'Notifications',
                              style: TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (notifications.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: tabController.index == 0 ? Colors.white : AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${notifications.length}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: tabController.index == 0 ? AppColors.primary : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.library_books, size: 16),
                          const SizedBox(width: 4),
                          const Flexible(
                            child: Text(
                              'Diary',
                              style: TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (notes.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: tabController.index == 1 ? Colors.white : AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${notes.length}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: tabController.index == 1 ? AppColors.primary : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_wallet, size: 16),
                          const SizedBox(width: 4),
                          const Flexible(
                            child: Text(
                              'Fees',
                              style: TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (studentData != null) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: tabController.index == 2 ? Colors.white : Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.check,
                                size: 12,
                                color: tabController.index == 2 ? Colors.green : Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Content with proper constraints
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  _buildNotificationsList(),
                  _buildNotesList(),
                  _buildFeesManagement(),
                ],
              ),
            ),
          ] else ...[
            // No Data State with proper padding
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No data available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your code to fetch all data',
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
            ),
          ],
        ],
      ),
    );
  }
}
