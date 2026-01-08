import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
class HotelRegistrationForm extends StatefulWidget {
  @override
  _HotelRegistrationFormState createState() => _HotelRegistrationFormState();
}

class _HotelRegistrationFormState extends State<HotelRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  static const platform = MethodChannel('com.abhotel/fingerprint');

  String? token;
  bool _isSubmitting = false;
  bool _isScanning = false;

  // Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _contactController = TextEditingController();
  final _adharNoController = TextEditingController();
  final _nationalityController = TextEditingController();

  // Biometric / Images
  String _fingerprintBase64 = '';
  String _fingerprintData = 'Not scanned';
  XFile? _faceImage;
  XFile? _adharFront;
  XFile? _adharBack;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _nationalityController.text = "Indian"; // default like web
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
    });
  }

  Map<String, String> _getHeaders() {
    return {
      if (!kIsWeb) 'Content-Type': 'multipart/form-data',
      if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
    };


  }

  void _showToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _scanFingerprint() async {
    if (kIsWeb) return;
    setState(() => _isScanning = true);
    try {
      final result = await platform.invokeMethod('scanFingerprint');
      setState(() {
        _fingerprintBase64 = result;
        _fingerprintData = "Scanned at ${DateTime.now()}";
      });
      _showToast("Fingerprint scanned successfully!");
    } catch (e) {
      setState(() => _fingerprintData = "Scan failed");
      _showToast("Fingerprint scan failed");
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _pickImage(bool isFace, bool isFront) async {
    final source = kIsWeb ? ImageSource.gallery : await _showImageSourceDialog();
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      if (isFace) _faceImage = picked;
      else if (isFront) _adharFront = picked;
      else _adharBack = picked;
    });
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<http.MultipartFile> _fileToMultipart(XFile file, String fieldName) async {
    final bytes = await file.readAsBytes();
    return http.MultipartFile.fromBytes(fieldName, bytes, filename: file.name);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showToast("Please fill all required fields!");
      return;
    }
    if (_faceImage == null) {
      _showToast("Please capture face photo!");
      return;
    }
    if (_adharFront == null || _adharBack == null) {
      _showToast("Please capture Aadhar images!");
      return;
    }
    if (!kIsWeb && _fingerprintBase64.isEmpty) {
      _showToast("Please scan fingerprint!");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse('https://s-m-s-keyw.onrender.com/hotel/customer/register');
      final request = http.MultipartRequest('POST', uri);
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields['name'] = _nameController.text.trim();
      request.fields['address'] = _addressController.text.trim();
      request.fields['city'] = _cityController.text.trim();
      request.fields['state'] = _stateController.text.trim();
      request.fields['contact'] = _contactController.text.trim();
      request.fields['adharNo'] = _adharNoController.text.trim();
      request.fields['nationality'] = _nationalityController.text.trim();

      // Add files
      request.files.add(await _fileToMultipart(_faceImage!, 'face_image'));
      request.files.add(await _fileToMultipart(_adharFront!, 'adharImgF'));
      request.files.add(await _fileToMultipart(_adharBack!, 'adharImgB'));

      // Add fingerprint (as bytes)
      if (_fingerprintBase64.isNotEmpty) {
        final bytes = base64Decode(_fingerprintBase64);
        request.files.add(http.MultipartFile.fromBytes('fingerprint_data', bytes, filename: 'fingerprint.iso'));
      } else {
        request.files.add(http.MultipartFile.fromBytes('fingerprint_data', [], filename: 'fingerprint.iso'));
      }

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        _showToast("Customer registered successfully!");
        _formKey.currentState!.reset();
        setState(() {
          _faceImage = null;
          _adharFront = null;
          _adharBack = null;
          _fingerprintBase64 = '';
          _fingerprintData = 'Not scanned';
        });
        Navigator.pop(context, true);
      } else {
        _showToast("Error: $respStr");
      }
    } catch (e) {
      _showToast("Submission failed: $e");
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
Widget _imagePreview(XFile? file, {double width = 100, double height = 100}) {
  if (file == null) return SizedBox();
  
  return Container(
    width: width,
    height: height,
    margin: EdgeInsets.only(top: 8),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(8),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: kIsWeb
          ? Image.network(file.path, fit: BoxFit.cover)
          : Image.file(
              File(file.path), // Only works on mobile
              fit: BoxFit.cover,
            ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Customer Registration'), backgroundColor: Colors.teal,foregroundColor: Colors.white,),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInput(_nameController, 'Full Name', true),
              SizedBox(height: 12),
              _buildInput(_addressController, 'Address', true, maxLines: 3),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildInput(_cityController, 'City', true)),
                  SizedBox(width: 12),
                  Expanded(child: _buildInput(_stateController, 'State', true)),
                ],
              ),
              SizedBox(height: 12),
              _buildInput(_contactController, 'Contact Number', true, keyboardType: TextInputType.phone),
              SizedBox(height: 12),
              _buildInput(_adharNoController, 'Aadhar Number', false),
              SizedBox(height: 12),
              _buildInput(_nationalityController, 'Nationality', false),
              SizedBox(height: 12),

              _buildImageButton('Capture Aadhar Front', () => _pickImage(false, true)),
              _imagePreview(_adharFront),
              SizedBox(height: 12),

              _buildImageButton('Capture Aadhar Back', () => _pickImage(false, false)),
              _imagePreview(_adharBack),
              SizedBox(height: 12),

              if (!kIsWeb)
                ElevatedButton(
                  onPressed: _isScanning ? null : _scanFingerprint,
                  child: Text(_isScanning ? 'Scanning...' : 'Scan Fingerprint'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal,foregroundColor: Colors.white),
                ),
              if (!kIsWeb) Text(_fingerprintData),
              SizedBox(height: 12),

              _buildImageButton('Capture Face Photo', () => _pickImage(true, false)),
              _imagePreview(_faceImage),
              SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Register'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal,foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, bool required,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required ? (v) => v!.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _buildImageButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal,foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 12)),
    );
  }
}
