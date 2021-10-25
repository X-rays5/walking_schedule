import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:optimized_cached_image/optimized_cached_image.dart';

import 'user_view.dart';

class Users extends StatefulWidget {
  @override
  _UsersState createState() => _UsersState();
}

class _UsersState extends State<Users> {
  late Future<List> _users;

  @override
  initState() {
    super.initState();
    _users = _GetUsers();
  }

  Future<List> _GetUsers() async {
    var url = Uri.parse('http://192.168.1.18:3000/users/0'); //TODO: replace this with a server url
    var res = await http.get(url, headers: {
      'X-API-Uid': FirebaseAuth.instance.currentUser!.uid
    });
    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      return await _GetUsers();
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
                                    builder: (BuildContext context) => UserView(snapshot.data![i]['name'], snapshot.data![i]['photo'], snapshot.data![i]['role']))); // TODO: insert walk id
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