import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';

class UploadSyllabusScreen extends StatefulWidget {
  @override
  _UploadSyllabusScreenState createState() => _UploadSyllabusScreenState();
}

class _UploadSyllabusScreenState extends State<UploadSyllabusScreen> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _textContentController = TextEditingController();
  
  // State variables
  bool _isLoading = false;
  bool _publish = false;
  String _selectedClass = '';
  String _selectedSubject = '';
  String _inputType = 'file';
  
  // FIXED: Use Uint8List for web compatibility
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  
  // Data lists
  List<dynamic> _classData = [];
  List<String> _subjects = [];

  final String _baseUrl = 'https://s-m-s-keyw.onrender.com';

  @override
  void initState() {
    super.initState();
    _fetchClassData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textContentController.dispose();
    super.dispose();
  }

  Future<void> _fetchClassData() async {
    try {
      setState(() => _isLoading = true);
      
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken');
      
      if (authToken == null) {
        _showToast('Not authenticated. Please login.');
        setState(() => _isLoading = false);
        return;
      }

      

      final response = await http.get(
        Uri.parse('$_baseUrl/class/data'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('classData')) {
          setState(() {
            _classData = responseData['classData'] as List<dynamic>;
            _isLoading = false;
          });
        } else if (responseData is List) {
          setState(() {
            _classData = responseData;
            _isLoading = false;
          });
        } else {
          _showToast('Invalid response format');
          setState(() => _isLoading = false);
        }
      } else if (response.statusCode == 401) {
        _showToast('Session expired. Please login again.');
        await prefs.remove('authToken');
        setState(() => _isLoading = false);
      } else {
        _showToast('Error: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
     
      _showToast('Failed to load class data: $e');
      setState(() => _isLoading = false);
    }
  }

  // FIXED: Web-compatible upload function
Future<void> _uploadSyllabus(Map<String, String> params, Uint8List fileBytes, String fileName) async {
  setState(() => _isLoading = true);
  try {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken')?.trim();
    
    if (authToken == null || authToken.isEmpty) {
      _showToast('Not authenticated. Please login.');
      setState(() => _isLoading = false);
      return;
    }

    // Ensure filename ends with .pdf
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      fileName = '$fileName.pdf';
    }

    final queryString = Uri(queryParameters: params).query;
    final url = Uri.parse('$_baseUrl/doc/upload?$queryString');

    var request = http.MultipartRequest('POST', url);
    
    request.headers['Authorization'] = 'Bearer $authToken'; 
    request.headers['Content-Type'] = 'multipart/form-data';
    
    // Add PDF content type to the file part
    var multipartFile = http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
      contentType: MediaType('application', 'pdf'), // Explicit content type
    );
    request.files.add(multipartFile);

  

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    
    
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      _showToast('Syllabus uploaded successfully');
      _clearForm();
      Navigator.pop(context);
    } else {
      _showToast('Upload failed: ${response.statusCode}\n$responseBody');
    }
  } catch (e) {
   
    _showToast('Upload error: ${e.toString()}');
  } finally {
    setState(() => _isLoading = false);
  }
}
  void _clearForm() {
    setState(() {
      _selectedFileBytes = null;
      _selectedFileName = null;
      _titleController.clear();
      _textContentController.clear();
      _selectedClass = '';
      _selectedSubject = '';
      _publish = false;
    });
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
    
  }

  // FIXED: Font-compatible PDF generation (no Helvetica)
  Future<Uint8List> _convertTextToPdf(String text, String title) async {
    try {
   
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // FIXED: Remove font specification to use default
              pw.Header(
                level: 0, 
                child: pw.Text(
                  title, 
                  style: pw.TextStyle(
                    fontSize: 20, 
                    fontWeight: pw.FontWeight.bold,
                    // No font specified - uses default
                  )
                )
              ),
              pw.SizedBox(height: 20),
              pw.Paragraph(
                text: text,
                style: pw.TextStyle(
                  fontSize: 12, 
                  lineSpacing: 1.5,
                  // No font specified - uses default
                ),
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      
      return bytes;
    } catch (e) {

      throw Exception('Failed to generate PDF: $e');
    }
  }

  // FIXED: Simplified file picker for web
  Future<void> _pickFile() async {
    try {
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
        allowMultiple: false,
        withData: true, // Important for web
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile platformFile = result.files.first;
        
        // Check file size (5MB limit)
        if (platformFile.size > 5 * 1024 * 1024) {
          _showToast('File size should not exceed 5MB');
          return;
        }
        
        // Use bytes for web compatibility
        if (platformFile.bytes != null) {
          setState(() {
            _selectedFileBytes = platformFile.bytes;
            _selectedFileName = platformFile.name;
          });
          _showToast('File selected: ${platformFile.name}');
          
        } else {
          _showToast('Could not read file data');
        }
      }
    } catch (e) {
     
      _showToast('Error selecting file: ${e.toString()}');
    }
  }

  void _onClassChanged(String? className) {
    setState(() {
      _selectedClass = className ?? '';
      _selectedSubject = '';
      
      if (className != null && className.isNotEmpty) {
        try {
          final selectedClassData = _classData.firstWhere(
            (c) => c['className'] == className,
            orElse: () => null,
          );
          
          if (selectedClassData != null && selectedClassData['subject'] != null) {
            _subjects = List<String>.from(selectedClassData['subject']);
          } else {
            _subjects = [];
          }
        } catch (e) {
          
          _subjects = [];
        }
      } else {
        _subjects = [];
      }
    });
  }

  // FIXED: Proper variable initialization
  Future<void> _handleSubmit() async {
 
    if (!_formKey.currentState!.validate()) {
      _showToast('Please fill all required fields');
      return;
    }

    if (_selectedClass.isEmpty) {
      _showToast('Please select a class');
      return;
    }
    
    if (_selectedSubject.isEmpty) {
      _showToast('Please select a subject');
      return;
    }

    if (_inputType == 'file' && _selectedFileBytes == null) {
      _showToast('Please select a file');
      return;
    }
    
    if (_inputType == 'text' && _textContentController.text.trim().isEmpty) {
      _showToast('Please enter text content');
      return;
    }

    try {
      // FIXED: Initialize variables properly
      Uint8List? fileBytes;
      String fileName = 'syllabus.pdf'; // Default value

      if (_inputType == 'text' && _textContentController.text.isNotEmpty) {
   ;
        _showToast('Converting text to PDF...');
        
        fileBytes = await _convertTextToPdf(_textContentController.text, _titleController.text);
        fileName = '${_titleController.text.replaceAll(RegExp(r'[^\w\s-]'), '_')}.pdf';
        
      
      } else if (_selectedFileBytes != null && _selectedFileName != null) {
    
        fileBytes = _selectedFileBytes;
        fileName = _selectedFileName!; 
      }

      if (fileBytes == null) {
        _showToast('No valid file to upload');
        return;
      }

      final params = {
        'tittle': _titleController.text,
        'subject': _selectedSubject,
        'publish': _publish.toString(),
        'cls': _selectedClass,
      };

   
      
      await _uploadSyllabus(params, fileBytes, fileName);
    } catch (e) {
    
      _showToast('Upload failed: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.book_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text('Upload Syllabus', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Color(0xFF519186),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF519186)),
                  SizedBox(height: 16),
                  Text('Processing...', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status indicator
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Web-optimized file upload • Unicode-safe PDF generation',
                                style: TextStyle(fontSize: 12, color: Colors.green[700]),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Title Field
                      _buildSectionTitle('Title', Icons.book),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'Enter syllabus title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF519186)),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        validator: (value) => value?.isEmpty == true ? 'Title is required' : null,
                      ),
                      SizedBox(height: 20),

                      // Class and Subject Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Class', Icons.school),
                                DropdownButtonFormField<String>(
                                  value: _selectedClass.isEmpty ? null : _selectedClass,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Color(0xFF519186)),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                  hint: Text('Select Class'),
                                  isExpanded: true,
                                  items: _classData.map<DropdownMenuItem<String>>((cls) {
                                    return DropdownMenuItem<String>(
                                      value: cls['className']?.toString() ?? '',
                                      child: Text(cls['className']?.toString() ?? 'Unknown'),
                                    );
                                  }).toList(),
                                  onChanged: _onClassChanged,
                                  validator: (value) => value?.isEmpty == true ? 'Class is required' : null,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Subject', Icons.subject),
                                DropdownButtonFormField<String>(
                                  value: _selectedSubject.isEmpty ? null : _selectedSubject,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Color(0xFF519186)),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                  hint: Text(_selectedClass.isEmpty ? 'Select Class First' : 'Select Subject'),
                                  isExpanded: true,
                                  items: _subjects.map<DropdownMenuItem<String>>((subject) {
                                    return DropdownMenuItem<String>(
                                      value: subject,
                                      child: Text(subject),
                                    );
                                  }).toList(),
                                  onChanged: _selectedClass.isEmpty ? null : (value) => setState(() => _selectedSubject = value ?? ''),
                                  validator: (value) => value?.isEmpty == true ? 'Subject is required' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Publish Checkbox
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _publish,
                              onChanged: (value) => setState(() => _publish = value ?? false),
                              activeColor: Color(0xFF519186),
                            ),
                            Icon(Icons.check_circle_outline, size: 20, color: Colors.grey[600]),
                            SizedBox(width: 8),
                            Text(
                              'Publish immediately',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // File/Text Toggle
                      Row(
                        children: [
                          _buildToggleButton('Upload File', Icons.upload_file, 'file'),
                          SizedBox(width: 12),
                          _buildToggleButton('Enter Text', Icons.text_fields, 'text'),
                        ],
                      ),
                      SizedBox(height: 20),

                      // File Upload or Text Content
                      if (_inputType == 'file') ...[
                        _buildFileUploadSection(),
                      ] else ...[
                        _buildTextContentSection(),
                      ],
                      SizedBox(height: 30),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF519186),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                          ),
                          child: Text(
                            _isLoading ? 'Uploading...' : 'Upload Syllabus',
                            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Color(0xFF519186)),
          SizedBox(width: 8),
          Text(
            '$title*',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, IconData icon, String type) {
    final isSelected = _inputType == type;
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () => setState(() => _inputType = type),
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Color(0xFF519186).withOpacity(0.1) : Colors.grey[100],
          foregroundColor: isSelected ? Color(0xFF519186) : Colors.grey[700],
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedFileBytes != null ? Color(0xFF519186) : Colors.grey[400]!, 
              width: 2
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _selectedFileBytes != null ? Color(0xFF519186).withOpacity(0.05) : Colors.grey[50],
            ),
            child: Column(
              children: [
                Icon(
                  _selectedFileBytes != null ? Icons.check_circle : Icons.cloud_upload_outlined, 
                  size: 48, 
                  color: _selectedFileBytes != null ? Color(0xFF519186) : Colors.grey[400]
                ),
                SizedBox(height: 16),
                Text(
                  _selectedFileBytes != null ? 'File Ready for Upload' : 'Click to upload file',
                  style: TextStyle(
                    fontSize: 14, 
                    color: _selectedFileBytes != null ? Color(0xFF519186) : Colors.grey[600], 
                    fontWeight: FontWeight.w500
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'PDF, DOC, DOCX, or TXT (MAX. 5MB)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF519186),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _selectedFileBytes != null ? 'Change File' : 'Select File', 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)
                  ),
                ),
                if (_selectedFileName != null) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF519186).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insert_drive_file, color: Color(0xFF519186), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected: $_selectedFileName',
                                style: TextStyle(fontSize: 14, color: Color(0xFF519186), fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Size: ${((_selectedFileBytes?.length ?? 0) / 1024).toStringAsFixed(1)} KB',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() {
                            _selectedFileBytes = null;
                            _selectedFileName = null;
                          }),
                          icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Syllabus Content', Icons.text_fields),
        TextFormField(
          controller: _textContentController,
          maxLines: 8,
          decoration: InputDecoration(
            hintText: 'Enter syllabus content here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF519186)),
            ),
            contentPadding: EdgeInsets.all(16),
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (_inputType == 'text' && (value?.trim().isEmpty == true)) {
              return 'Content is required';
            }
            return null;
          },
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '✓ Text will be converted to PDF with Unicode-safe fonts',
            style: TextStyle(fontSize: 12, color: Colors.blue[700]),
          ),
        ),
      ],
    );
  }
}