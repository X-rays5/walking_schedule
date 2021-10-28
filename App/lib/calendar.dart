import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'util.dart';
import 'add_walk.dart';
import 'walk_view.dart';

class Calendar extends StatefulWidget {
  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime _date = DateTime.now();
  final List _days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  final List _months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

  late Future<List> _walks;
  late bool _is_admin = false;
  bool _walks_today = false;

  @override
  initState() {
    super.initState();
    _walks = _GetWalks();
  }

  Future<List> _GetWalks() async {
    try {
      var url = Uri.parse('http://192.168.1.18:3000/walks/${DateFormat('yyyy-MM-dd').format(_date)}'); //TODO: replace this with a server url
      var res = await http.get(url, headers: {
        'X-API-Uid': FirebaseAuth.instance.currentUser!.uid
      });
      if (res.statusCode == 200) {
        url = Uri.parse('http://192.168.1.18:3000/user/${FirebaseAuth.instance.currentUser!.displayName!}');
        var admin = await http.get(url, headers: {
          'X-API-Uid': FirebaseAuth.instance.currentUser!.uid
        });
        setState(() {
          _is_admin = json.decode(admin.body)['role'] == 'admin';
        });
        if (res.body == '[]') {
          _walks_today = false;
          return json.decode('[{"placeholder": true}]');
        } else {
          _walks_today = true;
          return json.decode(res.body);
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) => BuildPopUpDialog(context, 'Error', 'code: ${res.statusCode}\nbody: ${res.body}'),
        );
        _walks_today = false;
        return json.decode('[{"placeholder": true}]');
      }
    } catch (err) {
      showDialog(
        context: context,
        builder: (BuildContext context) => BuildPopUpDialog(context, 'Error', err.toString()),
      );
      _walks_today = false;
      return json.decode('[{"placeholder": true}]');
    }
  }

  void _Reload() {
    setState(() {
      _walks = _GetWalks();
    });
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
      _Reload();
    }
  }

  Widget _AddWalkButton(BuildContext context) {
    if (_is_admin) {
      return FloatingActionButton(
        backgroundColor: Theme.of(context).backgroundColor,
        foregroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) => AddWalk())).then((value) {
             _Reload();
          });
        },
        child: const Icon(Icons.add),
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar"),
        actions: [
          IconButton(
              onPressed: (){_Reload();},
              icon: const Icon(Icons.refresh)
          )
        ],
      ),
      floatingActionButton: _AddWalkButton(context),
      body: Column(
        children: [
          Center(
            child: TextButton(
                onPressed: (){_DatePicker(context);},
                child: Text(_days[_date.weekday - 1]+DateFormat(' dd ').format(_date)+_months[_date.month - 1]+' '+DateFormat('yyyy').format(_date))
            ),
          ),
          FutureBuilder<List>(
              future: _walks,
              builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  if (!_walks_today) {
                    return const Center(
                      child: Text('Nothing available for this date'),
                    );
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
                                  subtitle: InterestedCount(snapshot.data![i]),
                                  leading: const Icon(Icons.directions_walk),
                                  trailing: const Icon(Icons.arrow_forward),
                                  onTap: () {
                                    Navigator.of(context).push(MaterialPageRoute(
                                        builder: (BuildContext context) => WalkView(snapshot.data![i]))).then((value) {
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
      )
    );
  }
}

/// Calculates number of weeks for a given year as per https://en.wikipedia.org/wiki/ISO_week_date#Weeks_per_year
int NumOfWeeks(int year) {
  DateTime dec28 = DateTime(year, 12, 28);
  int dayOfDec28 = int.parse(DateFormat("D").format(dec28));
  return ((dayOfDec28 - dec28.weekday + 10) / 7).floor();
}

/// Calculates week number from a date as per https://en.wikipedia.org/wiki/ISO_week_date#Calculation
int WeekNumber(DateTime date) {
  int dayOfYear = int.parse(DateFormat("D").format(date));
  int woy =  ((dayOfYear - date.weekday + 10) / 7).floor();
  if (woy < 1) {
    woy = NumOfWeeks(date.year - 1);
  } else if (woy > NumOfWeeks(date.year)) {
    woy = 1;
  }
  return woy;
}