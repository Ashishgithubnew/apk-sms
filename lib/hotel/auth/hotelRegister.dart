import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HotelForm extends StatefulWidget {
  @override
  _HotelFormState createState() => _HotelFormState();
}

class _HotelFormState extends State<HotelForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  // Color Palette
  final Color primaryColor = Color(0xFF126666);
  final Color secondaryColor = Color(0xFFE74C3C);
  final Color accentColor = Color.fromARGB(255, 30, 120, 120);
  final Color backgroundColor = Color(0xFFECF0F1);

  // Form controllers
  final TextEditingController _hotelNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _totalRoomsController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();

  String _selectedSubscription = 'Basic';
  final List<String> _subscriptionOptions = ['Basic', 'Premium', 'Enterprise'];

  @override
  void initState() {
    super.initState();
    // Set default country
    _countryController.text = 'India';
  }

  Future<void> _submitHotelForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        final payload = {
          "hotelName": _hotelNameController.text.trim(),
          "ownerName": _ownerNameController.text.trim(),
          "contactNumber": _contactController.text.trim(),
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
          "address": _addressController.text.trim(),
          "city": _cityController.text.trim(),
          "state": _stateController.text.trim(),
          "pincode": _pincodeController.text.trim(),
          "country": _countryController.text.trim(),
          "totalRooms": _totalRoomsController.text.trim(),
          "subscription": _selectedSubscription,
          "gstNumber": _gstNumberController.text.trim(),
        };

        print('Sending hotel creation payload: ${json.encode(payload)}');

        final response = await http.post(
          Uri.parse('https://s-m-s-keyw.onrender.com/hotelCreation/save'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(payload),
        );

        print('Hotel creation response status: ${response.statusCode}');
        print('Hotel creation response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          _showSuccessSnackBar('Hotel created successfully!');
          _resetHotelForm();
        } else {
          final errorData = json.decode(response.body);
          _showErrorSnackBar('Hotel creation failed: ${errorData['message'] ?? 'Unknown error'}');
        }
      } catch (e) {
        _showErrorSnackBar('Network error: $e');
        print('Hotel creation error: $e');
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetHotelForm() {
    _formKey.currentState?.reset();
    _hotelNameController.clear();
    _ownerNameController.clear();
    _contactController.clear();
    _emailController.clear();
    _passwordController.clear();
    _addressController.clear();
    _cityController.clear();
    _stateController.clear();
    _pincodeController.clear();
    _countryController.text = 'India';
    _totalRoomsController.clear();
    _gstNumberController.clear();
    setState(() {
      _selectedSubscription = 'Basic';
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hotel Creation Form',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 2,
      ),
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_business,
                      size: 50,
                      color: primaryColor,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Create New Hotel',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Register your hotel business with our management platform',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Hotel Business Information Section
              _buildSectionCard(
                title: 'Hotel Business Details',
                icon: Icons.business,
                children: [
                  _buildSectionHeader('Hotel Name'),
                  _buildTextFormField(
                    controller: _hotelNameController,
                    hintText: 'Enter your hotel name',
                    isRequired: true,
                  ),
                  SizedBox(height: 16),

                  _buildSectionHeader('Total Rooms'),
                  _buildTextFormField(
                    controller: _totalRoomsController,
                    hintText: 'Enter total number of rooms',
                    keyboardType: TextInputType.number,
                    // isRequired: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  SizedBox(height: 16),

                  _buildSectionHeader('Subscription Plan'),
                  _buildDropdownField(),
                  SizedBox(height: 16),

                  _buildSectionHeader('GST Number'),
                  _buildTextFormField(
                    controller: _gstNumberController,
                    hintText: 'Enter GST number (15 digits)',
                    // isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'GST number is required';
                      }
                      if (value.length != 15) {
                        return 'GST number must be 15 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Hotel Owner Information Section
              _buildSectionCard(
                title: 'Hotel Owner Details',
                icon: Icons.person_pin,
                children: [
                  _buildSectionHeader('Owner Name'),
                  _buildTextFormField(
                    controller: _ownerNameController,
                    hintText: 'Enter hotel owner full name',
                    isRequired: true,
                  ),
                  SizedBox(height: 16),

                  _buildSectionHeader('Contact Number'),
                  _buildTextFormField(
                    controller: _contactController,
                    hintText: 'Enter 10-digit mobile number',
                    keyboardType: TextInputType.phone,
                    isRequired: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Contact number is required';
                      }
                      if (value.length != 10) {
                        return 'Contact number must be 10 digits';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  _buildSectionHeader('Email Address'),
                  _buildTextFormField(
                    controller: _emailController,
                    hintText: 'Enter business email address',
                    keyboardType: TextInputType.emailAddress,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  _buildSectionHeader('Account Password'),
                  _buildPasswordField(),
                ],
              ),

              SizedBox(height: 20),

              // Hotel Location Information Section
              _buildSectionCard(
                title: 'Hotel Location Details',
                icon: Icons.location_on,
                children: [
                  _buildSectionHeader('Hotel Address'),
                  _buildTextFormField(
                    controller: _addressController,
                    hintText: 'Enter complete hotel address',
                    maxLines: 3,
                    isRequired: true,
                  ),
                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('City'),
                            _buildTextFormField(
                              controller: _cityController,
                              hintText: 'Enter city',
                              isRequired: true,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('State'),
                            _buildTextFormField(
                              controller: _stateController,
                              hintText: 'Enter state',
                              isRequired: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Pincode'),
                            _buildTextFormField(
                              controller: _pincodeController,
                              hintText: 'Enter pincode',
                              keyboardType: TextInputType.number,
                              isRequired: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Pincode is required';
                                }
                                if (value.length != 6) {
                                  return 'Pincode must be 6 digits';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('Country'),
                            _buildTextFormField(
                              controller: _countryController,
                              hintText: 'Enter country',
                              isRequired: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 32),

              // Submit Button
              _buildSubmitButton(),

              SizedBox(height: 16),

              // Reset Button
              _buildResetButton(),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 24),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: primaryColor,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isRequired = false,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator ?? (isRequired
          ? (value) => value!.isEmpty ? 'This field is required' : null
          : null),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Create account password (min 8 characters)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password is required';
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade50,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSubscription,
          isExpanded: true,
          items: _subscriptionOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedSubscription = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitHotelForm,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Creating Hotel...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_business, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Create Hotel',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      height: 50,
      child: TextButton(
        onPressed: _resetHotelForm,
        style: TextButton.styleFrom(
          foregroundColor: secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: secondaryColor),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh, size: 20),
            SizedBox(width: 8),
            Text(
              'Reset Form',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hotelNameController.dispose();
    _ownerNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _totalRoomsController.dispose();
    _gstNumberController.dispose();
    super.dispose();
  }
}
