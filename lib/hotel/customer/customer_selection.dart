import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'customer_checkIn_form.dart';
import '../hotelScreen/add_customer.dart'; // ✅ Your new customer form
import 'package:shared_preferences/shared_preferences.dart';

class CustomerData {
  final String id;
  final String name;
  final String adharNo;
  final String address;
  final String city;
  final String state;
  final String contact;
  final String nationality;

  CustomerData({
    required this.id,
    required this.name,
    required this.adharNo,
    required this.address,
    required this.city,
    required this.state,
    required this.contact,
    required this.nationality,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'adharNo': adharNo,
      'address': address,
      'city': city,
      'state': state,
      'contact': contact,
      'nationality': nationality,
    };
  }

  factory CustomerData.fromJson(Map<String, dynamic> json) {
    return CustomerData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      adharNo: json['adharNo'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      contact: json['contact'] ?? '',
      nationality: json['nationality'] ?? '',
    );
  }
}

class CustomerSelectionScreen extends StatefulWidget {
  const CustomerSelectionScreen({Key? key}) : super(key: key);

  @override
  State<CustomerSelectionScreen> createState() =>
      _CustomerSelectionScreenState();
}

class _CustomerSelectionScreenState extends State<CustomerSelectionScreen> {
  bool isScanning = false;
  String verificationMethod = "fingerprint"; // fingerprint / aadhar
  String aadharNumber = "";
  List<CustomerData> selectedCustomers = [];
  bool hasScanner = !kIsWeb; // Fingerprint scanner only on mobile

  Future<CustomerData?> fetchCustomerByAadhar(String aadharNo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";

      if (token.isEmpty) throw Exception("Authentication token not found");

      final response = await http.get(
        Uri.parse(
          "https://s-m-s-keyw.onrender.com/hotel/customer/get?aadhar=$aadharNo",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          return CustomerData.fromJson(data[0]);
        } else {
          throw Exception("NOT_FOUND");
        }
      } else {
        throw Exception("Failed with ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleFingerprint() async {
    setState(() => isScanning = true);
    await Future.delayed(Duration(seconds: 2)); // Mock scanning
    Fluttertoast.showToast(
        msg: "Fingerprint scanned. Backend integration pending.");
    setState(() => isScanning = false);
  }

  Future<void> _handleAadhar() async {
    setState(() => isScanning = true);
    try {
      final customer = await fetchCustomerByAadhar(aadharNumber);

      if (customer == null) {
        Fluttertoast.showToast(
            msg: "Customer not found, please register as new");
        return;
      }

      final already = selectedCustomers.any((c) => c.id == customer.id);
      if (already) {
        Fluttertoast.showToast(msg: "Customer already added");
      } else {
        setState(() {
          selectedCustomers.add(customer);
          aadharNumber = "";
        });
        Fluttertoast.showToast(msg: "${customer.name} added");
      }
    } catch (e) {
      if (e.toString().contains("NOT_FOUND")) {
        Fluttertoast.showToast(
            msg:
                "Customer not found, Please check Aadhar or register as new");
      } else {
        Fluttertoast.showToast(msg: "Error: ${e.toString()}");
      }
    } finally {
      setState(() => isScanning = false);
    }
  }

  void _proceedWithGroup() {
    if (selectedCustomers.isEmpty) {
      Fluttertoast.showToast(msg: "Please add at least one customer");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerCheckInForm(
          selectedCustomers:
              selectedCustomers.map((c) => c.toMap()).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text("Customer Registration ${kIsWeb ? "(Web)" : "(Mobile)"}"),
        backgroundColor: Color(0xFF126666),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Selected customers list
            if (selectedCustomers.isNotEmpty)
              Column(
                children: [
                  ...selectedCustomers.map(
                    (customer) => Card(
                      child: ListTile(
                        title: Text(customer.name),
                        subtitle: Text("Aadhar: ${customer.adharNo}"),
                        trailing: IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              selectedCustomers.remove(customer);
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Proceed button only if customers exist
                  ElevatedButton(
                    onPressed: _proceedWithGroup,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text("Proceed with Group Check-in"),
                  ),
                ],
              ),

            SizedBox(height: 10),

            // ✅ Add New Customer Button (always visible)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HotelRegistrationForm(),
                  ),
                );
              },
              icon: Icon(Icons.person_add),
              label: Text("Add New Customer"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFF1e7878),
                minimumSize: Size(double.infinity, 50),
              ),
            ),

            SizedBox(height: 20),

            // Toggle verification method
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildToggleButton("Fingerprint", "fingerprint"),
                SizedBox(width: 12),
                _buildToggleButton("Aadhar", "aadhar"),
              ],
            ),

            SizedBox(height: 16),

            // Fingerprint / Aadhar input
            if (verificationMethod == "fingerprint")
              ElevatedButton.icon(
                onPressed: (!hasScanner || isScanning) ? null : _handleFingerprint,
                icon: isScanning
                    ? CircularProgressIndicator(color: Colors.white)
                    : Icon(Icons.fingerprint),
                label: Text(isScanning
                    ? "Scanning..."
                    : "Add Customer with Fingerprint"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Color(0xFF1e7878),
                ),
              )
            else
              Column(
                children: [
                  TextField(
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    onChanged: (val) => aadharNumber = val,
                    decoration: InputDecoration(
                      labelText: "Enter 12-digit Aadhar",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: isScanning ? null : _handleAadhar,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Color(0xFF1e7878),
                    ),
                    child: isScanning
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Add Customer with Aadhar"),
                  ),
                ],
              ),

            SizedBox(height: 20),

            // Group Check-in instructions
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Group Check-in Instructions",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800])),
                  SizedBox(height: 4),
                  Text("• Add multiple customers by entering Aadhar numbers"),
                  Text("• Each customer will be added to group selection"),
                  Text("• Click 'Proceed with Group Check-in' when ready"),
                  Text("• All customers will be checked in together with shared booking"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, String method) {
    bool active = verificationMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => verificationMethod = method),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Color(0xFF126666) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                  color: active ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
