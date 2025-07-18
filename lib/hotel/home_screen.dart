import 'package:flutter/material.dart';
import './hotelScreen/add_customer.dart';

class HotelHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hotel Management'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel, size: 100, color: Colors.teal),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  // MaterialPageRoute(builder: (context) => HotelRegistrationForm()),
                  MaterialPageRoute(
                      builder: (context) => HotelRegistrationForm()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                'Register New Guest',
                style: TextStyle(
                  color: Colors.white, // Explicitly set text color to white
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
