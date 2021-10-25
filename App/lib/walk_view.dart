import 'dart:collection';

import 'package:flutter/material.dart';

class WalkView extends StatelessWidget {
  WalkView(Map<String, dynamic> walk) : _walk = walk;

  final Map<String, dynamic> _walk;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text(_walk['name']),
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