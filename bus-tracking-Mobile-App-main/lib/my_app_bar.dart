import 'package:flutter/material.dart';
import 'package:flutter_gradient_app_bar/flutter_gradient_app_bar.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const MyAppBar({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(45.0), // Adjust the height as needed
      child: GradientAppBar(
        centerTitle: true,
        title: Text(
          title, // Use the provided title
          style: TextStyle(
            fontSize: 20, // Adjust the font size as needed
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        gradient: LinearGradient(
          colors: [
            Colors.cyan,
            Colors.indigo,
          ],
        ),
        actions: <Widget>[
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  // Add your action when the icon is clicked
                },
                icon: Icon(
                  Icons.notifications,
                  size: 28, // Adjust the size as needed
                ),
              ),
              Positioned(
                right: 0,
                child: Container(
                  margin: EdgeInsets.only(top: 4, right: 1.5),
                  padding: EdgeInsets.symmetric(
                      horizontal: 3.5, vertical: 2), // Add padding here
                  // Add margin here
                  decoration: BoxDecoration(
                    color: Color.fromARGB(141, 245, 245, 245),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 10,
                    maxHeight: 25,
                  ),
                  child: Text(
                    '0', // Your notification count
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
