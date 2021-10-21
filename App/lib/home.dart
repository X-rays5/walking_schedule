import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'settings.dart';
import 'users.dart';
import 'calendar.dart';

class HomePage extends StatelessWidget {
  final FirebaseAuth _firebaseAuth;
  HomePage(FirebaseAuth auth) : _firebaseAuth = auth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            Column(
              children: [
                Text(_firebaseAuth.currentUser!.displayName!),
                const Divider(
                  height: 20,
                  thickness: 4,
                  indent: 0,
                  endIndent: 0,
                ),
              ],
            ),
            ListTile(
              title: const Text("Calendar"),
              leading: const Icon(Icons.calendar_today_rounded),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => Calendar()));
              },
            ),
            ListTile(
              title: const Text("Users"),
              leading: const Icon(Icons.account_circle),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => Users()));
              },
            ),
            ListTile(
              title: const Text("Settings"),
              leading: const Icon(Icons.settings),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => Settings()));
              },
            ),
            ListTile(
              title: const Text("Logout"),
              leading: const Icon(Icons.logout),
              onTap: (){_firebaseAuth.signOut();},
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Center(child: Text(DateFormat('EEE d MMM').format(DateTime.now()),textAlign: TextAlign.center,style: new TextStyle(fontWeight: FontWeight.bold,fontSize: 25.0),)),
        ],
      ),
    );
  }

}