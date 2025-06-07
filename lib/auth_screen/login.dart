import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:sms_apk/auth_screen/NotificationScreen.dart';
import 'package:sms_apk/utils/app_colors.dart';
import 'package:sms_apk/widgets/custom_popup.dart';
import '../Screens/homeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _forgotPasswordEmailController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _showForgotPassword = false; // New state for forgot password form

  // Email validation function
  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(email);
  }

  // Function to show animated popup dialog
  void _showPopupMessage(String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismiss
      builder: (context) {
        return FadeInDown(
          duration: Duration(milliseconds: 500),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? AppColors.primary : Colors.red,
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
          // If forgot password was successful, go back to login form
          setState(() {
            _showForgotPassword = false;
            _forgotPasswordEmailController.clear();
          });
        } else {
          // If login was successful, navigate to home screen
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => HomeScreen()));
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

  // Function to handle login request
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
      const String apiUrl = 'https://s-m-s-keyw.onrender.com/auth/login';
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token);
        await prefs.setString('email', email); // Store email
        await prefs.setString('password', password); // Store password
        // Fetch user data and store username
        await _fetchAndStoreUserData(token);

        _showPopupMessage('Login Successful!', true);
      } else {
        _showPopupMessage('Invalid email or password.', false);
      }
    } catch (e) {
      _showPopupMessage('Network error. Please try again.', false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Fetches data from API and stores it in SharedPreferences
  Future<void> _fetchAndStoreUserData(String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://s-m-s-keyw.onrender.com/self'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', json.encode(data));

        // Extract user details
        Map<String, dynamic> extractedData = _extractUserData(data);
        String extractedRole = data['role'] ?? "Unknown";

        // Store extracted data in SharedPreferences
        await prefs.setString('role', extractedRole);
        await prefs.setString('userName', extractedData['name']);
        await prefs.setString(
            'schoolAddress', extractedData['schoolAddress'] ?? "N/A");
        await prefs.setString(
            'adminContact', extractedData['adminContact'] ?? "N/A");
        await prefs.setString(
            'factAddress', extractedData['factAddress'] ?? "N/A");
        await prefs.setString(
            'factContact', extractedData['factContact'] ?? "N/A");
      } else if (response.statusCode == 400) {
        // Parse the response body to extract the error message
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody["detail"] ??
            "Invalid request. Please check your input.";
        showPopup(context, errorMessage, AppColors.primary);
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (error) {
      _showPopupMessage('Failed to load user data. Please try again.', false);
    }
  }

  /// Extracts the username based on the user's role
  Map<String, dynamic> _extractUserData(Map<String, dynamic> data) {
    if (data["role"] == "user") {
      return {
        "name": data["schoolCreationEntity"]?["ownerName"] ?? "Guest",
        "schoolAddress":
            data["schoolCreationEntity"]?["schoolAddress"] ?? "N/A",
        "adminContact": data["schoolCreationEntity"]?["adminContact"] ?? "N/A",
      };
    } else if (data["role"] == "sub-user") {
      return {
        "name": data["facultyInfo"]?["fact_Name"] ?? "Guest",
        "factAddress": data["facultyInfo"]?["fact_address"] ?? "N/A",
        "factContact": data["facultyInfo"]?["fact_contact"] ?? "N/A",
      };
    }
    return {
      "name": "Guest",
      "schoolAddress": "N/A",
      "adminContact": "N/A",
      "factAddress": "N/A",
      "factContact": "N/A",
    };
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
              decoration:
                  BoxDecoration(color: Color.fromARGB(255, 18, 102, 102)),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 30, 120, 120),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/ews-full-white.png',
                    height: 70, // Adjust height as needed
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // Login container with bounce animation
      Align(
  alignment: Alignment(0, 0.3), // 0.3 pushes it downward, increase for lower
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
                            _showForgotPassword ? 'Forgot Password' : 'Login',
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
                          // Email Input Field
                          FadeInRight(
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              cursorColor: AppColors.primary,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                floatingLabelStyle: TextStyle(color: AppColors.primary),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.primary),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.primary, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 15),

                          // Password Input Field with Eye Button
                          FadeInLeft(
                            child: TextField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              cursorColor: AppColors.primary,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                floatingLabelStyle: TextStyle(color: AppColors.primary),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.primary),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.primary, width: 2),
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
                                backgroundColor: AppColors.primary,
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
                                color: AppColors.primary,
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
                              cursorColor: AppColors.primary,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                floatingLabelStyle: TextStyle(color: AppColors.primary),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.primary),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.primary, width: 2),
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
                                backgroundColor: AppColors.primary,
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
                                color: AppColors.primary,
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
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NotificationScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Notifications"),
                ),
              ],
            ),
          ), // Your content
    ],
  ),
)

         
        ],
      ),
    );
  }
}