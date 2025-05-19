// views/home/recent_chats_view.dart
import 'package:flutter/material.dart';
import '../contacts/contacts_sync_view.dart';

class RecentChatsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Recent Chats Will Be Shown Here"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ContactsSyncView()),
          );
        },
        child: Icon(Icons.person_add),
        tooltip: "Sync Contacts",
      ),
    );
  }
}
