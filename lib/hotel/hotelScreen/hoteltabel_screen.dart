import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class Customer {
  final String name;
  final String contact;
  final String adharNo;

  Customer({
    required this.name,
    required this.contact,
    required this.adharNo,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      name: json['name'] ?? 'N/A',
      contact: json['contact'] ?? 'N/A',
      adharNo: json['adharNo'] ?? 'N/A',
    );
  }
}

class Guest {
  final String? arrivalDate;
  final String? departureDate;
  final double deposit;
  final double amount;
  final Customer customersEntity;

  Guest({
    this.arrivalDate,
    this.departureDate,
    required this.deposit,
    required this.amount,
    required this.customersEntity,
  });

  factory Guest.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // ✅ CustomersEntity is a list, take the first one
    Customer customer = Customer.fromJson(
      (json['customersEntity'] != null &&
              json['customersEntity'] is List &&
              json['customersEntity'].isNotEmpty)
          ? json['customersEntity'][0]
          : {},
    );

    return Guest(
      arrivalDate: json['arrivalDate'],
      departureDate: (json['departureDate'] != null &&
              json['departureDate'].toString().trim().isNotEmpty)
          ? json['departureDate']
          : null,
      deposit: parseDouble(json['deposit']),
      amount: parseDouble(json['amount']),
      customersEntity: customer,
    );
  }
}

// --- Main Widget ---
class HotelGuestHistoryScreen extends StatefulWidget {
  const HotelGuestHistoryScreen({super.key});

  @override
  State<HotelGuestHistoryScreen> createState() =>
      _HotelGuestHistoryScreenState();
}

class _HotelGuestHistoryScreenState extends State<HotelGuestHistoryScreen> {
  List<Guest> _guests = [];
  List<Guest> _filteredGuests = [];
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;

  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  void initState() {
    super.initState();
    _fetchGuests();
  }

  Future<void> _fetchGuests() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication token missing. Please log in.')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse("https://s-m-s-keyw.onrender.com/hotelCheckInn/get"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        final fetchedGuests =
            data.map((item) => Guest.fromJson(item)).toList();

        // ✅ Only show guests with departureDate
        final initialFiltered =
            fetchedGuests.where((g) => g.departureDate != null).toList();

        if (mounted) {
          setState(() {
            _guests = fetchedGuests;
            _filteredGuests = initialFiltered;
          });
        }
      } else {
        if (mounted) {
          final errorBody = json.decode(res.body);
          final message = errorBody['message'] ?? 'Failed to fetch guests';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $message')));
        }
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Try again later.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleFilter() {
    final filtered = _guests.where((guest) {
      if (guest.departureDate == null) return false;

      final departure = DateTime.tryParse(guest.departureDate!);
      if (departure == null) return false;

      final departureDateOnly =
          DateTime(departure.year, departure.month, departure.day);
      final fromDateOnly = _fromDate != null
          ? DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day)
          : null;
      final toDateOnly = _toDate != null
          ? DateTime(_toDate!.year, _toDate!.month, _toDate!.day)
          : null;

      if (fromDateOnly != null && departureDateOnly.isBefore(fromDateOnly)) {
        return false;
      }
      if (toDateOnly != null && departureDateOnly.isAfter(toDateOnly)) {
        return false;
      }

      return true;
    }).toList();

    setState(() => _filteredGuests = filtered);
  }

  void _clearFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _filteredGuests =
          _guests.where((g) => g.departureDate != null).toList();
    });
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _fromDate) {
      setState(() => _fromDate = picked);
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _toDate) {
      setState(() => _toDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Guest History Report"),
        backgroundColor: const Color(0xFF1e7878),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Guest History Report',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 20),

            // --- Filters ---
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildDatePicker(
                  context,
                  label: 'From Date',
                  selectedDate: _fromDate,
                  onTap: () => _selectFromDate(context),
                ),
                _buildDatePicker(
                  context,
                  label: 'To Date',
                  selectedDate: _toDate,
                  onTap: () => _selectToDate(context),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleFilter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1e7878),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply Filter'),
                ),
                if (_fromDate != null || _toDate != null)
                  TextButton(
                    onPressed: _isLoading ? null : _clearFilters,
                    child: Text(
                      'Clear Filters',
                      style: TextStyle(
                        color: Colors.red[600],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Data Table ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5)
                ],
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF1e7878))),
                    )
                  : _filteredGuests.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(
                              child: Text("No guests found.",
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54))),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 16.0,
                            headingRowColor:
                                MaterialStateProperty.all(Colors.grey[100]),
                            columns: const [
                              DataColumn(
                                  label: Text('Name',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Contact',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Aadhar',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Arrival',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Departure',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Deposit (₹)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Total (₹)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Balance (₹)',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                            ],
                            rows: _filteredGuests.map((guest) {
                              final balance = guest.amount - guest.deposit;
                              final balanceColor = balance > 0
                                  ? Colors.red[600]
                                  : Colors.green[600];
                              return DataRow(cells: [
                                DataCell(Text(guest.customersEntity.name)),
                                DataCell(Text(guest.customersEntity.contact)),
                                DataCell(Text(guest.customersEntity.adharNo)),
                                DataCell(Text(
                                    guest.arrivalDate?.split("T")[0] ??
                                        'N/A')),
                                DataCell(Text(
                                    guest.departureDate?.split("T")[0] ??
                                        'N/A')),
                                DataCell(Text(
                                    _currencyFormatter.format(guest.deposit))),
                                DataCell(Text(
                                    _currencyFormatter.format(guest.amount))),
                                DataCell(Text(
                                  _currencyFormatter.format(balance),
                                  style: TextStyle(color: balanceColor),
                                )),
                              ]);
                            }).toList(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context,
      {required String label,
      DateTime? selectedDate,
      required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedDate == null
                      ? 'Select Date'
                      : _dateFormatter.format(selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.calendar_today,
                    size: 18, color: Color(0xFF1e7878)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
