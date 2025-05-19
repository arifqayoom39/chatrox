class MessageModel {
  final String senderId;
  final String recipientPhoneNumber;
  final String content;
  final String timestamp;

  MessageModel({
    required this.senderId,
    required this.recipientPhoneNumber,
    required this.content,
    required this.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      senderId: json['senderId'],
      recipientPhoneNumber: json['recipientPhoneNumber'],
      content: json['content'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'recipientPhoneNumber': recipientPhoneNumber,
      'content': content,
      'timestamp': timestamp,
    };
  }
}
