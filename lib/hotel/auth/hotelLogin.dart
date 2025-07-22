import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_apk/hotel/auth/hotelRegister.dart';
import 'package:sms_apk/hotel/home_screen.dart';

class HotelLoginScreen extends StatefulWidget {
  const HotelLoginScreen({super.key});

  @override
  _HotelLoginScreenState createState() => _HotelLoginScreenState();
}

class _HotelLoginScreenState extends State<HotelLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _forgotPasswordEmailController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _showForgotPassword = false;

  // Color Palette
  final Color primaryColor = Color(0xFF126666);
  final Color secondaryColor = Color(0xFFE74C3C);
  final Color accentColor = Color.fromARGB(255, 30, 120, 120);

  // Email validation function
  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(email);
  }

  // Function to show animated popup dialog
  void _showPopupMessage(String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FadeInDown(
          duration: Duration(milliseconds: 500),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? primaryColor : Colors.red,
                ),
                SizedBox(width: 8),
                Text(isSuccess ? "Success" : "Error"),
              ],
            ),
            content: Text(message, style: TextStyle(fontSize: 16)),
          ),
        );
      },
    );

    // Auto-close popup after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pop(context);
      if (isSuccess) {
        if (_showForgotPassword) {
          setState(() {
            _showForgotPassword = false;
            _forgotPasswordEmailController.clear();
          });
        } else {
          // Navigate to hotel home screen
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => HotelHome()));
        }
      }
    });
  }

  // Function to handle forgot password request
  Future<void> _forgotPassword() async {
    String email = _forgotPasswordEmailController.text.trim();
    if (email.isEmpty) {
      _showPopupMessage('Please enter your email address.', false);
      return;
    }
    if (!_isValidEmail(email)) {
      _showPopupMessage('Please enter a valid email address.', false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Hotel forgot password API endpoint
      const String apiUrl = 'https://s-m-s-keyw.onrender.com/auth/forget-password';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        _showPopupMessage('Password reset instructions have been sent to your email.', true);
      } else {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['message'] ?? 'Failed to send password reset email.';
        _showPopupMessage(errorMessage, false);
      }
    } catch (e) {
      _showPopupMessage('Network error. Please try again.', false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to handle hotel login request
  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showPopupMessage('Please fill in all fields.', false);
      return;
    }

    if (!_isValidEmail(email)) {
      _showPopupMessage('Please enter a valid email address.', false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Hotel login API endpoint
      const String apiUrl = 'https://s-m-s-keyw.onrender.com/auth/login';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Hotel login response status: ${response.statusCode}');
      print('Hotel login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token);
        await prefs.setString('email', email);
        await prefs.setString('userType', 'hotel'); // Store user type
        
        // Fetch and store hotel data
        await _fetchAndStoreHotelData(token);
        
        _showPopupMessage('Login Successful!', true);
      } else {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['message'] ?? 'Invalid email or password.';
        _showPopupMessage(errorMessage, false);
      }
    } catch (e) {
      _showPopupMessage('Network error. Please try again.', false);
      print('Hotel login error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch and store hotel data
  Future<void> _fetchAndStoreHotelData(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://s-m-s-keyw.onrender.com/hotel/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        
        await prefs.setString('hotelData', json.encode(data));
        await prefs.setString('hotelName', data['hotelName'] ?? 'Unknown Hotel');
        await prefs.setString('ownerName', data['ownerName'] ?? 'Unknown Owner');
        await prefs.setString('role', 'hotel');
      }
    } catch (error) {
      print('Failed to load hotel data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 238, 235, 235),
      body: Stack(
        children: [
          // Background container with fade animation
          FadeIn(
            duration: Duration(seconds: 2),
            child: Container(
              height: screenHeight * 0.4,
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(color: primaryColor),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hotel,
                        color: Colors.white,
                        size: 50,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Hotel Management',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Login container
          Align(
            alignment: Alignment(0, 0.3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BounceInDown(
                        duration: Duration(seconds: 1),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          width: MediaQuery.of(context).size.width * 0.85,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  spreadRadius: 2),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title with fade effect
                              FadeInLeft(
                                child: Text(
                                  _showForgotPassword ? 'Forgot Password' : 'Hotel Login',
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                              ),
                              SizedBox(height: 20),
                              
                              // Conditional rendering based on form state
                              if (!_showForgotPassword) ...[
                                // Login Form
                                FadeInRight(
                                  child: TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    cursorColor: primaryColor,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      floatingLabelStyle: TextStyle(color: primaryColor),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: primaryColor),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: primaryColor, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 15),
                                
                                FadeInLeft(
                                  child: TextField(
                                    controller: _passwordController,
                                    obscureText: !_isPasswordVisible,
                                    cursorColor: primaryColor,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      floatingLabelStyle: TextStyle(color: primaryColor),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: primaryColor),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: primaryColor, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(_isPasswordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                
                                // Login Button
                                Pulse(
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.black,
                                      elevation: 5,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      minimumSize: Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: _isLoading
                                        ? CircularProgressIndicator(color: Colors.white)
                                        : Text('Login', style: TextStyle(fontSize: 18)),
                                  ),
                                ),
                                SizedBox(height: 15),
                                
                                // Forgot Password Link
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showForgotPassword = true;
                                    });
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 16,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // Forgot Password Form
                                FadeInRight(
                                  child: TextField(
                                    controller: _forgotPasswordEmailController,
                                    keyboardType: TextInputType.emailAddress,
                                    cursorColor: primaryColor,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      floatingLabelStyle: TextStyle(color: primaryColor),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: primaryColor),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: primaryColor, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                
                                // Send Reset Link Button
                                Pulse(
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _forgotPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.black,
                                      elevation: 5,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      minimumSize: Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: _isLoading
                                        ? CircularProgressIndicator(color: Colors.white)
                                        : Text('Send Reset Link', style: TextStyle(fontSize: 18)),
                                  ),
                                ),
                                SizedBox(height: 15),
                                
                                // Back to Login Link
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showForgotPassword = false;
                                      _forgotPasswordEmailController.clear();
                                    });
                                  },
                                  child: Text(
                                    'Back to Login',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 16,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Register New Hotel Button
                      Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => HotelForm()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 3,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_business, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Register New Hotel",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
