import 'package:flutter/material.dart';

class WalkView extends StatelessWidget {
  final String _walkId;
  WalkView(String walkId) : _walkId = walkId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Text("Walk View"),
        ),
    );
  }
}