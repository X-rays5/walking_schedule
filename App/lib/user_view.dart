import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:optimized_cached_image/optimized_cached_image.dart';
import 'package:quiver/time.dart';

class UserView extends StatefulWidget {
  const UserView(String username, String photo, {Key? key}) : _username = username, _photo = photo, super(key: key);

  final String _username;
  final String _photo;

  @override
  _UserViewState createState() => _UserViewState(_username, _photo);
}

class _UserViewState extends State<UserView> {
  _UserViewState(String username, String photo) : _username = username, _photo = photo;

  final String _username;
  final String _photo;
  late DateTime _start_date;
  late DateTime _end_date;

  @override
  initState() {
    super.initState();
    DateTime date = DateTime.now();
    _start_date = DateTime(date.year, date.month, 1);
    _end_date = DateTime(date.year, date.month, daysInMonth(date.year, date.month));
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Info"),
      ),
      body: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_username),
            accountEmail: const Text(''),
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
          int.parse(DateFormat('yyyyD').format(_start_date)) > int.parse(DateFormat('yyyyD').format(_end_date)) ? const Text("invalid period") : Expanded(
              child: ListView(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                children: [
                  for (int i = 0; i < 50; i++)
                    ListTile(
                        title: Text('placeholder $i'),
                        leading: const Icon(Icons.directions_walk)
                    )
                ],
              )
          ),
        ],
      ),
    );
  }

}