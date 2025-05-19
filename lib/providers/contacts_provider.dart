import 'package:appwrite/appwrite.dart';
import 'package:chat/views/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/contacts_service.dart';

final contactsProvider = FutureProvider<List<UserModel>>((ref) async {
  final contactsService = ref.read(contactsServiceProvider);
  return await contactsService.fetchAllUsers();
});

final contactsServiceProvider = Provider<ContactsService>((ref) {
  // Configure the Appwrite client here
  final client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1') // Replace with your Appwrite endpoint
    ..setProject('66f81a60001e00a447db'); // Replace with your Appwrite project ID

  final databases = Databases(client);
  return ContactsService(client: client, databases: databases);
});
