import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserPassword extends StatefulWidget {
  const UserPassword({Key? key}) : super(key: key);

  @override
  _UserPasswordState createState() => _UserPasswordState();
}

class _UserPasswordState extends State<UserPassword> {
  final TextEditingController emailController = TextEditingController();
  String password = '';
  bool loading = false;
  bool obscurePassword = true;
  String? errorMessage;
  String? successMessage;
  final String apiUrl = 'https://s-m-s-keyw.onrender.com/auth/edit';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      debugPrint('All SharedPreferences keys: ${prefs.getKeys()}');

      String? email = prefs.getString('email') ?? prefs.getString('flutter.email');

      if ((email == null || email.isEmpty) && prefs.containsKey('userData')) {
        final userDataString = prefs.getString('userData') ?? prefs.getString('flutter.userData');
        if (userDataString != null && userDataString.isNotEmpty) {
          try {
            final userData = json.decode(userDataString) as Map<String, dynamic>;
            email = userData['email']?.toString();

            if (email == null) {
              if (userData.containsKey('schoolCreationEntity')) {
                email = userData['schoolCreationEntity']?['email']?.toString();
              }
              if (email == null && userData.containsKey('adminCreationEntity')) {
                email = userData['adminCreationEntity']?['email']?.toString();
              }
            }
          } catch (e) {
            debugPrint('Error parsing userData: $e');
          }
        }
      }

      if (email != null && email.isNotEmpty) {
        setState(() {
          emailController.text = email!;
        });
        debugPrint('Successfully loaded email: $email');
        await prefs.setString('email', email!);
      } else {
        setState(() {
          emailController.text = 'Email not found in preferences';
        });
        debugPrint('Failed to find email in any location');
      }
    } catch (e) {
      debugPrint('Error in _loadUserDetails: $e');
      setState(() {
        emailController.text = 'Error loading email';
      });
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final possibleTokenKeys = [
        'token',
        'authToken',
        'auth_token',
        'jwt',
        'access_token',
        'flutter.token',
      ];

      for (final key in possibleTokenKeys) {
        final token = prefs.getString(key);
        if (token != null && token.isNotEmpty) {
          debugPrint('Found token in key: $key');
          return token;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      errorMessage = null;
      successMessage = null;
    });

    final email = emailController.text.trim();

    if (email.isEmpty || email == 'Email not found in preferences' || email == 'Error loading email') {
      setState(() {
        errorMessage = 'Valid email not available. Please log in again.';
      });
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final token = await _getAuthToken();

      if (token == null) {
        setState(() {
          errorMessage = 'Authentication token not found. Please log in again.';
          loading = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        setState(() {
          successMessage = 'Password updated successfully!';
          password = '';
          _formKey.currentState?.reset();
        });
      } else {
        String message = 'Failed to update password.';
        if (response.body.isNotEmpty) {
          try {
            final errorData = json.decode(response.body);
            message = errorData['message'] ?? message;
          } catch (e) {
            debugPrint('Error parsing response: $e');
          }
        }

        setState(() {
          errorMessage = message;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Failed to update password. Please try again.';
      });
      debugPrint('Error updating password: $error');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              if (errorMessage != null)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),

              if (successMessage != null)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          successMessage!,
                          style: TextStyle(color: Colors.green.shade800),
                        ),
                      ),
                    ],
                  ),
                ),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              )),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: emailController,
                            readOnly: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              fillColor: Colors.grey.shade100,
                              filled: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            style: TextStyle(
                              color: emailController.text.contains('Loading') ||
                                      emailController.text.contains('not found') ||
                                      emailController.text.contains('Error')
                                  ? Colors.red.shade800
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('New Password',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              )),
                          SizedBox(height: 8),
                          TextFormField(
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              hintText: 'Enter new password',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                password = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: loading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(200, 50),
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: Colors.blue.shade200,
                        ),
                        child: loading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Update Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
