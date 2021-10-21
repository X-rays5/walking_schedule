import 'package:flutter/material.dart';

class Users extends StatelessWidget {
  const Users({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Users"),
      ),
      body: Column(
        children: [
          Expanded(
              child:
              ListView(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  children: [
                    // TODO: fetch users
                    for (int i = 0; i < 20; i++)
                      ListTile(
                        title: Text('username'),
                        subtitle: Text('Count this month: $i'),
                        leading: const Icon(Icons.account_circle),
                      ),
                  ]
              )
          )
        ],
      )
    );
  }
}

void _ReloadUsers() {

}