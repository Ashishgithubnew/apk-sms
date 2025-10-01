import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'customer/customer_selection.dart';

class HotelDetails {
  final String hotelName;
  final String ownerName;
  final int totalRooms;
  final String email;

  HotelDetails({
    required this.hotelName,
    required this.ownerName,
    required this.totalRooms,
    required this.email,
  });

  factory HotelDetails.fromJson(Map<String, dynamic> j) {
    return HotelDetails(
      hotelName: j['hotelName'] ?? '',
      ownerName: j['ownerName'] ?? '',
      totalRooms: (j['totalRooms'] is int) ? j['totalRooms'] : int.tryParse('${j['totalRooms']}') ?? 0,
      email: j['email'] ?? '',
    );
  }
}

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
}

class Customer {
  final String id;
  final String creationDateTime;
  final String? hotelCode;
  final String name;
  final String address;
  final String city;
  final String state;
  final String contact;
  final String adharNo;
  final String nationality;
  final String fingerprintData;

  Customer({
    required this.id,
    required this.creationDateTime,
    required this.hotelCode,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.contact,
    required this.adharNo,
    required this.nationality,
    required this.fingerprintData,
  });

  factory Customer.fromJson(Map<String, dynamic> j) {
    return Customer(
      id: j['id']?.toString() ?? '',
      creationDateTime: j['creationDateTime']?.toString() ?? '',
      hotelCode: j['hotelCode']?.toString(),
      name: j['name']?.toString() ?? '',
      address: j['address']?.toString() ?? '',
      city: j['city']?.toString() ?? '',
      state: j['state']?.toString() ?? '',
      contact: j['contact']?.toString() ?? '',
      adharNo: j['adharNo']?.toString() ?? '',
      nationality: j['nationality']?.toString() ?? '',
      fingerprintData: j['fingerprint_data']?.toString() ?? '',
    );
  }
}

class Guest {
  final String id;
  final String arrivalDate;
  final String guestNames;
  final String? address;
  final String? contact;
  final String? company;
  final String? idDetails;
  final String? nationality;
  final String maleCount;
  final String femaleCount;
  final String childCount;
  final String purpose;
  final String comingFrom;
  final String goingTo;
  final String departureDate;
  final String transport;
  final String deposit;
  final String billNo;
  final String amount;
  final String? roomNumber;
  final String remarks;

  final List<Customer> customersEntity;   // 👈 Change here

  Guest({
    required this.id,
    required this.arrivalDate,
    required this.guestNames,
    this.address,
    this.contact,
    this.company,
    this.idDetails,
    this.nationality,
    required this.maleCount,
    required this.femaleCount,
    required this.childCount,
    required this.purpose,
    required this.comingFrom,
    required this.goingTo,
    required this.departureDate,
    required this.transport,
    required this.deposit,
    required this.billNo,
    required this.amount,
    required this.remarks,
    this.roomNumber,
    required this.customersEntity,
  });

  factory Guest.fromJson(Map<String, dynamic> j) {
    return Guest(
      id: j['id']?.toString() ?? '',
      arrivalDate: j['arrivalDate']?.toString() ?? '',
      guestNames: j['guestNames']?.toString() ?? '',
      address: j['address']?.toString(),
      contact: j['contact']?.toString(),
      company: j['company']?.toString(),
      idDetails: j['idDetails']?.toString(),
      nationality: j['nationality']?.toString(),
      maleCount: j['maleCount']?.toString() ?? '0',
      femaleCount: j['femaleCount']?.toString() ?? '0',
      childCount: j['childCount']?.toString() ?? '0',
      purpose: j['purpose']?.toString() ?? '',
      comingFrom: j['comingFrom']?.toString() ?? '',
      goingTo: j['goingTo']?.toString() ?? '',
      departureDate: j['departureDate']?.toString() ?? '',
      transport: j['transport']?.toString() ?? '',
      deposit: j['deposit']?.toString() ?? '0',
      billNo: j['billNo']?.toString() ?? '',
      amount: j['amount']?.toString() ?? '0',
      remarks: j['remarks']?.toString() ?? '',
       roomNumber: j['roomNumber']?.toString(),
      customersEntity: (j['customersEntity'] is List)
          ? (j['customersEntity'] as List)
              .map((c) => Customer.fromJson(c))
              .toList()
          : [],
    );
  }
}

