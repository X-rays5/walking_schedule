import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_material_pickers/flutter_material_pickers.dart';

import 'walk_view.dart';

class Calendar extends StatefulWidget {
  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  List<String> _locations = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
  String _selectedLocation = DateFormat.EEEE().format(DateTime.now());
  int _week = WeekNumber(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar"),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              TextButton(
                child: Text('Week $_week'),
                onPressed: (){showMaterialNumberPicker(
                  context: context,
                  title: 'Please pick a week',
                  maxNumber: NumOfWeeks(DateTime.now().year),
                  minNumber: 1,
                  selectedNumber: _week,
                  onChanged: (value) => setState(() => _week = value),
                );},
              ),
              DropdownButton<String>(
                hint: Text('Please pick a day'), // Not necessary for Option 1
                value: _selectedLocation,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLocation = newValue!;
                  });
                },
                items: _locations.map((String location) {
                  return DropdownMenuItem<String>(
                    child: new Text(location),
                    value: location,
                  );
                }).toList(),
              ),
            ],
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