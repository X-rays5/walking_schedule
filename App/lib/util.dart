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

String InterestedCount(Map<String, dynamic> json) {
  if (json['walker'] == 'none') {
    Map<String, dynamic> interested = json['interested'];
    int count = interested.length == 1 ? 0 : interested.length - 1; // theres always a placeholder to ensure no exceptions
    return 'Interested: $count';
  } else {
    return 'Walker: ${json['walker']}';
  }
}