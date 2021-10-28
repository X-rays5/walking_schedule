import 'package:flutter/material.dart';

Widget BuildPopUpDialog(BuildContext context, String title, String message) {
  return AlertDialog(
    title: Text(title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(message),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Close'),
      ),
    ],
  );
}

Widget InterestedCount(Map<String, dynamic> json) {
  if (json['walker'] == 'none') {
    int count = json['interested'][0] == '' ? 0 : json['interested'].length;
    return Text('Interested: $count');
  } else {
    return Text('Walker: ${json['walker']}');
  }
}