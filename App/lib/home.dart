import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:optimized_cached_image/optimized_cached_image.dart';
import 'package:http/http.dart' as http;
import 'package:quiver/time.dart';

import 'util.dart';
import 'walk_view.dart';
import 'users.dart';
import 'calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late Future<List> _walks;
  bool _has_walks = false;
  bool _is_admin = false;

  @override
  initState() {
    super.initState();
    _walks = _GetWalks();
  }

  Future<List> _GetWalks() async {
    DateTime cur_date = DateTime.now();
    try {
      var url = Uri.parse('https://walking-schedule.herokuapp.com/walks/${DateFormat('yyyy-MM-dd').format(DateTime.now())}/${DateFormat('yyyy-MM-dd').format(DateTime(cur_date.year, cur_date.month, daysInMonth(cur_date.year, cur_date.month)))}');
      var res = await http.get(url, headers: {
        'X-API-Uid': FirebaseAuth.instance.currentUser!.uid
      });
      if (res.statusCode == 200) {
        url = Uri.parse('https://walking-schedule.herokuapp.com/user/${FirebaseAuth.instance.currentUser!.displayName!}');
        var admin = await http.get(url, headers: {
          'X-API-Uid': FirebaseAuth.instance.currentUser!.uid
        });
        setState(() {
          _is_admin = json.decode(admin.body)['role'] == 'admin';
          FirebaseMessaging.instance.subscribeToTopic('admin');
        });
        if (res.body == '[]') {
          _has_walks = false;
          return json.decode('[{"placeholder": true}]');
        } else {
          _has_walks = true;
          return json.decode(res.body);
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) => BuildPopUpDialog(context, 'Error', 'code: ${res.statusCode}\nbody: ${res.body}'),
        );
        _has_walks = false;
        return json.decode('[{"placeholder": true}]');
      }
    } catch (err) {
      showDialog(
        context: context,
        builder: (BuildContext context) => BuildPopUpDialog(context, 'Error', err.toString()),
      );
      _has_walks = false;
      return json.decode('[{"placeholder": true}]');
    }
  }

  void _Reload() {
    setState(() {
      _walks = _GetWalks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
              onPressed: (){_Reload();},
              icon: const Icon(Icons.refresh)
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(_firebaseAuth.currentUser!.displayName!),
              accountEmail: Text(_firebaseAuth.currentUser!.email!),
              currentAccountPicture: CircleAvatar(
                child: OptimizedCacheImage(
                  imageUrl: _firebaseAuth.currentUser!.photoURL!,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
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
              title: const Text("Logout"),
              leading: const Icon(Icons.logout),
              onTap: (){_firebaseAuth.signOut();},
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const Center(
            child: Text('\nUpcoming this month \n',
            textAlign:
            TextAlign.center,style:
            TextStyle(fontWeight: FontWeight.bold,fontSize: 25.0),
            ),
          ),
          FutureBuilder<List>(
              future: _walks,
              builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  if (!_has_walks) {
                    return const Text('No upcoming walks');
                  }
                  return Container(
                    child:
                    Expanded(
                      child: ListView(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          children: [
                            for (int i = 0; i < snapshot.data!.length; i++)
                              ListTile(
                                title: Text(snapshot.data![i]['name']),
                                subtitle: Text('${InterestedCount(snapshot.data![i])}\nDate: ${snapshot.data![i]['date']}'),
                                leading: const Icon(Icons.directions_walk),
                                trailing: const Icon(Icons.arrow_forward),
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (BuildContext context) => WalkView(snapshot.data![i], _is_admin))).then((value) {
                                    _Reload();
                                  });
                                },
                              ),
                          ]
                      ),
                    ),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              }
          )
        ],
      ),
    );
  }

}