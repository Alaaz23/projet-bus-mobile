import 'dart:convert';

import 'package:bus_tracking/my_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';

class ModifyScreen extends StatefulWidget {
  final String nom;
  final String prenom;
  final String password;
  final String matricule;

  const ModifyScreen({
    Key? key,
    required this.nom,
    required this.prenom,
    required this.password,
    required this.matricule,
  }) : super(key: key);

  @override
  _ModifyScreenState createState() => _ModifyScreenState();
}

class _ModifyScreenState extends State<ModifyScreen> {
  late TextEditingController previousPasswordController;
  late TextEditingController newPasswordController;

  @override
  void initState() {
    super.initState();
    previousPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    previousPasswordController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: 'Modify',
      ),
      backgroundColor: Colors.white, // Set background color to white
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Modify your password',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 20),
              TextField(
                controller: previousPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Previous Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  resetPassword();
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero, // Remove any default padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.cyan,
                        Colors.indigo,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Container(
                    width: 200,
                    height: 45.0,
                    constraints:
                        const BoxConstraints(minWidth: 50.0, minHeight: 45.0),
                    alignment: Alignment.center,
                    child: const Text(
                      'Modify',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void resetPassword() async {
    String previousPassword = previousPasswordController.text;
    String newPassword = newPasswordController.text;

    // Check if the previous password matches the stored password
    if (previousPassword != widget.password) {
      // If previous password doesn't match, show error message
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Previous password does not match.',
      );
      return; // Exit the function
    }

    try {
      var response = await http.post(
        Uri.parse('http://10.0.2.2:8081/Bus-tracking/salaries/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matricule': widget.matricule,
          'password': newPassword,
          // Add any other parameters required by your backend service
        }),
      );

      if (response.statusCode == 200) {
        // Password reset successfully
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'Password reset successfully',
        );
      } else if (response.statusCode == 404) {
        // User not found
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'User not found',
        );
      } else {
        // Other errors
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Handle network errors
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'An error occurred: $e',
      );
    }
  }
}
