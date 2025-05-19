import 'package:chat/models/user_data.dart';

class GroupMessageModel {
  String messageId;
  String groupId;
  String message;
  String senderId;
  DateTime timestamp;
  bool? isImage;
  bool? isAudio;
  bool? isVideo;
  String? replyMessage;
  String? replySender;
  String? replyMessageId;
  String? reaction;
  List<UserData> userData;

  GroupMessageModel({
    required this.messageId,
    required this.groupId,
    required this.message,
    required this.senderId,
    required this.timestamp,
    this.isImage,
    this.isAudio,
    this.isVideo,
    this.replyMessage,
    this.replySender,
    this.replyMessageId,
    this.reaction,
    required this.userData,
  });

  // factory function to convert json to Group Message Model
  factory GroupMessageModel.fromMap(Map<String, dynamic> map) {
    return GroupMessageModel(
      messageId: map["\$id"],
      groupId: map["groupId"],
      message: map["message"],
      senderId: map["senderId"],
      isImage: map["isImage"] ?? false,
      isAudio: map["isAudio"] ?? false,
      isVideo: map["isVideo"] ?? false,
      replyMessage: map["replyMessage"],
      replySender: map["replySender"],
      replyMessageId: map["replyMessageId"],
      reaction: map["reaction"],
      timestamp: DateTime.parse(map["timestamp"] ?? "2024-01-01"),
      userData: List<UserData>.from(map["userData"].map((e) => UserData.toMap(e)) ?? []),
    );
  }
}
