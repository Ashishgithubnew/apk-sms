import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class HotelRegistrationForm extends StatefulWidget {
  @override
  _HotelRegistrationFormState createState() => _HotelRegistrationFormState();
}

class _HotelRegistrationFormState extends State<HotelRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  static const platform = MethodChannel('com.abhotel/fingerprint');
   6 
  String? token;
  bool _isTokenLoading = true;

  // Color Palette
  final Color primaryColor = Color(0xFF126666);
  final Color secondaryColor = Color(0xFFE74C3C);
  final Color accentColor = Color.fromARGB(255, 30, 120, 120);
  final Color backgroundColor = Color(0xFFECF0F1);

  // Form controllers
  TextEditingController _nameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _cityController = TextEditingController();
  TextEditingController _stateController = TextEditingController();
  TextEditingController _contactController = TextEditingController();
  TextEditingController _adharNoController = TextEditingController();
  TextEditingController _nationalityController = TextEditingController();

  // Biometric data
  String _fingerprintData = "Not scanned";
  String _fingerprintBase64 = "";
  XFile? _faceImage;
  String _faceImageBase64 = "";
  XFile? _adharImgF;
  String _adharImgFBase64 = "";
  XFile? _adharImgB;
  String _adharImgBBase64 = "";

  bool _isScanning = false;
  bool _isSubmitting = false;
  bool _showForm = false;
  bool _isExistingCustomer = false;
  Map<String, dynamic>? _existingCustomerData;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  // Load token from SharedPreferences
  Future<void> _loadToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        token = prefs.getString('authToken');
        _isTokenLoading = false;
      });
      
      if (token == null || token!.isEmpty) {
        _showErrorSnackBar('Authentication token not found. Please login again.');
        // Optionally navigate back to login screen
        // Nav    igator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      setState(() {
        _isTokenLoading = false;
      });
      _showErrorSnackBar('Error loading authentication token');
    }
  }

  // Get headers with authentication
  Map<String, String> _getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Handle authentication errors
  void _handleAuthError(int statusCode) {
    if (statusCode == 401) {
      _showErrorSnackBar('Session expired. Please login again.');
      // Clear token and navigate to login
      _clearTokenAndNavigateToLogin();
    } else if (statusCode == 403) {
      _showErrorSnackBar('Access denied. Insufficient permissions.');
    }
  }

  Future<void> _clearTokenAndNavigateToLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    setState(() {
      token = null;
    });
    // Navigate to login screen
    // Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _scanFingerprint() async {
    if (kIsWeb) {
      _showErrorSnackBar('Fingerprint scanning is not supported on web');
      return;
    }
    
    if (token == null || token!.isEmpty) {
      _showErrorSnackBar('Authentication required. Please login again.');
      return;
    }
    
    setState(() => _isScanning = true);
    try {
      final String result = await platform.invokeMethod('scanFingerprint');
      setState(() {
        _fingerprintData = "Scanned at ${DateTime.now().toString()}";
        _fingerprintBase64 = result;
        _isScanning = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _fingerprintData = "Scan failed: ${e.message}";
        _isScanning = false;
      });
      _showErrorSnackBar('Fingerprint scan failed: ${e.message}');
    }
  }

  Future<void> _captureFace() async {
    try {
      ImageSource? source;
      
      if (kIsWeb) {
        source = ImageSource.gallery;
      } else {
        source = await _showImageSourceDialog();
        if (source == null) return;
      }

      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _faceImage = pickedFile;
          _faceImageBase64 = base64Encode(bytes);
        });
        _showSuccessSnackBar('Face image captured successfully');
      } else {
        _showErrorSnackBar('No image selected');
      }
    } catch (e) {
      _showErrorSnackBar('Error capturing face image: $e');
      print('Face capture error: $e');
    }
  }

  Future<void> _captureAdharFront() async {
    try {
      ImageSource? source;
      
      if (kIsWeb) {
        source = ImageSource.gallery;
      } else {
        source = await _showImageSourceDialog();
        if (source == null) return;
      }

      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _adharImgF = pickedFile;
          _adharImgFBase64 = base64Encode(bytes);
        });
        _showSuccessSnackBar('Aadhar front image captured successfully');
      } else {
        _showErrorSnackBar('No image selected');
      }
    } catch (e) {
      _showErrorSnackBar('Error capturing Aadhar front: $e');
      print('Aadhar front capture error: $e');
    }
  }

  Future<void> _captureAdharBack() async {
    try {
      ImageSource? source;
      
      if (kIsWeb) {
        source = ImageSource.gallery;
      } else {
        source = await _showImageSourceDialog();
        if (source == null) return;
      }

      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _adharImgB = pickedFile;
          _adharImgBBase64 = base64Encode(bytes);
        });
        _showSuccessSnackBar('Aadhar back image captured successfully');
      } else {
        _showErrorSnackBar('No image selected');
      }
    } catch (e) {
      _showErrorSnackBar('Error capturing Aadhar back: $e');
      print('Aadhar back capture error: $e');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _checkExistingCustomer() async {
    if (kIsWeb) {
      _showErrorSnackBar('Fingerprint checking is not supported on web. Please use "Add New Customer"');
      return;
    }
    
    if (token == null || token!.isEmpty) {
      _showErrorSnackBar('Authentication required. Please login again.');
      return;
    }
    
    setState(() => _isScanning = true);
    try {
      final String fingerprintData = await platform.invokeMethod('scanFingerprint');
      
      final response = await http.post(
        Uri.parse('https://s-m-s-keyw.onrender.com/hotel/customer/check'),
        headers: _getAuthHeaders(),
        body: json.encode({
          'fingerprint_data': fingerprintData,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _existingCustomerData = data['userData'];
          _isExistingCustomer = true;
          _showForm = true;
          _fillFormWithExistingData();
        });
        _showSuccessSnackBar('Existing customer found');
      } else if (response.statusCode == 404) {
        _showErrorSnackBar('Customer not found. Please register new customer.');
        setState(() {
          _showForm = true;
          _isExistingCustomer = false;
        });
      } else {
        _handleAuthError(response.statusCode);
        _showErrorSnackBar('Error checking customer: ${response.body}');
      }
    } on PlatformException catch (e) {
      _showErrorSnackBar('Scan failed: ${e.message}');
    } catch (e) {
      _showErrorSnackBar('Network error: $e');
      print('Check customer error: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  void _fillFormWithExistingData() {
    if (_existingCustomerData != null) {
      _nameController.text = _existingCustomerData!['name'] ?? '';
      _addressController.text = _existingCustomerData!['address'] ?? '';
      _cityController.text = _existingCustomerData!['city'] ?? '';
      _stateController.text = _existingCustomerData!['state'] ?? '';
      _contactController.text = _existingCustomerData!['contact'] ?? '';
      _adharNoController.text = _existingCustomerData!['adharNo'] ?? '';
      _nationalityController.text = _existingCustomerData!['nationality'] ?? '';
      _fingerprintBase64 = _existingCustomerData!['fingerprint_data'] ?? '';
      _faceImageBase64 = _existingCustomerData!['face_image'] ?? '';
      _adharImgFBase64 = _existingCustomerData!['adharImgF'] ?? '';
      _adharImgBBase64 = _existingCustomerData!['adharImgB'] ?? '';
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Check authentication
      if (token == null || token!.isEmpty) {
        _showErrorSnackBar('Authentication required. Please login again.');
        return;
      }

      // Validate required images
      if (_faceImageBase64.isEmpty) {
        _showErrorSnackBar('Please capture face image');
        return;
      }
      if (_adharImgFBase64.isEmpty) {
        _showErrorSnackBar('Please capture Aadhar front image');
        return;
      }
      if (_adharImgBBase64.isEmpty) {
        _showErrorSnackBar('Please capture Aadhar back image');
        return;
      }
      
      // Skip fingerprint validation on web
      if (!kIsWeb && _fingerprintBase64.isEmpty) {
        _showErrorSnackBar('Please scan fingerprint');
        return;
      }

      setState(() => _isSubmitting = true);
      
      try {
        final payload = {
          "userData": {
            "name": _nameController.text.trim(),
            "address": _addressController.text.trim(),
            "city": _cityController.text.trim(),
            "state": _stateController.text.trim(),
            "contact": _contactController.text.trim(),
            "adharNo": _adharNoController.text.trim(),
            "nationality": _nationalityController.text.trim(),
            "fingerprint_data": _fingerprintBase64,
            "face_image": _faceImageBase64,
            "adharImgF": _adharImgFBase64,
            "adharImgB": _adharImgBBase64
          }
        };

        print('Platform: ${kIsWeb ? "Web" : "Mobile"}');
        print('Payload size: ${json.encode(payload).length} characters');
        print('Face image size: ${_faceImageBase64.length} characters');
        print('Aadhar front size: ${_adharImgFBase64.length} characters');
        print('Aadhar back size: ${_adharImgBBase64.length} characters');
        print('Fingerprint size: ${_fingerprintBase64.length} characters');

        final response = await http.post(
          Uri.parse('https://s-m-s-keyw.onrender.com/hotel/customer/register'),
          headers: _getAuthHeaders(),
          body: json.encode(payload),
        );

        if (response.statusCode == 200) {
          _showSuccessSnackBar('Registration successful!');
          _resetForm();
        } else {
          _handleAuthError(response.statusCode);
          _showErrorSnackBar('Error: ${response.body}');
          print('Server response: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        _showErrorSnackBar('Network error: $e');
        print('Submit error: $e');
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _contactController.clear();
    _adharNoController.clear();
    _nationalityController.clear();
    
    setState(() {
      _fingerprintData = "Not scanned";
      _fingerprintBase64 = "";
      _faceImage = null;
      _faceImageBase64 = "";
      _adharImgF = null;
      _adharImgFBase64 = "";
      _adharImgB = null;
      _adharImgBBase64 = "";
      _showForm = false;
      _isExistingCustomer = false;
      _existingCustomerData = null;
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while token is being loaded
    if (_isTokenLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AB Hotel Registration ${kIsWeb ? "(Web)" : "(Mobile)"}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (token != null && token!.isNotEmpty)
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await _clearTokenAndNavigateToLogin();
              },
              tooltip: 'Logout',
            ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Authentication status indicator
            if (token == null || token!.isEmpty)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Authentication required. Please login to continue.',
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ),
              ),

            if (kIsWeb)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Web Version: Camera and fingerprint features are limited. Use gallery to select images.',
                        style: TextStyle(color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (!_showForm) ...[
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              _buildMainActionButton(
                onPressed: (token != null && token!.isNotEmpty) ? () {
                  setState(() {
                    _showForm = true;
                    _isExistingCustomer = false;
                  });
                } : null,
                label: 'Add New Customer',
                icon: Icons.person_add,
                color: (token != null && token!.isNotEmpty) ? primaryColor : Colors.grey,
              ),
              SizedBox(height: 20),
              _buildMainActionButton(
                onPressed: (kIsWeb || token == null || token!.isEmpty) ? null : _checkExistingCustomer,
                label: kIsWeb ? 'Check Existing Customer (Not Available on Web)' : 'Check Existing Customer',
                icon: Icons.fingerprint,
                color: (kIsWeb || token == null || token!.isEmpty) ? Colors.grey : accentColor,
                isLoading: _isScanning,
              ),
            ] else ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isExistingCustomer)
                      Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Existing Customer Found',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                    _buildSectionHeader('1. Full Name'),
                    _buildTextFormField(_nameController, isRequired: true),
                    SizedBox(height: 16),

                    _buildSectionHeader('2. Address'),
                    _buildTextFormField(_addressController, maxLines: 3, 
                    // isRequired: true
                    ),
                    SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: _buildSectionHeader('3. City')),
                        SizedBox(width: 16),
                        Expanded(child: _buildSectionHeader('4. State')),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _buildTextFormField(_cityController, isRequired: true)),
                        SizedBox(width: 16),
                        Expanded(child: _buildTextFormField(_stateController, isRequired: true)),
                      ],
                    ),
                    SizedBox(height: 16),

                    _buildSectionHeader('5. Contact Number'),
                    _buildTextFormField(
                      _contactController,
                      keyboardType: TextInputType.phone,
                      isRequired: true,
                    ),
                    SizedBox(height: 16),

                    _buildSectionHeader('6. Aadhar Number'),
                    _buildTextFormField(_adharNoController,
                    //  isRequired: true
                     ),
                    SizedBox(height: 16),

                    _buildSectionHeader('7. Nationality'),
                    _buildTextFormField(_nationalityController, 
                    // isRequired: true
                    ),
                    SizedBox(height: 16),

                    _buildSectionHeader('8. Aadhar Card Front'),
                    _buildImageCaptureButton(
                      onPressed: _captureAdharFront,
                      label: kIsWeb ? 'Select Aadhar Front' : 'Capture Aadhar Front',
                      isCaptured: _adharImgF != null && _adharImgFBase64.isNotEmpty,
                      capturedImage: _adharImgF,
                    ),
                    SizedBox(height: 16),

                    _buildSectionHeader('9. Aadhar Card Back'),
                    _buildImageCaptureButton(
                      onPressed: _captureAdharBack,
                      label: kIsWeb ? 'Select Aadhar Back' : 'Capture Aadhar Back',
                      isCaptured: _adharImgB != null && _adharImgBBase64.isNotEmpty,
                      capturedImage: _adharImgB,
                    ),
                    SizedBox(height: 16),

                    if (!kIsWeb) ...[
                      _buildSectionHeader('10. Fingerprint Scan'),
                      _buildImageCaptureButton(
                        onPressed: _isScanning ? null : _scanFingerprint,
                        label: 'Scan Fingerprint',
                        isCaptured: !_fingerprintData.contains("Not scanned"),
                        isLoading: _isScanning,
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          _fingerprintData,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    _buildSectionHeader(kIsWeb ? '10. Face Photo' : '11. Face Photo'),
                    _buildImageCaptureButton(
                      onPressed: _captureFace,
                      label: kIsWeb ? 'Select Face Photo' : 'Capture Face',
                      isCaptured: _faceImage != null && _faceImageBase64.isNotEmpty,
                      capturedImage: _faceImage,
                    ),
                    SizedBox(height: 24),

                    // Submit Button
                    _buildSubmitButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      label: _isExistingCustomer ? 'Update Customer' : 'Register Customer',
                      isLoading: _isSubmitting,
                    ),
                    SizedBox(height: 12),

                    // Cancel Button
                    _buildCancelButton(
                      onPressed: _resetForm,
                      label: 'Cancel',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    required Color color,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 3,
        ),
        child: isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 26),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubmitButton({
    required VoidCallback? onPressed,
    required String label,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Widget _buildCancelButton({
    required VoidCallback? onPressed,
    required String label,
  }) {
    return SizedBox(
      height: 50,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: primaryColor,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller, {
    String? labelText,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: isRequired
          ? (value) => value!.isEmpty ? 'This field is required' : null
          : null,
    );
  }

  Widget _buildImageCaptureButton({
    required VoidCallback? onPressed,
    required String label,
    bool isCaptured = false,
    bool isLoading = false,
    XFile? capturedImage,
  }) {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: isCaptured ? Colors.green : accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCaptured ? Icons.check : (kIsWeb ? Icons.photo_library : Icons.camera_alt),
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          isCaptured ? '$label (Done)' : label,
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (capturedImage != null) ...[
          SizedBox(height: 8),
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: kIsWeb
                  ? Image.network(
                      capturedImage.path,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    )
                  : Image.file(
                      File(capturedImage.path),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _contactController.dispose();
    _adharNoController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }
}
