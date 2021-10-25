import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optimized_cached_image/optimized_cached_image.dart';
import 'package:quiver/time.dart';
import 'package:http/http.dart' as http;

import 'walk_view.dart';

class UserView extends StatefulWidget {
  const UserView(String username, String photo, String role, {Key? key}) : _username = username, _photo = photo, _role = role, super(key: key);

  final String _username;
  final String _photo;
  final String _role;

  @override
  _UserViewState createState() => _UserViewState(_username, _photo, _role);
}

class _UserViewState extends State<UserView> {
  _UserViewState(String username, String photo, String role) : _username = username, _photo = photo, _role = role;

  final String _username;
  final String _photo;
  final String _role;
  late DateTime _start_date;
  late DateTime _end_date;
  late Future<List> _walks;

  @override
  initState() {
    super.initState();
    DateTime date = DateTime.now();
    _start_date = DateTime(date.year, date.month, 1);
    _end_date = DateTime(date.year, date.month, daysInMonth(date.year, date.month));
    _walks = _GetWalks();
  }

  Future<List> _GetWalks() async {
    var url = Uri.parse('http://192.168.1.18:3000/walks/${_username}/${DateFormat('yyyy-MM-dd').format(_start_date)}/${DateFormat('yyyy-MM-dd').format(_end_date)}'); //TODO: replace this with a server url
    var res = await http.get(url, headers: {
      'X-API-Uid': FirebaseAuth.instance.currentUser!.uid
    });
    if (res.statusCode == 200) {
      return json.decode(res.body);
    } else {
      return await _GetWalks();
    }
  }

  void _Reload() {
    setState(() {
      _walks = _GetWalks();
    });
  }

  Future<void> _DatePickerStart(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _start_date,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null && picked != _start_date) {
      setState(() {
        _start_date = picked;
      });
      _Reload();
    }
  }

  Future<void> _DatePickerEnd(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _end_date,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null && picked != _end_date) {
      setState(() {
        _end_date = picked;
      });
      _Reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Info"),
        actions: [
          IconButton(
              onPressed: (){_Reload();},
              icon: const Icon(Icons.refresh)
          )
        ],
      ),
      body: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_username),
            accountEmail: Text(_role),
            currentAccountPicture: CircleAvatar(
              child: OptimizedCacheImage(
              imageUrl: _photo,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
          const Text('Walk period\n', style: TextStyle(fontSize: 20.0)),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                    onPressed: (){_DatePickerStart(context);},
                    child: Row(
                      children: [
                        Text(DateFormat('dd-MM-yyyy').format(_start_date)),
                        const Icon(Icons.calendar_today_rounded),
                      ],
                    )
                ),
                const VerticalDivider(
                  width: 3,
                  thickness: 2,
                ),
                TextButton(
                    onPressed: (){_DatePickerEnd(context);},
                    child: Row(
                      children: [
                        Text(DateFormat('dd-MM-yyyy').format(_end_date)),
                        const Icon(Icons.calendar_today_rounded),
                      ],
                    )
                ),
              ],
            ),
          ),
          FutureBuilder<List>(
            future: _walks,
            builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return Container(
                  child: Expanded(
                    child: ListView(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      children: [
                        for (int i = 0; i < snapshot.data!.length; i++)
                          ListTile(
                            title: Text(snapshot.data![i]['name']),
                            subtitle: Text(snapshot.data![i]['date']),
                            leading: const Icon(Icons.directions_walk),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) => WalkView(snapshot.data![i])));
                            },
                          ),
                      ],
                    ),
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