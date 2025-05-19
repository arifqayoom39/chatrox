import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';

final messageServiceProvider = Provider((ref) => MessageService());

class MessageService {
  final Client _client;
  late final Databases _database;
  late final Realtime _realtime;

  static const String endpoint = 'https://cloud.appwrite.io/v1';
  static const String projectId = '66f81a60001e00a447db';
  static const String databaseId = '66f81b280024be529cdd';
  static const String messageCollectionId = '66f81f3300273d200433';

  MessageService()
      : _client = Client() {
    _client.setEndpoint(endpoint).setProject(projectId);
    _database = Databases(_client);
    _realtime = Realtime(_client);
  }

  Future<void> sendMessage({
    required String currentUserId,
    required String recipientPhoneNumber,
    required String content,
  }) async {
    try {
      print('Sending message: $content to $recipientPhoneNumber'); // Debugging
      await _database.createDocument(
        databaseId: databaseId,
        collectionId: messageCollectionId,
        documentId: ID.unique(),
        data: {
          'senderId': currentUserId,
          'recipientPhoneNumber': recipientPhoneNumber,
          'content': content,
          'timestamp': DateTime.now().toUtc().toString(),
        },
      );
      print('Message sent successfully.'); // Debugging
    } catch (e) {
      print('Error sending message: $e'); // Debugging
    }
  }

  Stream<List<MessageModel>> getRealTimeMessages(String currentUserId, String recipientPhoneNumber) {
    final subscription = _realtime.subscribe(['databases.$databaseId.collections.$messageCollectionId.documents']);

    return subscription.stream.map((event) {
      print('Received event: ${event.payload}'); // Debugging

      if (event.payload['documents'] != null) {
        return event.payload['documents']
            .where((doc) =>
                doc['recipientPhoneNumber'] == recipientPhoneNumber ||
                doc['senderId'] == currentUserId)
            .map((doc) => MessageModel.fromJson(doc))
            .toList();
      }
      return <MessageModel>[]; // Return an empty list if there are no documents
    });
  }

  Future<List<MessageModel>> getMessages(String currentUserId, String recipientPhoneNumber) async {
    final result = await _database.listDocuments(
      databaseId: databaseId,
      collectionId: messageCollectionId,
      queries: [
        Query.or([
          Query.equal('recipientPhoneNumber', recipientPhoneNumber),
          Query.equal('senderId', currentUserId),
        ]),
      ],
    );

    print('Fetched messages: ${result.documents.length}'); // Debugging
    return result.documents.map((doc) => MessageModel.fromJson(doc.data)).toList();
  }
}
