import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

// Provider to get messages based on user IDs
final messagesProvider = StreamProvider.family<List<MessageModel>, MessageQuery>((ref, messageQuery) {
  return ref.read(messageServiceProvider).getRealTimeMessages(messageQuery.currentUserId, messageQuery.recipientPhoneNumber);
});

class MessageQuery {
  final String currentUserId;
  final String recipientPhoneNumber;

  MessageQuery(this.currentUserId, this.recipientPhoneNumber);
}
