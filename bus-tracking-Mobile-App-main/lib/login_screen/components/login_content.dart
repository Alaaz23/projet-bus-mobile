import 'package:bus_tracking/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bus_tracking/home_page.dart';

class LoginContent extends StatefulWidget {
  const LoginContent({Key? key}) : super(key: key);

  @override
  State<LoginContent> createState() => _LoginContentState();
}

class _LoginContentState extends State<LoginContent> {
  TextEditingController matriculeController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool matriculeError = false;
  bool passwordError = false;
  bool formSubmitted = false;

  Widget inputField(String hint, IconData iconData) {
    String errorMsg = '';

    if (formSubmitted) {
      if (hint == 'Matricule') {
        if (matriculeController.text.isEmpty) {
          errorMsg = 'Matricule is required';
        } else if (matriculeController.text.length != 6) {
          errorMsg = 'Matricule must be 6 characters long';
        }
      } else if (hint == 'Mot De Passe') {
        if (passwordController.text.isEmpty) {
          errorMsg = 'Password is required';
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 8),
      child: SizedBox(
        height: 50,
        child: Material(
          elevation: 8,
          shadowColor: Colors.black87,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          child: TextField(
            controller:
                hint == 'Matricule' ? matriculeController : passwordController,
            obscureText: hint == 'Mot De Passe',
            textAlignVertical: TextAlignVertical.bottom,
            onChanged: (text) {
              if (formSubmitted) {
                setState(() {
                  matriculeError = false;
                  passwordError = false;
                });
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor:
                  kInputFieldFillColor, // Use the color from constants.dart
              hintText: hint,
              prefixIcon: Icon(iconData),
              errorText: errorMsg.isNotEmpty ? errorMsg : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget logos() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 130, vertical: 8),
      child: Row(
        children: [
          Flexible(
            child: Container(
              height: 1,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(
              width: 16), // Add some space between the line and the image
          Image.asset(
            'assets/images/sof.png',
            height:
                60, // Adjust the height of the image as per your requirement
          ),
          const SizedBox(
              width: 16), // Add some space between the image and the line
          Flexible(
            child: Container(
              height: 1,
              color: kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget forgotPassword() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 110),
      child: TextButton(
        onPressed: () {},
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kSecondaryColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 130),
                logos(),
                inputField('Matricule', Ionicons.person_outline),
                inputField('Mot De Passe', Ionicons.lock_closed_outline),
                loginButton('Log In'),
                forgotPassword(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget loginButton(String buttonText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 130, vertical: 16),
      child: ElevatedButton(
        onPressed: () async {
          setState(() {
            formSubmitted = true;
            matriculeError = matriculeController.text.isEmpty ||
                matriculeController.text.length != 6;
            passwordError = passwordController.text.isEmpty;
          });

          if (matriculeError || passwordError) {
            // Show login error message
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please enter valid Matricule and Password.'),
              backgroundColor: Colors.red,
            ));
          } else {
            // Perform login here
            final success = await AuthService().login(
              context,
              matriculeController.text,
              passwordController.text,
            );
            if (!success) {
              // Login failed
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Login failed. Please check your credentials.'),
                backgroundColor: Colors.red,
              ));
            }
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const StadiumBorder(),
          backgroundColor: kSecondaryColor, // Use the color from constants.dart
          elevation: 8,
          shadowColor: Colors.black87,
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8081/Bus-tracking/salaries';
  static const String loginUrl = '$baseUrl/login';
  static const String resetPasswordUrl = '$baseUrl/reset-password';

  get data => null;

  Future<bool> login(BuildContext context, String matricule, String mdp) async {
    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'matricule': matricule,
          'password': mdp,
        }),
      );

      // Print response status code for debugging
      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Print response data for debugging
        print('Response data: $data');
        bool loginSuccess = data['success'] ?? false;
        if (loginSuccess) {
          // Check if the password is the default one
          bool isDefaultPassword = mdp == 'Sofrecom123#';
          if (isDefaultPassword) {
            // Prompt user to reset password
            _showPasswordResetDialog(context, matricule, data);
          } else {
            // Authentication succeeded
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => HomePage(
                  matricule: matricule,
                  id_st: data['id_st'], // Pass tragetId here
                  nom: data['nom'], // Pass nom here
                  prenom: data['prenom'],
                  id: data['id'],
                  id_b: data['id_b'],
                  password: data['password'], // Pass prenom here
                ), // Replace HomePage() with your home page widget
              ),
            );
          }
        } else {
          // Authentication failed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login failed. Please check your credentials.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return loginSuccess;
      } else {
        // Server returned an error response
        print('Server error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server error. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      // An error occurred
      print('An error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  Future<String> resetPassword(String matricule, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse(resetPasswordUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'matricule': matricule,
          'password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return "Password reset successfully";
      } else if (response.statusCode == 404) {
        return "User not found";
      } else {
        return "Failed to reset password";
      }
    } catch (e) {
      return "An error occurred";
    }
  }

  void _showPasswordResetDialog(
      BuildContext context, String matricule, dynamic data) {
    TextEditingController newPasswordController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Password Reset Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'For security reasons, you must reset your password before proceeding.',
              ),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final success = await AuthService().resetPassword(
                  matricule,
                  newPasswordController.text,
                );
                if (success == "Password reset successfully") {
                  // Reset successful, navigate to home page
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => HomePage(
                        matricule: matricule,
                        id_st: data['id_st'], // Pass tragetId here
                        nom: data['nom'], // Pass nom here
                        prenom: data['prenom'],
                        id: data['id'],
                        id_b: data['id_b'],
                        password: data['password'], // Pass prenom here
                      ),
                    ),
                  );
                } else {
                  // Reset failed, display error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Failed to reset password. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Reset Password'),
            ),
          ],
        );
      },
    );
  }
}
