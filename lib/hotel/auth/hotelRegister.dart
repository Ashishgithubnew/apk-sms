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

  // Colors
  final Color primaryColor = Color(0xFF126666);
  final Color secondaryColor = Color(0xFFE74C3C);
  final Color backgroundColor = Color(0xFFECF0F1);

  // Controllers
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
  final TextEditingController _roomNumberController = TextEditingController();

  String _selectedSubscription = 'Basic';
  final List<String> _subscriptionOptions = ['Basic', 'Premium', 'Enterprise'];

  String? _selectedReferral;
  final List<String> _referralOptions = ['viveksaini', 'gaurav'];

  List<String> _roomNumbers = [];

  @override
  void initState() {
    super.initState();
    _countryController.text = 'India';

    // Listen to total rooms changes to rebuild UI for room input
    _totalRoomsController.addListener(() {
      setState(() {});
    });
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
    _roomNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitHotelForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        "hotelName": _hotelNameController.text.trim(),
        "ownerName": _ownerNameController.text.trim(),
        "contactNumber": _contactController.text.trim(),
        "referral": _selectedReferral ?? '',
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
        "roomNumber": _roomNumbers.map((e) => int.tryParse(e) ?? 0).toList(),
      };

      final response = await http.post(
        Uri.parse('https://s-m-s-keyw.onrender.com/hotelCreation/save'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Hotel created successfully!', success: true);

        _resetHotelForm();
        Navigator.pop(context, true);
      } else {
        final errorData = json.decode(response.body);
        _showSnackBar('Hotel creation failed: ${errorData['message'] ?? 'Unknown error'}', success: false);
      }
    } catch (e) {
      _showSnackBar('Network error: $e', success: false);
    } finally {
      setState(() => _isSubmitting = false);
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
    _roomNumberController.clear();
    _roomNumbers.clear();
    setState(() {
      _selectedSubscription = 'Basic';
      _selectedReferral = null;
    });
  }

  void _showSnackBar(String message, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Hotel Creation Form', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionCard(
                title: 'Hotel Business Details',
                icon: Icons.business,
                children: [
                  _buildTextFieldWithHeader('Hotel Name', _hotelNameController, 'Enter hotel name', isRequired: true),
                  _buildTextFieldWithHeader('Total Rooms', _totalRoomsController, 'Enter total rooms', keyboardType: TextInputType.number),
                  _buildRoomNumberInput(),
                  _buildDropdownFieldWithHeader('Referral (optional)', _referralOptions, _selectedReferral, (val) => setState(() => _selectedReferral = val)),
_buildDropdownFieldWithHeader(
  'Subscription Plan',
  _subscriptionOptions,
  _selectedSubscription,
  (val) => setState(() => _selectedSubscription = val ?? 'Basic'),
),
                  _buildTextFieldWithHeader('GST Number', _gstNumberController, 'Enter GST number'),
                ],
              ),
              _buildSectionCard(
                title: 'Hotel Owner Details',
                icon: Icons.person_pin,
                children: [
                  _buildTextFieldWithHeader('Owner Name', _ownerNameController, 'Enter owner name', isRequired: true),
                  _buildTextFieldWithHeader('Contact Number', _contactController, 'Enter 10-digit number', keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)], validator: (v) {
                    if (v == null || v.isEmpty) return 'Contact number required';
                    if (v.length != 10) return 'Must be 10 digits';
                    return null;
                  }),
                  _buildTextFieldWithHeader('Email Address', _emailController, 'Enter email', keyboardType: TextInputType.emailAddress, validator: (v) {
                    if (v == null || v.isEmpty) return 'Email required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Invalid email';
                    return null;
                  }),
                  _buildPasswordField(),
                ],
              ),
              _buildSectionCard(
                title: 'Hotel Location Details',
                icon: Icons.location_on,
                children: [
                  _buildTextFieldWithHeader('Address', _addressController, 'Enter address', maxLines: 3, isRequired: true),
                  Row(
                    children: [
                      Expanded(child: _buildTextFieldWithHeader('City', _cityController, 'Enter city', isRequired: true)),
                      SizedBox(width: 16),
                      Expanded(child: _buildTextFieldWithHeader('State', _stateController, 'Enter state', isRequired: true)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextFieldWithHeader('Pincode', _pincodeController, 'Enter pincode', keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)], validator: (v) {
                          if (v == null || v.isEmpty) return 'Pincode required';
                          if (v.length != 6) return 'Must be 6 digits';
                          return null;
                        }),
                      ),
                      SizedBox(width: 16),
                      Expanded(child: _buildTextFieldWithHeader('Country', _countryController, 'Enter country', isRequired: true)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildSubmitButton(),
              SizedBox(height: 12),
              _buildResetButton(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------ WIDGET BUILDERS ------------------------

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: primaryColor), SizedBox(width: 8), Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor))]),
        SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _buildTextFieldWithHeader(String header, TextEditingController controller, String hintText,
      {bool isRequired = false, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, int maxLines = 1, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(header, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: primaryColor)),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(hintText: hintText, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey.shade50, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          validator: validator ?? (isRequired ? (v) => v!.isEmpty ? 'This field is required' : null : null),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Create password (min 8 chars)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password required';
        if (v.length < 8) return 'Min 8 characters';
        return null;
      },
    );
  }

  Widget _buildDropdownFieldWithHeader(String header, List<String> options, String? selectedValue, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(header, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: primaryColor)),
        SizedBox(height: 6),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              hint: Text('Select'),
              isExpanded: true,
              items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget _buildRoomNumberInput() {
    int totalRooms = int.tryParse(_totalRoomsController.text) ?? 0;
    bool isRoomLimitReached = _roomNumbers.length >= totalRooms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Room Numbers', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: primaryColor)),
        SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _roomNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: totalRooms > 0 && !isRoomLimitReached,
                decoration: InputDecoration(hintText: 'Enter room number', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.grey.shade50, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: (_roomNumberController.text.isEmpty || isRoomLimitReached) ? null : () {
                setState(() {
                  _roomNumbers.add(_roomNumberController.text.trim());
                  _roomNumberController.clear();
                });
              },
              child: Icon(Icons.add),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
            ),
          ],
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _roomNumbers.map((room) => Chip(label: Text(room), deleteIcon: Icon(Icons.close, size: 18), onDeleted: () => setState(() => _roomNumbers.remove(room)))).toList(),
        ),
        if (isRoomLimitReached && totalRooms > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('You have reached total rooms!', style: TextStyle(color: Colors.red)),
          ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitHotelForm,
        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: _isSubmitting
            ? CircularProgressIndicator(color: Colors.white)
            : Text('Create Hotel', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      height: 50,
      child: TextButton(
        onPressed: _resetHotelForm,
        style: TextButton.styleFrom(foregroundColor: secondaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: secondaryColor))),
        child: Text('Reset Form', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
