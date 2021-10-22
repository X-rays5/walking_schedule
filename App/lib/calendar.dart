import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_material_pickers/flutter_material_pickers.dart';

import 'walk_view.dart';

class Calendar extends StatefulWidget {
  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime _date = DateTime.now();
  final List _days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  final List _months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar"),
      ),
      body: Column(
        children: [
         TextButton(
             onPressed: (){_DatePicker(context);},
             child: Text(_days[_date.weekday - 1]+DateFormat(' dd ').format(_date)+_months[_date.month - 1]+' '+DateFormat('yyyy').format(_date))
         ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              children: [
                // TODO: fetch walks for the day
                for (int i = 0; i < 4; i++)
                  ListTile(
                    title: Text('Ochtend'),
                    subtitle: Text('Godelief'),
                    leading: const Icon(Icons.directions_walk),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) => WalkView("id"))); // TODO: insert walk id
                    },
                  ),
              ],
            )
          ),
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