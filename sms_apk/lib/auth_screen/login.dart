import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
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
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Email validation function
  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      }
    });
  }

  // Function to handle login request
  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Input validation
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
              decoration: BoxDecoration(color: Color.fromARGB(255, 18, 102, 102)),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 30, 120, 120),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'EasyWaySolution',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),

          // Login container with bounce animation
          Center(
            child: BounceInDown(
              duration: Duration(seconds: 1),
              child: Container(
                padding: EdgeInsets.all(20),
                width: MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Login Title with fade effect
                    FadeInLeft(
                      child: Text(
                        'Login',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Email Input Field
                    FadeInRight(
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    SizedBox(height: 15),

                    // Password Input Field with Eye Button
                    FadeInLeft(
                      child: TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
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

                    // Login Button with pulse animation
                    Pulse(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.black,
                          elevation: 5,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('Login', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// // ignore_for_file: unused_local_variable, use_build_context_synchronously, library_private_types_in_public_api

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:animate_do/animate_do.dart';
// import '../Screens/homeScreen.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _isLoading = false;

//   // Function to handle login request
//   Future<void> _login() async {
//     setState(() {
//       _isLoading = true;
//     });

//     const String apiUrl = 'https://s-m-s-keyw.onrender.com/auth/login';
//     final response = await http.post(
//       Uri.parse(apiUrl),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'email': _emailController.text,
//         'password': _passwordController.text,
//       }),
//     );

//     setState(() {
//       _isLoading = false;
//     });

//     if (response.statusCode == 200) {
//       // Handle successful login
//       final data = json.decode(response.body);
//       final token = data['token'];

//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       await prefs.setString('authToken', token);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Login Successful!')),
//       );

//       // Navigate to MainScreen
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => HomeScreen()),
//       );
//     } else {
//       // Handle login failure
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Login Failed! Please check your credentials.')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     double screenHeight = MediaQuery.of(context).size.height;

//     return Scaffold(
//       backgroundColor: Color.fromARGB(255, 238, 235, 235),
//       body: Stack(
//         children: [
//           // Background color container with fade animation
//           FadeIn(
//             duration: Duration(seconds: 2),
//             child: Container(
//               height: screenHeight * 0.4,
//               padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
//               decoration: BoxDecoration(
//                 color: Color.fromARGB(
//                     255, 18, 102, 102), // Original background color
//               ),
//               child: Center(
//                 child: Container(
//                   padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                   decoration: BoxDecoration(
//                     color: Color.fromARGB(
//                         255, 30, 120, 120), // Lighter background for text
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     'EasyWaySolution',
//                     style: TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           // Centered login container with bounce animation
//           Center(
//             child: BounceInDown(
//               duration: Duration(seconds: 1),
//               child: Container(
//                 padding: EdgeInsets.all(20),
//                 width: MediaQuery.of(context).size.width * 0.85,
//                 decoration: BoxDecoration(
//                   color: const Color.fromARGB(255, 255, 255, 255),
//                   borderRadius: BorderRadius.circular(12),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black26,
//                       blurRadius: 10,
//                       spreadRadius: 2,
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Login Title with fade effect
//                     FadeInLeft(
//                       child: Text(
//                         'Login',
//                         style: TextStyle(
//                           fontSize: 26,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 20),

//                     // Email Input Field
//                     FadeInRight(
//                       child: TextField(
//                         controller: _emailController,
//                         decoration: InputDecoration(
//                           labelText: 'Email',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 15),

//                     // Password Input Field
//                     FadeInLeft(
//                       child: TextField(
//                         controller: _passwordController,
//                         obscureText: true,
//                         decoration: InputDecoration(
//                           labelText: 'Password',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 20),

//                     // Login Button with pulse animation
//                     Pulse(
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : _login,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue,
//                           foregroundColor: Colors.white,
//                           shadowColor: Colors.black,
//                           elevation: 5,
//                           padding: EdgeInsets.symmetric(vertical: 12),
//                           minimumSize:
//                               Size(double.infinity, 50), // Full width button
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         child: _isLoading
//                             ? CircularProgressIndicator(color: Colors.white)
//                             : Text('Login', style: TextStyle(fontSize: 18)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
