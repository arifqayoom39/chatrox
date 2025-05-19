import 'package:chat/models/user_data.dart';

class MessageModel {
  final String message;
  final String sender; // senderId
  final String receiver; // receiverId
  final String? messageId;
  final DateTime timestamp;
  final bool isSeenByReceiver; // isSeenbyReceiver
  final bool? isImage;
  final bool isGroupInvite;
  
  // New fields
  final String? replyMessage;
  final String? replySender;
  final String? replyMessageId;
  final String? reaction;
  final bool? isAudio;
  final bool? isVideo;
  final List<UserData>? userData; // Changed from dynamic to List<UserData>

  MessageModel({
      required this.message,
      required this.sender,
      required this.receiver,
      this.messageId,
      required this.timestamp,
      required this.isSeenByReceiver,
      this.isImage,
      required this.isGroupInvite,
      this.replyMessage,
      this.replySender,
      this.replyMessageId,
      this.reaction,
      this.isAudio,
      this.isVideo,
      this.userData,
  });

  // that will convert Document model to message model
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
        message: map["message"],
        sender: map["senderId"], // Note: mapping 'senderId' to 'sender'
        receiver: map["receiverId"], // Note: mapping 'receiverId' to 'receiver'
        timestamp: DateTime.parse(map["timestamp"]),
        isSeenByReceiver: map["isSeenbyReceiver"], // Note: lowercase 'b' in API
        messageId: map["\$id"],
        isImage: map["isImage"],
        isGroupInvite: map["isGroupInvite"] ?? false,
        replyMessage: map["replyMessage"],
        replySender: map["replySender"],
        replyMessageId: map["replyMessageId"],
        reaction: map["reaction"],
        isAudio: map["isAudio"],
        isVideo: map["isVideo"],
        userData: map["userData"] != null 
            ? List<UserData>.from(map["userData"].map((e) => UserData.toMap(e)))
            : null,
    );
  }
}
