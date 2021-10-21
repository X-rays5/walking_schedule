import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'settings.dart';
import 'users.dart';
import 'calendar.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog walking calendar',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: HomePage(title: "Home"),
    );
  }
}

class HomePage extends StatelessWidget {
  final String title;

  HomePage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: login page
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            Column(
              children: [
                Text("username"), //TODO: get username
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
              onTap: (){_LogOut();},
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

void _LogOut() {
  // TODO: actually log the user out
}