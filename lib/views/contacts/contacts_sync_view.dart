import 'package:chat/providers/auth_provider.dart';
import 'package:chat/providers/contacts_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'chat_page.dart'; // Import the ChatPage

class ContactsSyncView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsyncValue = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal[800],
        title: Text(
          'Contacts',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevation: 1,
      ),
      body: contactsAsyncValue.when(
        data: (List<UserModel> users) {
          if (users.isEmpty) {
            return Center(
              child: Text(
                'No contacts found.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            );
          }

          // Fetch the current user using AuthService
          final currentUserAsyncValue = ref.watch(currentUserProvider);

          return currentUserAsyncValue.when(
            data: (currentUser) {
              final currentUserId = currentUser?.$id ?? '';
              print('Current User ID: $currentUserId'); // Debug print for currentUserId

              if (currentUserId.isEmpty) {
                return Center(
                  child: Text('Could not fetch current user ID'),
                );
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigate to ChatPage when a user is tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            userName: user.name,
                            phoneNumber: user.phoneNumber, // Pass phoneNumber
                            currentUserId: currentUserId,   // Pass currentUserId
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            user.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${user.phoneNumber}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Divider(
                          color: Colors.grey[300],
                          height: 0.5,
                          thickness: 1,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () {
              print('Loading current user...'); // Debug print for loading state
              return Center(child: CircularProgressIndicator());
            },
            error: (err, stack) {
              print('Error fetching current user: $err'); // Debug print for error
              return Center(child: Text('Error: $err'));
            },
          );
        },
        loading: () {
          print('Loading contacts...'); // Debug print for loading state
          return Center(child: CircularProgressIndicator(color: Colors.teal[800]));
        },
        error: (err, stack) {
          print('Error fetching contacts: $err'); // Debug print for error
          return Center(child: Text('Error: $err'));
        },
      ),
      backgroundColor: Colors.white,
    );
  }
}
