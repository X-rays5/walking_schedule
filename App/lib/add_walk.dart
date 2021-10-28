import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'util.dart';

class AddWalk extends StatefulWidget {
  @override
  _AddWalkState createState() => _AddWalkState();
}

class _AddWalkState extends State<AddWalk> {
  late TextEditingController _walk_name_controller;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _walk_name_controller = TextEditingController();
  }

  @override
  void dispose() {
    _walk_name_controller.dispose();
    super.dispose();
  }

  Future<void> _DatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _PostWalk() async {
    try {
      var url = Uri.parse('http://192.168.1.18:3000/walks/${DateFormat('yyyy-MM-dd').format(_date)}'); //TODO: replace this with a server url
      Map data = {
        'name': _walk_name_controller.text,
      };
      var body = json.encode(data);
      var res = await http.post(url, headers: {'X-API-Uid': FirebaseAuth.instance.currentUser!.uid, "Content-Type": "application/json"}, body: body);
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

  void _Submit() async {
    if (int.parse(DateFormat('yyyyD').format(_date)) < int.parse(DateFormat('yyyyD').format(DateTime.now()))) {
      showDialog(
        context: context,
        builder: (BuildContext context) => BuildPopUpDialog(context, 'Error', 'Date can\'t be before current date'),
      );
    } else {
      if (_walk_name_controller.text.isNotEmpty) {
        _PostWalk();
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) => BuildPopUpDialog(context, 'Error', 'Name can\'t be empty'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.cancel_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Add Walk'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).backgroundColor,
        foregroundColor: Theme.of(context).primaryColor,
        onPressed: () => {
          _Submit()
        },
        child: const Icon(Icons.check),
      ),
      body: Column(
        children: [
          const Text('\n', style: TextStyle(fontSize: 5.0)), // without this the first TextField clips into the AppBar
          TextField(
            controller: _walk_name_controller,
            textAlign: TextAlign.left,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Input walk name',
              labelText: 'Name'
            ),
          ),
          TextButton(
              onPressed: (){_DatePicker(context);},
              child: Row(
                children: [
                  Text('Date: ${DateFormat('dd-MM-yyyy').format(_date)}'),
                  const Icon(Icons.calendar_today_rounded),
                ],
              )
          ),

        ],
      ),
    );
  }

}