class HotelHomeScreen extends StatefulWidget {
  const HotelHomeScreen({Key? key}) : super(key: key);

  @override
  _HotelHomeScreenState createState() => _HotelHomeScreenState();
}

class _HotelHomeScreenState extends State<HotelHomeScreen> {
  HotelDetails? hotelDetails;
  List<Guest> guests = [];
  bool loading = true;
  String searchTerm = '';

  // Customer selection for group check-in
  List<CustomerData> selectedCustomers = [];
  bool isScanning = false;
  String verificationMethod = "adhar"; // "fingerprint" / "adhar"
  String aadharNumber = "";
  bool hasScanner = !kIsWeb;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadHotelData();
    await _fetchGuests();
  }

  Future<void> _loadHotelData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDetailsStr = prefs.getString('userDetails');
    if (userDetailsStr != null) {
      try {
        final parsed = jsonDecode(userDetailsStr);
        if (parsed != null && parsed['hotelCreationEntity'] != null) {
          setState(() {
            hotelDetails = HotelDetails.fromJson(parsed['hotelCreationEntity']);
          });
        }
      } catch (e) {
        debugPrint('Failed to parse userDetails: $e');
      }
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchGuests() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final token = await _getToken();
      final uri = Uri.parse('https://s-m-s-keyw.onrender.com/hotelCheckInn/get');
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<Guest> loaded = [];
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) loaded.add(Guest.fromJson(item));
          }
        } else if (decoded is Map<String, dynamic>) {
          loaded.add(Guest.fromJson(decoded));
        }
        if (!mounted) return;
        setState(() {
          guests = loaded;
        });
      } else {
        Fluttertoast.showToast(msg: 'Failed to fetch guest data');
      }
    } catch (e) {
      debugPrint('Error fetching guests: $e');
      Fluttertoast.showToast(msg: 'Error fetching guest data');
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _checkoutGuest(String guestId) async {
    try {
      final token = await _getToken();
      final departureDate = DateTime.now().toIso8601String().substring(0, 19);
      final payload = {'id': guestId, 'departureDate': departureDate};

      final uri = Uri.parse('https://s-m-s-keyw.onrender.com/checkout');
      final response = await http.post(uri,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'authorization': 'Bearer $token',
          },
          body: jsonEncode(payload));

      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(msg: 'Guest checked out successfully');
        await _fetchGuests();
      } else {
        Fluttertoast.showToast(msg: 'Failed to checkout guest');
      }
    } catch (e) {
      debugPrint('Checkout error: $e');
      Fluttertoast.showToast(msg: 'Error during checkout');
    }
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.of(context).pushReplacementNamed('/');
  }

  List<Guest> get currentGuests {
    return guests.where((g) => g.departureDate.trim().isEmpty).toList();
  }

  int get todayBookings {
    final today = DateTime.now();
    return currentGuests.where((g) {
      try {
        final arrival = DateTime.parse(g.arrivalDate);
        return arrival.year == today.year && arrival.month == today.month && arrival.day == today.day;
      } catch (_) {
        return g.arrivalDate.split('T').first == DateFormat('yyyy-MM-dd').format(today);
      }
    }).length;
  }

  double get todayRevenue {
    final today = DateTime.now();
    double total = 0;
    for (final g in guests) {
      try {
        final arrival = DateTime.parse(g.arrivalDate);
        if (arrival.year == today.year && arrival.month == today.month && arrival.day == today.day) {
          total += double.tryParse(g.amount) ?? 0;
        }
      } catch (_) {}
    }
    return total;
  }

  int get availableRooms {
    final total = hotelDetails?.totalRooms ?? 0;
    return total - currentGuests.length;
  }

  @override
  Widget build(BuildContext context) {
    final hotelName = hotelDetails?.hotelName ?? 'Hotel Management';

    return Scaffold(
      appBar: AppBar(
        title: Text(hotelName),
        actions: [IconButton(icon: Icon(Icons.logout), onPressed: _handleLogout)],
      ),
      body: SafeArea(
        child: loading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // header
                    _buildHeader(hotelName),

                    SizedBox(height: 20),

                    // dashboard cards
                    GridView.count(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      crossAxisCount: MediaQuery.of(context).size.width > 900
                          ? 3
                          : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3 / 1.4,
                      children: [
                       _buildCard(
  title: 'Register / Select Customer',
  subtitle: 'Add customers for check-in',
  icon: Icons.person_add,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerSelectionScreen(),
      ),
    );
  },
  color: Colors.teal,
),

                        _buildCard(
                          title: 'Manage Guests',
                          subtitle: 'View and manage existing guests',
                          icon: Icons.people,
                          onTap: _openGuestModal,
                          color: Colors.blue,
                        ),
                       _buildCard(
  title: 'Guest History & Reports',
  subtitle: 'View past guests & reports',
  icon: Icons.bar_chart,
  onTap: () => Navigator.of(context).pushNamed('/hotel-tabel'),
  color: Colors.orange,
),
                      ],
                    ),

                    SizedBox(height: 18),

                    // quick overview
                    _buildOverview(),

                    SizedBox(height: 32),

                    // footer
                    Center(
                      child: Column(
                        children: [
                          Text('© 2024 $hotelName. All rights reserved.', style: TextStyle(color: Colors.grey[700])),
                          SizedBox(height: 4),
                          Text('Powered by EasyWaySolution Hotel Management System',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  // =================== UI Helpers ===================

  Widget _buildHeader(String hotelName) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: Colors.teal[50], shape: BoxShape.circle),
            child: Center(child: Icon(Icons.hotel, size: 36, color: Colors.teal[700])),
          ),
          SizedBox(height: 12),
          Text('Welcome to $hotelName', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('Manage your hotel operations efficiently with our system.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final bg = Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))]),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: (color ?? Colors.teal).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color ?? Colors.teal, size: 26),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              ]),
            ),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(backgroundColor: color ?? Colors.teal,foregroundColor: Colors.white),
              child: Text('Get Started'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Overview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
              children: [
                _overviewTile(icon: Icons.people, title: '${currentGuests.length}', subtitle: 'Current Guests'),
                _overviewTile(icon: Icons.bed, title: '$availableRooms', subtitle: 'Available Rooms'),
                _overviewTile(icon: Icons.calendar_today, title: '$todayBookings', subtitle: "Today's Bookings"),
                _overviewTile(icon: Icons.attach_money, title: '₹${todayRevenue.toStringAsFixed(2)}', subtitle: "Today's Revenue"),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _overviewTile({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 22, color: Colors.teal),
          ),
          SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey[700])),
          ])
        ],
      ),
    );
  }



