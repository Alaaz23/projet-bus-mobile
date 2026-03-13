import 'package:bus_tracking/feedback.dart';
import 'package:bus_tracking/modify.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracking/login_screen/login_screen.dart';

class MyDrawer extends StatelessWidget {
  final String nom;
  final String prenom;
  final int id;
  final String password;
  final String matricule; // Add the ID parameter

  const MyDrawer({
    Key? key,
    required this.nom,
    required this.prenom,
    required this.id, required this.password, required this.matricule, // Add the ID parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyan,
                  Colors.indigo,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/sofrecom.png',
                  width: 50,
                  height: 50,
                ),
                Text(
                  'Nom & Prénom',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Montserrat',
                  ),
                ),
                Text(
                  '$nom $prenom',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Modify'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ModifyScreen(nom: nom, prenom: prenom,password: password,matricule: matricule)),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.feedback),
            title: Text('Feedback'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        FeedbackScreen(nom: nom, prenom: prenom, id: id)),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
