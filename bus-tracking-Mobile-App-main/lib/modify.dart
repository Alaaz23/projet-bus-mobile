import 'dart:convert';

import 'package:bus_tracking/my_app_bar.dart';
import 'package:bus_tracking/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';

class ModifyScreen extends StatefulWidget {
  final String nom;
  final String prenom;
  final String matricule;

  const ModifyScreen({
    Key? key,
    required this.nom,
    required this.prenom,
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

    if (previousPassword.isEmpty || newPassword.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Veuillez remplir tous les champs.',
      );
      return;
    }

    if (newPassword.length < 6) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Le nouveau mot de passe doit contenir au moins 6 caractères.',
      );
      return;
    }

    try {
      // Étape 1 : Vérifier l'ancien mot de passe via le backend (login)
      final verifyResponse = await http.post(
        Uri.parse('$kBackendBaseUrl/salaries/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matricule': widget.matricule,
          'password': previousPassword,
        }),
      );

      if (verifyResponse.statusCode != 200) {
        QuickAlert.show(context: context, type: QuickAlertType.error, text: 'Erreur réseau.');
        return;
      }

      final verifyData = jsonDecode(verifyResponse.body);
      if (verifyData['success'] != true) {
        QuickAlert.show(context: context, type: QuickAlertType.error, text: 'Mot de passe actuel incorrect.');
        return;
      }

      // Étape 2 : Changer le mot de passe
      final response = await http.post(
        Uri.parse('$kBackendBaseUrl/salaries/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matricule': widget.matricule,
          'password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        await QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'Mot de passe modifié avec succès.',
        );
        if (mounted) Navigator.of(context).pop();
      } else if (response.statusCode == 404) {
        QuickAlert.show(context: context, type: QuickAlertType.error, text: 'Utilisateur introuvable.');
      } else {
        QuickAlert.show(context: context, type: QuickAlertType.error, text: 'Erreur: ${response.statusCode}');
      }
    } catch (e) {
      QuickAlert.show(context: context, type: QuickAlertType.error, text: 'Erreur réseau. Vérifiez votre connexion.');
    }
  }
}