// Toggle Button for Modal
Widget _buildToggleButtonModal(String label, String method, StateSetter setModalState) {
  bool active = verificationMethod == method;
  return Expanded(
    child: GestureDetector(
      onTap: () => setModalState(() => verificationMethod = method),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? Color(0xFF126666) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: active ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ),
  );
}

  // ==================== Guest Modal ====================
void _openGuestModal() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black.withOpacity(0.5),
    builder: (ctx) {
      return FractionallySizedBox(
        heightFactor: 0.9,
        child: StatefulBuilder(
          builder: (context, setModalState) {
            List<Guest> filtered = currentGuests.where((guest) {
              if (guest.customersEntity.isEmpty) return false;
              final matches = guest.customersEntity.any((c) {
                final nameMatch = c.name.toLowerCase().contains(searchTerm.toLowerCase());
                final contactMatch = c.contact.contains(searchTerm);
                return nameMatch || contactMatch;
              });
              return matches;
            }).toList();

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  // ===== Header =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Current Guests',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  // ===== Search Box =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name or contact number...',
                        suffixIcon: searchTerm.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () => setModalState(() => searchTerm = ''),
                              )
                            : null,
                      ),
                      onChanged: (v) => setModalState(() => searchTerm = v),
                    ),
                  ),

                  // ===== Guests Table =====
                  Expanded(
                    child: loading
                        ? Center(child: CircularProgressIndicator())
                        : filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.people, size: 48, color: Colors.grey[400]),
                                    SizedBox(height: 8),
                                    Text(searchTerm.isEmpty
                                        ? 'No guests currently checked in.'
                                        : 'No guests match your search.'),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 12,
                                    horizontalMargin: 6,
                                    columns: const [
                                      DataColumn(label: Text('Guest Names')),
                                      DataColumn(label: Text('Contact')),
                                      DataColumn(label: Text('Address')),
                                      DataColumn(label: Text('Aadhar')),
                                      DataColumn(label: Text('Counts (M/F/C)')),
                                      DataColumn(label: Text('Deposit (₹)')),
                                      DataColumn(label: Text('Total (₹)')),
                                      DataColumn(label: Text('Balance (₹)')),
                                      DataColumn(label: Text('Actions')),
                                    ],
                                    rows: filtered.map((g) {
                                      final customers = g.customersEntity;
                                      final deposit = double.tryParse(g.deposit) ?? 0;
                                      final total = double.tryParse(g.amount) ?? 0;
                                      final balance = total - deposit;

                                      // Names, contacts, addresses, aadhar joined
                                      final namesDisplay = customers.map((c) => c.name).join(", ");
                                      final contactsDisplay = customers.map((c) => c.contact).join(", ");
                                      final addressesDisplay = customers.map((c) => c.address).join(", ");
                                      final aadharDisplay = customers.map((c) => c.adharNo).join(", ");

                                      // Sum counts
                                      int maleCount = int.tryParse(g.maleCount) ?? 0;
                                      int femaleCount = int.tryParse(g.femaleCount) ?? 0;
                                      int childCount = int.tryParse(g.childCount) ?? 0;

                                      return DataRow(cells: [
                                        DataCell(Text(namesDisplay)),
                                        DataCell(Text(contactsDisplay)),
                                        DataCell(Text(addressesDisplay)),
                                        DataCell(Text(aadharDisplay)),
                                        DataCell(Text(
                                          'M:$maleCount F:$femaleCount C:$childCount',
                                          style: TextStyle(fontSize: 12),
                                        )),
                                        DataCell(Text(deposit.toStringAsFixed(2))),
                                        DataCell(Text(total.toStringAsFixed(2))),
                                        DataCell(
                                          Text(
                                            balance.toStringAsFixed(2),
                                            style: TextStyle(color: balance > 0 ? Colors.red : Colors.green),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red,foregroundColor: Colors.white),
                                                child: Text('Checkout'),
                                                onPressed: () async {
                                                  Navigator.of(context).pop();
                                                  await _checkoutGuest(g.id);
                                                },
                                              ),
                                              SizedBox(width: 8),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue,foregroundColor: Colors.white),
                                                child: Text('View'),
                                                onPressed: () {
                                                  _openGuestDetailModal(g);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ),
                  ),

                  // ===== Footer =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${filtered.length} of ${currentGuests.length} guests',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal,foregroundColor: Colors.white),
                          child: Text('Back to Dashboard'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
void _openGuestDetailModal(Guest guest) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black.withOpacity(0.5),
    builder: (ctx) {
      return FractionallySizedBox(
        heightFactor: 0.8,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Guest Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Guest info summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Guest Names: ${guest.customersEntity.map((c) => c.name).join(", ")}'),
                    Text('Arrival: ${guest.arrivalDate}'),
                    Text('Departure: ${guest.departureDate.isEmpty ? "-" : guest.departureDate}'),
                    Text('Room Number: ${guest.roomNumber ?? "-"}'),
                    SizedBox(height: 12),
                  ],
                ),
              ),

              Divider(),

              // Customers List
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  itemCount: guest.customersEntity.length,
                  itemBuilder: (context, index) {
                    final c = guest.customersEntity[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(c.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Contact: ${c.contact}'),
                            Text('Address: ${c.address}'),
                            Text('Aadhar: ${c.adharNo}'),
                            Text('Nationality: ${c.nationality}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}



}
