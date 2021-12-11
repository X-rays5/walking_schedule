import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'util.dart';

class WalkView extends StatefulWidget {
  WalkView(Map<String, dynamic> walk, bool is_admin) : _walk = walk, _is_admin = is_admin;

  final Map<String, dynamic> _walk;
  final bool _is_admin;

  @override
  _WalkViewState createState() => _WalkViewState(_walk, _is_admin);
}

class _WalkViewState extends State<WalkView> {
  _WalkViewState(Map<String, dynamic> walk, bool is_admin) : _walk = walk, _is_admin = is_admin;

  Map<String, dynamic> _walk;
  final bool _is_admin;

  late Future<List> _users;
  bool _has_users = false;

  @override
  initState() {
    super.initState();
    _users = _GetUsers();
  }

  Future<List> _GetUsers() async {
    try {
      var url = Uri.parse('https://walking-schedule.herokuapp.com/users/1');
      var res = await http.get(url, headers: {
        'X-API-Uid': FirebaseAuth.instance.currentUser!.uid
      });
      if (res.statusCode == 200) {
        if (res.body == '[]') {
          _has_users = false;
          // needs to have actual data even if there is nothing
          return json.decode('[{"placeholder": true}]');
        } else {
          _has_users = true;
          return json.decode(res.body);
        }
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

  Future<void> _DeleteWalk() async {
    try {
      var url = Uri.parse(
          'https://walking-schedule.herokuapp.com/walks/${_walk['id']}');
      var res = await http.delete(
          url, headers: {'X-API-Uid': FirebaseAuth.instance.currentUser!.uid});
      if (res.statusCode == 200) {
        Navigator.of(context).pop();
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) =>
              BuildPopUpDialog(context, 'Error',
                  'code: ${res.statusCode}\nbody: ${res.body}'),
        );
      }
    } catch (err) {
      showDialog(
        context: context,
        builder: (BuildContext context) =>
            BuildPopUpDialog(context, 'Error', err.toString()),
      );
    }
  }

  Future<void> _Interested(BuildContext context, bool interested) async {
    try {
      var url = Uri.parse(
          'https://walking-schedule.herokuapp.com/walks/${_walk['id']}/interested/$interested');
      var res = await http.patch(
          url, headers: {'X-API-Uid': FirebaseAuth.instance.currentUser!.uid});
      if (res.statusCode == 200) {
        setState(() {
          _walk = json.decode(res.body);
        });
        Navigator.of(context).pop();
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) =>
              BuildPopUpDialog(context, 'Error',
                  'code: ${res.statusCode}\nbody: ${res.body}'),
        );
      }
    } catch (err) {
      showDialog(
        context: context,
        builder: (BuildContext context) =>
            BuildPopUpDialog(context, 'Error', err.toString()),
      );
    }
  }

  Future<void> _SetWalker(BuildContext context, String name) async {
    try {
      var url = Uri.parse(
          'https://walking-schedule.herokuapp.com/walks/${_walk['id']}/walker/$name');
      var res = await http.patch(
          url, headers: {'X-API-Uid': FirebaseAuth.instance.currentUser!.uid});
      if (res.statusCode == 200) {
        setState(() {
          _walk = json.decode(res.body);
        });
        Navigator.of(context).pop();
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) =>
              BuildPopUpDialog(context, 'Error',
                  'code: ${res.statusCode}\nbody: ${res.body}'),
        );
      }
    } catch (err) {
      showDialog(
        context: context,
        builder: (BuildContext context) =>
            BuildPopUpDialog(context, 'Error', err.toString()),
      );
    }
  }

  String GetUserInterestedState(String username) {
    Map<String, dynamic> interested = _walk['interested'];
    if (interested.containsKey(username)) {
      if (interested[username] == true) {
        return 'Interested';
      } else {
        return 'Not interested';
      }
    } else {
      return 'Unanswered';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_walk['name']),
        actions: [
          PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text("Reload"),
                  onTap: () => _Reload(),
                ),
                if (_is_admin) PopupMenuItem(
                  child: const Text("Delete"),
                  onTap: () => _DeleteWalk(),
                ),
              ]),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).backgroundColor,
        foregroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Interested in walk?'),
                  content: const Text('This will make you available to be chosen for the walk'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _Interested(context, false).then((value) {
                        });
                      },
                      child: const Text('NO'),
                    ),
                    TextButton(
                      onPressed: () {
                        _Interested(context, true).then((value) {
                        });
                      },
                      child: const Text('YES'),
                    ),
                  ],
                );
              }
          );
        },
        icon: const Icon(Icons.directions_walk),
        label: const Text('Interested'),
      ),
      body: Column(
        children: [
          Center(
            child: Column(
              children: [
                Text('\nWalker: ${_walk['walker']}'),
                Text('Date: ${_walk['date']}'),
              ],
            ),
          ),
          if (_is_admin) FutureBuilder<List>(
              future: _users,
              builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  if (!_has_users) {
                    return const Center(
                      child: Text('\nCouldn\'t get users'),
                    );
                  }
                  return Expanded(
                    child: ListView(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      children: [
                        for (int i = 0; i < snapshot.data!.length; i++)
                          ListTile(
                            title: Text(snapshot.data![i]['name']),
                            subtitle: Text(GetUserInterestedState(snapshot.data![i]['name'])),
                            leading: const Icon(Icons.account_circle),
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Set user as walker for this walk'),
                                      content: Text('This will set ${snapshot.data![i]['name']} as the walker for this walk'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('NO'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _SetWalker(context, snapshot.data![i]['name']);
                                          },
                                          child: const Text('YES'),
                                        ),
                                      ],
                                    );
                                  }
                              );
                            },
                          ),
                      ],
                    ),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              }
          ),
        ],
      ),
    );
  }
}