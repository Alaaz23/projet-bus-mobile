import 'package:bus_tracking/my_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quickalert/quickalert.dart';

class FeedbackScreen extends StatefulWidget {
  final String nom;
  final String prenom;
  final int id;

  const FeedbackScreen({
    Key? key,
    required this.nom,
    required this.prenom,
    required this.id,
  }) : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: 'Feedback',
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 180),
          child: Column(
            children: [
              const Text(
                'Description:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(40.0),
                ),
                child: TextField(
                  controller: _descriptionController,
                  style: TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    hintText: 'Enter your Feedback here',
                    hintStyle: TextStyle(color: Colors.black),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_descriptionController.text.isEmpty) {
                    QuickAlert.show(
                      context: context,
                      type: QuickAlertType.error,
                      text: 'Please enter your feedback before submitting.',
                    );
                  } else {
                    final feedbackData = {
                      'description': _descriptionController.text,
                      'salarie': {
                        'id': widget.id,
                      },
                    };

                    final url = Uri.parse(
                        'http://10.0.2.2:8081/Bus-tracking/feedbacks/add');
                    final response = await http.post(
                      url,
                      headers: <String, String>{
                        'Content-Type': 'application/json; charset=UTF-8',
                      },
                      body: jsonEncode(feedbackData),
                    );

                    if (response.statusCode == 201) {
                      QuickAlert.show(
                        context: context,
                        type: QuickAlertType.success,
                        text: 'Feedback submitted successfully!',
                      );
                    } else {
                      QuickAlert.show(
                        context: context,
                        type: QuickAlertType.error,
                        text: 'Error submitting feedback.',
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
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
                      'Validate',
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
}
