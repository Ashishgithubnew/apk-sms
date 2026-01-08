import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomerCheckInForm extends StatefulWidget {
  final List<Map<String, dynamic>> selectedCustomers;

  const CustomerCheckInForm({Key? key, required this.selectedCustomers})
      : super(key: key);

  @override
  State<CustomerCheckInForm> createState() => _CustomerCheckInFormState();
}

class _CustomerCheckInFormState extends State<CustomerCheckInForm> {
  final _formKey = GlobalKey<FormState>();
  bool isSubmitting = false;

  // Form Fields
  String guestNames = "";
  String address = "";
  String contact = "";
  String company = "";
  String idDetails = "";
  String nationality = "Indian";
  String maleCount = "1";
  String femaleCount = "0";
  String childCount = "0";
  String purpose = "";
  String comingFrom = "";
  String goingTo = "";
  String arrivalDate = DateTime.now().toIso8601String().substring(0, 16);
  String departureDate = "";
  String transport = "";
  String deposit = "";
  String billNo = "";
  String amount = "";
  String roomNumber = "";
  String remarks = "";

  List<String> allRooms = [];
  List<String> availableRooms = [];
  List<String> occupiedRooms = [];

  @override
  void initState() {
    super.initState();
    _populateGuestNames();
    _fetchRoomsAndGuests();
  }

  void _populateGuestNames() {
  if (widget.selectedCustomers.isNotEmpty) {
    // Sabke names comma separated
    guestNames = widget.selectedCustomers.map((c) => c['name']).join(", ");

    // Pehle guest ke details se baaki fields auto-fill
    final firstGuest = widget.selectedCustomers[0];
    address = firstGuest['address'] ?? '';
    contact = firstGuest['contact'] ?? '';
    idDetails = firstGuest['adharNo'] ?? '';
    company = firstGuest['company'] ?? '';
    nationality = firstGuest['nationality'] ?? 'Indian';
  }
}


  Future<void> _fetchRoomsAndGuests() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";
    if (token.isEmpty) return;

    // Step 1: Get all rooms from userDetails
    final userDetailsString = prefs.getString("userDetails");
    if (userDetailsString != null) {
      final userDetails = jsonDecode(userDetailsString);
      allRooms = List<String>.from(userDetails["hotelCreationEntity"]["roomNumber"] ?? []);
    }

    // Step 2: Call GET API to fetch checked-in guests
    try {
      final response = await http.get(
        Uri.parse("https://s-m-s-keyw.onrender.com/hotelCheckInn/get"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final guestData = jsonDecode(response.body);
        final occupiedRoomsList = guestData
            .where((guest) =>
                guest["departureDate"] == null ||
                guest["departureDate"].toString().isEmpty)
            .map<String>((guest) => guest["roomNumber"].toString())
            .toSet()
            .toList();

        setState(() {
          occupiedRooms = occupiedRoomsList;
          availableRooms = allRooms
              .where((room) => !occupiedRoomsList.contains(room))
              .toList();
        });
      } else {
        Fluttertoast.showToast(msg: "Failed to fetch guest data");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching guests: $e");
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    if (token.isEmpty) {
      Fluttertoast.showToast(msg: "Authentication token not found");
      setState(() => isSubmitting = false);
      return;
    }

    final payload = {
      "guestNames": guestNames,
      "address": address,
      "contact": contact,
      "company": company,
      "idDetails": idDetails,
      "nationality": nationality,
      "maleCount": maleCount,
      "femaleCount": femaleCount,
      "childCount": childCount,
      "purpose": purpose,
      "comingFrom": comingFrom,
      "goingTo": goingTo,
      "arrivalDate": arrivalDate,
      "departureDate": departureDate,
      "transport": transport,
      "deposit": deposit,
      "billNo": billNo,
      "amount": amount,
      "roomNumber": roomNumber,
      "remarks": remarks,
    };

    try {
      final response = await http.post(
        Uri.parse("https://s-m-s-keyw.onrender.com/hotelCheckInn/save"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "Check-in completed successfully!");
        Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(msg: "Check-in failed: ${response.body}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Widget _buildTextField(
      String label, String value, Function(String) onChanged,
      {bool required = false, TextInputType inputType = TextInputType.text}) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      keyboardType: inputType,
      validator:
          required ? (val) => val == null || val.isEmpty ? "Required" : null : null,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Check-in")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Guest Names", guestNames, (val) => guestNames = val, required: true),
              _buildTextField("Address", address, (val) => address = val, required: true),
              _buildTextField("Contact", contact, (val) => contact = val, required: true, inputType: TextInputType.phone),
              _buildTextField("Company", company, (val) => company = val),
              _buildTextField("ID Details", idDetails, (val) => idDetails = val),
              DropdownButtonFormField<String>(
                value: nationality,
                decoration: const InputDecoration(labelText: "Nationality"),
                items: ["Indian", "Foreigner"]
                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                    .toList(),
                onChanged: (val) => setState(() => nationality = val!),
              ),
              _buildTextField("Male Count", maleCount, (val) => maleCount = val, required: true, inputType: TextInputType.number),
              _buildTextField("Female Count", femaleCount, (val) => femaleCount = val, required: true, inputType: TextInputType.number),
              DropdownButtonFormField<String>(
                value: roomNumber.isNotEmpty ? roomNumber : null,
                decoration: const InputDecoration(labelText: "Room Number"),
                items: [
                  ...availableRooms.map((room) => DropdownMenuItem(
                        value: room,
                        child: Text("$room - Available"),
                      )),
                  ...occupiedRooms.map((room) => DropdownMenuItem(
                        value: room,
                        enabled: false,
                        child: Text("$room - Occupied"),
                      )),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => roomNumber = val);
                },
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              _buildTextField("Child Count", childCount, (val) => childCount = val, required: true, inputType: TextInputType.number),
              _buildTextField("Purpose of Visit", purpose, (val) => purpose = val, required: true),
              _buildTextField("Coming From", comingFrom, (val) => comingFrom = val, required: true),
              _buildTextField("Going To", goingTo, (val) => goingTo = val, required: true),
              _buildTextField("Transport Mode", transport, (val) => transport = val, required: true),
              _buildTextField("Deposit", deposit, (val) => deposit = val, inputType: TextInputType.number),
              _buildTextField("Bill No", billNo, (val) => billNo = val),
              _buildTextField("Amount", amount, (val) => amount = val, inputType: TextInputType.number),
              _buildTextField("Remarks", remarks, (val) => remarks = val),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isSubmitting ? null : _handleSubmit,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Complete Check-in"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
