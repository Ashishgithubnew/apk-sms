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
  final TextEditingController _forgotPasswordEmailController =
      TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _showForgotPassword = false;

  // Colors
  final Color primaryColor = const Color(0xFF126666);
  final Color secondaryColor = const Color(0xFFE74C3C);
  final Color accentColor = const Color.fromARGB(255, 30, 120, 120);

  // Email validation
  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(email);
  }

  // Popup Message
  void _showPopupMessage(String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? primaryColor : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(isSuccess ? "Success" : "Error"),
              ],
            ),
            content: Text(message, style: const TextStyle(fontSize: 16)),
          ),
        );
      },
    );

   
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  
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

    setState(() => _isLoading = true);

    try {
      const String apiUrl =
          'https://s-m-s-keyw.onrender.com/auth/forget-password';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        _showPopupMessage(
            'Password reset instructions have been sent to your email.', true);
        setState(() {
          _showForgotPassword = false;
          _forgotPasswordEmailController.clear();
        });
      } else {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['message'] ??
            'Failed to send password reset email.';
        _showPopupMessage(errorMessage, false);
      }
    } catch (e) {
      _showPopupMessage('Network error. Please try again.', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  
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

  if (!mounted) return;
  setState(() => _isLoading = true);

  try {
    // 1. Login API
    const String loginUrl = 'https://s-m-s-keyw.onrender.com/auth/login';
    final response = await http.post(
      Uri.parse(loginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token'];

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('email', email);

      // 2. /self API
      final selfResponse = await http.get(
        Uri.parse('https://s-m-s-keyw.onrender.com/self'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (selfResponse.statusCode == 200) {
        final userData = json.decode(selfResponse.body);

        final role = (userData['role'] ?? "").toString().toLowerCase();
        final hotelName =
            userData['hotelCreationEntity']?['hotelName'] ?? 'Hotel';

        await prefs.setString('userDetails', json.encode(userData));
        await prefs.setString("loginType", role);
        await prefs.setString('hotelName', hotelName);
        await prefs.setBool("isLoggedIn", true);

        if (!mounted) return;

        // ✅ Clean navigation
        if (role == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const HotelAdminDashboardScreen()),
          );
        } else if (role == "hotel") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HotelHomeScreen()),
          );
        } else {
          _showPopupMessage('Unauthorized role. Please contact support.', false);
        }
      } else {
        _showPopupMessage('Failed to fetch user details.', false);
      }
    } else {
      final responseBody = jsonDecode(response.body);
      final errorMessage =
          responseBody['message'] ?? 'Invalid email or password.';
      _showPopupMessage(errorMessage, false);
    }
  } catch (e) {
    _showPopupMessage('Network error. Please try again.', false);
    debugPrint('Hotel login error: $e');
  } finally {
    if (!mounted) return;
    setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 238, 235, 235),
      body: Stack(
        children: [
          // Header
          FadeIn(
            duration: const Duration(seconds: 2),
            child: Container(
              height: screenHeight * 0.4,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(color: primaryColor),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.hotel, color: Colors.white, size: 50),
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

          // Login Form
          Align(
            alignment: const Alignment(0, 0.3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: BounceInDown(
                    duration: const Duration(seconds: 1),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      width: MediaQuery.of(context).size.width * 0.85,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              spreadRadius: 2),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _showForgotPassword
                                ? 'Forgot Password'
                                : 'Hotel Login',
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          const SizedBox(height: 20),

                          if (!_showForgotPassword) ...[
                            // Email
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              cursorColor: primaryColor,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Password
                            TextField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              cursorColor: primaryColor,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
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
                            const SizedBox(height: 20),

                            ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text('Login',
                                      style: TextStyle(fontSize: 18)),

                            ),
                            TextButton(
                              onPressed: () {
                                setState(() => _showForgotPassword = true);
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(color: primaryColor),
                              ),
                            ),
                          ] else ...[
                            // Forgot Password
                            TextField(
                              controller: _forgotPasswordEmailController,
                              keyboardType: TextInputType.emailAddress,
                              cursorColor: primaryColor,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _forgotPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text('Send Reset Link'),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showForgotPassword = false;
                                  _forgotPasswordEmailController.clear();
                                });
                              },
                              child: Text(
                                'Back to Login',
                                style: TextStyle(color: primaryColor),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Register New Hotel
                SizedBox(
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
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      "Register New Hotel",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
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

// Dummy Admin Dashboard for navigation test
class HotelAdminDashboardScreen extends StatelessWidget {
  const HotelAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hotel Admin Dashboard")),
      body: const Center(child: Text("Welcome Admin!")),
    );
  }
}
