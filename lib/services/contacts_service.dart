import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:chat/views/models/user_model.dart';


class ContactsService {
  final Client client;
  final Databases databases;

  ContactsService({required this.client, required this.databases});

  Future<List<UserModel>> fetchAllUsers() async {
    try {
      final result = await databases.listDocuments(
        databaseId: '66f81b280024be529cdd', // Replace with your database ID
        collectionId: '66f81e9b0025cc17e32f', // Replace with your collection ID
      );
      
      List<UserModel> users = result.documents.map((doc) {
        return UserModel.fromMap(doc.data);
      }).toList();
      
      return users;
    } catch (e) {
      print('Error fetching users: $e');
      rethrow;
    }
  }
}
