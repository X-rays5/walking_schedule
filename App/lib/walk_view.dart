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

  Future<void> _DeleteWalk(BuildContext context) async {
    try {
      var url = Uri.parse(
          'http://192.168.1.18:3000/walks/${_walk['id']}'); //TODO: replace this with a server url
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
          'http://192.168.1.18:3000/walks/${_walk['id']}/interested/$interested'); //TODO: replace this with a server url
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
          'http://192.168.1.18:3000/walks/${_walk['id']}/walker/$name'); //TODO: replace this with a server url
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

  Widget _InterestedUser(int i) {
    if (_walk['interested'][i] != '') {
      return ListTile(
        title: Text(_walk['interested'][i]),
        leading: const Icon(Icons.account_circle),
        onTap: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Set user as walker for this walk'),
                  content: Text('This will set ${_walk['interested'][i]} as the walker for this walk'),
                  actions: [
                    TextButton(
                      onPressed: () {
                          Navigator.of(context).pop();
                      },
                      child: const Text('NO'),
                    ),
                    TextButton(
                      onPressed: () {
                        _SetWalker(context, _walk['interested'][i]);
                      },
                      child: const Text('YES'),
                    ),
                  ],
                );
              }
          );
        },
      );
    } else {
      return const Center(child: Text(''));
    }
  }

  Widget _InterestedUsers() {
    if (_is_admin) {
      return ListView(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          children: [
            for (int i = 0; i < _walk['interested'].length; i++)
              _InterestedUser(i),
          ]
      );
    } else {
      return Container();
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
                  child: const Text("Delete"),
                  onTap: () => _DeleteWalk(context),
                ),
              ],
            ),
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
          Text('Walker: ${_walk['walker']}'),
          Text('Date: ${_walk['date']}'),
          Expanded(
              child:  _InterestedUsers(),
          ),
        ],
      ),
    );
  }
}