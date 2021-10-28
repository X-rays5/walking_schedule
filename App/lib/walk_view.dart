import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'util.dart';

class WalkView extends StatelessWidget {
  WalkView(Map<String, dynamic> walk) : _walk = walk;

  final Map<String, dynamic> _walk;

  Future<void> _DeleteWalk(BuildContext context) async {
    try {
      var url = Uri.parse('http://192.168.1.18:3000/walks/${_walk['id']}'); //TODO: replace this with a server url
      var res = await http.delete(url, headers: {'X-API-Uid': FirebaseAuth.instance.currentUser!.uid});
      if (res.statusCode == 200) {
        Navigator.of(context).pop();
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) => BuildPopUpDialog(context, 'Error', 'code: ${res.statusCode}\nbody: ${res.body}'),
        );
      }
    } catch (err) {
      showDialog(
        context: context,
        builder: (BuildContext context) => BuildPopUpDialog(context, 'Error', err.toString()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_walk['name']),
          actions: [
            //list if widget in appbar actions
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),  //don't specify icon if you want 3 dot menu
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text("Delete"),
                  onTap: () => _DeleteWalk(context),
                ),
              ],
            ),
          ],
        ),
      body: Column(
        children: [
          Text(_walk['walker']),
          Text(_walk['date']),
          for (int i = 0; i < _walk['interested'].length; i++)
            Text(_walk['interested'][i]),
        ],
      ),
    );
  }
}