import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;
import 'package:shared_preferences/shared_preferences.dart';
import 'UploadSyllabus_screen.dart';
import 'syllabus_model.dart';

class SyllabusController {
  final String baseUrl = 'https://s-m-s-keyw.onrender.com';

  Future<List<Syllabus>> fetchSyllabus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken');

      if (authToken == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/doc/getAll'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((item) => Syllabus.fromJson(item)).toList();
      } else {
        throw Exception(
            'Failed to load syllabus - Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching syllabus: ${e.toString()}');
    }
  }

  Future<void> deleteSyllabus(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken');
    await http.post(
      Uri.parse('$baseUrl/doc/delete?id=$id'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
    );
  }

  // NEW: Add status update functionality
  Future<void> updatePublishStatus(List<Map<String, String>> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken');

      if (authToken == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/doc/syllabus/update'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update status - Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating status: ${e.toString()}');
    }
  }

  Future<void> downloadSyllabus(String id, String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken');

      if (authToken == null) {
        throw Exception('Authentication token not found');
      }

      if (kIsWeb) {
        final response = await http.get(
          Uri.parse('$baseUrl/doc/download/$id'),
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        );

        if (response.statusCode == 200) {
          final blob = html.Blob([response.bodyBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
        } else {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      } else {
        final status = await Permission.storage.request();
        if (status.isGranted) {
          final dir = await getExternalStorageDirectory();
          await FlutterDownloader.enqueue(
            url: '$baseUrl/doc/download/$id',
            savedDir: dir!.path,
            fileName: fileName,
            headers: {'Authorization': 'Bearer $authToken'},
            showNotification: true,
            openFileFromNotification: true,
          );
        }
      }
    } catch (e) {
      throw Exception('Download failed: ${e.toString()}');
    }
  }
}

class ViewSyllabusScreen extends StatefulWidget {
  @override
  _ViewSyllabusScreenState createState() => _ViewSyllabusScreenState();
}

class _ViewSyllabusScreenState extends State<ViewSyllabusScreen> {
  final SyllabusController _controller = SyllabusController();
  List<Syllabus> _syllabusList = [];
  bool _loading = false;

  // NEW: Status management variables
  Map<String, bool> _modifiedStatus = {};
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadSyllabus();
  }

  Future<void> _loadSyllabus() async {
    setState(() => _loading = true);
    try {
      _syllabusList = await _controller.fetchSyllabus();
      // Reset modified status when reloading
      _modifiedStatus.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading syllabus: ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this syllabus?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _loading = true);
      try {
        await _controller.deleteSyllabus(id);
        await _loadSyllabus();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Syllabus deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete syllabus')),
        );
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  // NEW: Handle status change
  void _handleStatusChange(String id, bool currentStatus) {
    setState(() {
      _modifiedStatus[id] = !currentStatus;
    });
  }

  // NEW: Get current status (modified or original)
  bool _getCurrentStatus(String id, bool defaultStatus) {
    return _modifiedStatus.containsKey(id)
        ? _modifiedStatus[id]!
        : defaultStatus;
  }

  // NEW: Update publish status
  Future<void> _updatePublishStatus() async {
    if (_modifiedStatus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No changes to update')),
      );
      return;
    }

    final payload = _modifiedStatus.entries
        .map((entry) => {
              'id': entry.key,
              'publish': entry.value.toString(),
            })
        .toList();

    setState(() => _isUpdating = true);
    try {
      await _controller.updatePublishStatus(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated successfully')),
      );
      await _loadSyllabus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: ${e.toString()}')),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.library_books, color: Colors.white),
            SizedBox(width: 8),
            Text('Syllabus Documents', style: TextStyle(color: Colors.white),overflow: TextOverflow.ellipsis, ),
          ],
        ),
        backgroundColor: Color(0xFF519186),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSyllabus,
            tooltip: 'Refresh',
          ),
         
        ],
      ),
      body: Column(
        children: [
          // NEW: Status update button
          if (_modifiedStatus.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Colors.blue[50],
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : _updatePublishStatus,
                icon: _isUpdating
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.publish),
                label: Text(_isUpdating
                    ? 'Publishing...'
                    : 'Publish Syllabus (${_modifiedStatus.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF519186),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

          // Main content
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF519186)),
                        SizedBox(height: 16),
                        Text('Loading syllabus...',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  )
                : _syllabusList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.library_books_outlined,
                                size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'No syllabus documents found',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap the + button to upload your first syllabus',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[500]),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _navigateToUpload(),
                              icon: Icon(Icons.add),
                              label: Text('Upload Syllabus'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF519186),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _syllabusList.length,
                        itemBuilder: (context, index) {
                          final syllabus = _syllabusList[index];
                          final currentStatus =
                              _getCurrentStatus(syllabus.id, syllabus.publish);

                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Container(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // NEW: Status checkbox
                                      Container(
                                        margin: EdgeInsets.only(right: 12),
                                        child: Checkbox(
                                          value: currentStatus,
                                          onChanged: (value) =>
                                              _handleStatusChange(
                                                  syllabus.id, currentStatus),
                                          activeColor: Color(0xFF519186),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),

                                      Container(
                                        padding: EdgeInsets.all(8),
                                       
                                        child: Icon(
                                          Icons.picture_as_pdf,
                                          color: Color(0xFF519186),
                                          size: 24,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              syllabus.title ??
                                                  'Untitled Document',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.school,
                                                    size: 14,
                                                    color: Colors.grey[600]),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Class: ${syllabus.cls == "undefined" ? "Not specified" : syllabus.cls}',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600]),
                                                ),
                                                SizedBox(width: 12),
                                                Icon(Icons.subject,
                                                    size: 14,
                                                    color: Colors.grey[600]),
                                                SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Subject: ${syllabus.subject}',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.grey[600]),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: currentStatus
                                              ? Colors.green[50]
                                              : Colors.orange[50],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: currentStatus
                                                ? Colors.green[200]!
                                                : Colors.orange[200]!,
                                          ),
                                        ),
                                        child: Text(
                                          currentStatus ? 'Published' : 'Draft',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: currentStatus
                                                ? Colors.green[700]
                                                : Colors.orange[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),

                                  // Action buttons
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Download Button
                                      IconButton(
                                        onPressed: () =>
                                            _controller.downloadSyllabus(
                                          syllabus.id,
                                          syllabus.name,
                                        ),
                                        icon: Icon(Icons.download,
                                            color: Color(
                                                0xFF519186)), // Added missing parenthesis
                                        tooltip: 'Download',
                                      ),

                                      // Edit Button
                                      IconButton(
                                        onPressed: () =>
                                            _navigateToEdit(syllabus),
                                        icon: Icon(Icons.edit,
                                            color: Colors.blue[600]),
                                        tooltip: 'Edit',
                                      ),

                                      // Delete Button
                                      IconButton(
                                        onPressed: () =>
                                            _confirmDelete(syllabus.id),
                                        icon: Icon(Icons.delete,
                                            color: Colors.red[600]),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToUpload(),
        backgroundColor: Color(0xFF519186),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Upload Syllabus',
      ),
    );
  }

  void _navigateToUpload() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicSyllabusScreen(
          isEditMode: false,
          onSuccess: _loadSyllabus,
        ),
      ),
    );
  }

  void _navigateToEdit(Syllabus syllabus) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicSyllabusScreen(
          isEditMode: true,
          existingSyllabus: syllabus,
          onSuccess: _loadSyllabus,
        ),
      ),
    );
  }
}
