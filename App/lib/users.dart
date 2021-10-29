import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:optimized_cached_image/optimized_cached_image.dart';

import 'util.dart';
import 'user_view.dart';

class Users extends StatefulWidget {
  @override
  _UsersState createState() => _UsersState();
}

class _UsersState extends State<Users> {
  late Future<List> _users;
  bool _has_users = false;

  @override
  initState() {
    super.initState();
    _users = _GetUsers();
  }

  Future<List> _GetUsers() async {
    try {
    var url = Uri.parse('https://walking-schedule.herokuapp.com/users/0');
    var res = await http.get(url, headers: {
      'X-API-Uid': FirebaseAuth.instance.currentUser!.uid
    });
    if (res.statusCode == 200) {
      _has_users = true;
      return json.decode(res.body);
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => BuildPopUpDialog(context, 'Error', 'code: ${res.statusCode}\nbody: ${res.body}'),
      );
      _has_users = false;
      return json.decode('[{"placeholder": true}]');
    }
    } catch (err) {
      showDialog(
        context: context,
        builder: (BuildContext context) => BuildPopUpDialog(context, 'Error', err.toString()),
      );
      _has_users = false;
      return json.decode('[{"placeholder": true}]');
    }
  }

  void _Reload() {
    setState(() {
      _users = _GetUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Users"),
        actions: [
          IconButton(
              onPressed: (){_Reload();},
              icon: const Icon(Icons.refresh)
          )
        ],
      ),
      body: FutureBuilder<List>(
          future: _users,
          builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              if (!_has_users) {
                return const Text('No users found');
              }
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        children: [
                          for (int i = 0; i < snapshot.data!.length; i++)
                            ListTile(
                              title: Text(snapshot.data![i]['name']),
                              subtitle: Text(snapshot.data![i]['role']),
                              leading: CircleAvatar(
                                child: OptimizedCacheImage(
                                  imageUrl: snapshot.data![i]['photo'],
                                  placeholder: (context, url) => const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward),
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (BuildContext context) => UserView(snapshot.data![i]['name'], snapshot.data![i]['photo'], snapshot.data![i]['role'])));
                              },
                            ),
                        ]
                    ),
                  ),
                ],
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          }
      )
    );
  }
}