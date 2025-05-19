import 'dart:convert';
import 'package:tostore/tostore.dart';
import 'package:chat/models/message_model.dart';
import 'package:chat/models/user_data.dart';

class LocalDatabaseService {
  static LocalDatabaseService? _instance;
  late ToStore _db;
  bool _isInitialized = false;

  // Singleton pattern
  static LocalDatabaseService get instance {
    _instance ??= LocalDatabaseService._internal();
    return _instance!;
  }

  LocalDatabaseService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    _db = ToStore(
      version: 1,
      schemas: [
        // Messages table schema
        const TableSchema(
          name: 'messages',
          primaryKey: 'messageId',
          fields: [
            FieldSchema(name: 'messageId', type: DataType.text, nullable: false),
            FieldSchema(name: 'message', type: DataType.text, nullable: false),
            FieldSchema(name: 'sender', type: DataType.text, nullable: false),
            FieldSchema(name: 'receiver', type: DataType.text, nullable: false),
            FieldSchema(name: 'timestamp', type: DataType.datetime, nullable: false),
            FieldSchema(name: 'isSeenByReceiver', type: DataType.boolean, nullable: false),
            FieldSchema(name: 'isImage', type: DataType.boolean),
            FieldSchema(name: 'isGroupInvite', type: DataType.boolean, nullable: false),
            FieldSchema(name: 'replyMessage', type: DataType.text),
            FieldSchema(name: 'replySender', type: DataType.text),
            FieldSchema(name: 'replyMessageId', type: DataType.text),
            FieldSchema(name: 'reaction', type: DataType.text),
            FieldSchema(name: 'isAudio', type: DataType.boolean),
            FieldSchema(name: 'isVideo', type: DataType.boolean),
            FieldSchema(name: 'userData', type: DataType.text), // Serialized JSON
          ],
          indexes: [
            IndexSchema(fields: ['sender', 'receiver']),
            IndexSchema(fields: ['timestamp']),
          ],
        ),
        // Users table schema for caching user data
        const TableSchema(
          name: 'users',
          primaryKey: 'userId',
          fields: [
            FieldSchema(name: 'userId', type: DataType.text, nullable: false),
            FieldSchema(name: 'name', type: DataType.text),
            FieldSchema(name: 'phone', type: DataType.text),
            FieldSchema(name: 'email', type: DataType.text),
            FieldSchema(name: 'profilePic', type: DataType.text),
            FieldSchema(name: 'isOnline', type: DataType.boolean),
            FieldSchema(name: 'deviceToken', type: DataType.text),
            FieldSchema(name: 'lastSeen', type: DataType.datetime),
          ],
        ),
        // Table for pending sync operations when offline
        const TableSchema(
          name: 'pending_sync',
          primaryKey: 'id',
          fields: [
            FieldSchema(name: 'id', type: DataType.text, nullable: false),
            FieldSchema(name: 'messageId', type: DataType.text, nullable: false),
            FieldSchema(name: 'action', type: DataType.text, nullable: false),
            FieldSchema(name: 'timestamp', type: DataType.datetime, nullable: false),
          ],
          indexes: [
            IndexSchema(fields: ['timestamp']),
          ],
        ),
      ],
    );

    await _db.initialize();
    _isInitialized = true;
  }

  // Save a message to local database
  Future<bool> saveMessage(MessageModel message) async {
    if (!_isInitialized) await initialize();

    try {
      // Convert userData to JSON string if it exists
      String? userDataJson;
      if (message.userData != null && message.userData!.isNotEmpty) {
        userDataJson = jsonEncode(message.userData!.map((u) => {
          'userId': u.userId,
          'name': u.name,
          'phone': u.phone,
          //'email': u.email,
          'profilePic': u.profilePic,
          'isOnline': u.isOnline,
          'deviceToken': u.deviceToken,
          //'lastSeen': u.lastSeen?.toIso8601String(),
        }).toList());
      }

      await _db.insert('messages', {
        'messageId': message.messageId,
        'message': message.message,
        'sender': message.sender,
        'receiver': message.receiver,
        'timestamp': message.timestamp,
        'isSeenByReceiver': message.isSeenByReceiver,
        'isImage': message.isImage,
        'isGroupInvite': message.isGroupInvite,
        'replyMessage': message.replyMessage,
        'replySender': message.replySender,
        'replyMessageId': message.replyMessageId,
        'reaction': message.reaction,
        'isAudio': message.isAudio,
        'isVideo': message.isVideo,
        'userData': userDataJson,
      });
      return true;
    } catch (e) {
      print('Error saving message to local DB: $e');
      return false;
    }
  }

  // Get messages between users
  Future<List<MessageModel>> getChatMessages(String currentUserId, String otherUserId) async {
    if (!_isInitialized) await initialize();

    try {
      final results = await _db.query('messages')
          .where('sender', '=', currentUserId)
          .where('receiver', '=', otherUserId)
          .or()
          .where('sender', '=', otherUserId)
          .where('receiver', '=', currentUserId)
          .orderByAsc('timestamp');

      return results.map((map) => _mapToMessageModel(map)).toList();
    } catch (e) {
      print('Error fetching messages from local DB: $e');
      return [];
    }
  }

  // Get all chats for a user
  Future<Map<String, List<MessageModel>>> getAllChats(String userId) async {
    if (!_isInitialized) await initialize();

    try {
      // Get all messages where user is either sender or receiver
      final results = await _db.query('messages')
          .where('sender', '=', userId)
          .or()
          .where('receiver', '=', userId)
          .orderByAsc('timestamp');

      // Group messages by chat partner
      Map<String, List<MessageModel>> chats = {};

      for (var map in results) {
        final message = _mapToMessageModel(map);
        
        // Determine chat partner (the other user)
        final chatPartnerId = message.sender == userId ? message.receiver : message.sender;
        
        if (!chats.containsKey(chatPartnerId)) {
          chats[chatPartnerId] = [];
        }
        
        chats[chatPartnerId]!.add(message);
      }

      return chats;
    } catch (e) {
      print('Error fetching all chats from local DB: $e');
      return {};
    }
  }

  // Update message seen status
  Future<bool> updateMessageSeen(String messageId, bool isSeen) async {
    if (!_isInitialized) await initialize();

    try {
      await _db.update('messages', {
        'isSeenByReceiver': isSeen,
      }).where('messageId', '=', messageId);
      return true;
    } catch (e) {
      print('Error updating message seen status: $e');
      return false;
    }
  }

  // Delete a message
  Future<bool> deleteMessage(String messageId) async {
    if (!_isInitialized) await initialize();

    try {
      await _db.delete('messages').where('messageId', '=', messageId);
      return true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  // Update message content (for edit)
  Future<bool> updateMessageContent(String messageId, String newContent) async {
    if (!_isInitialized) await initialize();

    try {
      await _db.update('messages', {
        'message': newContent,
      }).where('messageId', '=', messageId);
      return true;
    } catch (e) {
      print('Error updating message content: $e');
      return false;
    }
  }

  // Add reaction to message
  Future<bool> addReaction(String messageId, String reaction) async {
    if (!_isInitialized) await initialize();

    try {
      await _db.update('messages', {
        'reaction': reaction,
      }).where('messageId', '=', messageId);
      return true;
    } catch (e) {
      print('Error adding reaction: $e');
      return false;
    }
  }

  // Save user data
  Future<bool> saveUser(UserData user) async {
    if (!_isInitialized) await initialize();

    try {
      await _db.upsert('users', {
        'userId': user.userId,
        'name': user.name,
        'phone': user.phone ?? "",
        //'email': user.email,
        'profilePic': user.profilePic,
        'isOnline': user.isOnline,
        'deviceToken': user.deviceToken,
        //'lastSeen': user.lastSeen,
      });
      return true;
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }

  // Get user data
  Future<UserData?> getUser(String userId) async {
    if (!_isInitialized) await initialize();

    try {
      final results = await _db.query('users')
          .where('userId', '=', userId);

      if (results.isNotEmpty) {
        final map = results.first;
        return UserData(
          userId: map['userId'] as String,
          name: map['name'] as String?,
          phone: map['phone'] as String? ?? '',
          //email: map['email'] as String?,
          profilePic: map['profilePic'] as String?,
          isOnline: map['isOnline'] as bool?,
          deviceToken: map['deviceToken'] as String?,
          //lastSeen: map['lastSeen'] != null ? DateTime.parse(map['lastSeen'] as String) : null,
        );
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Track which messages are pending to sync with the server
  Future<void> markMessageForSync(String messageId, String syncAction) async {
    if (!_isInitialized) await initialize();

    try {
      await _db.insert('pending_sync', {
        'id': '$messageId-$syncAction',
        'messageId': messageId,
        'action': syncAction, // 'send', 'update', 'delete', 'reaction'
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      print('Error marking message for sync: $e');
    }
  }

  // Get all messages pending sync
  Future<List<Map<String, dynamic>>> getPendingSyncMessages() async {
    if (!_isInitialized) await initialize();

    try {
      final results = await _db.query('pending_sync')
          .orderByAsc('timestamp');
      return results;
    } catch (e) {
      print('Error getting pending sync messages: $e');
      return [];
    }
  }

  // Remove a message from pending sync
  Future<void> removePendingSync(String id) async {
    if (!_isInitialized) await initialize();

    try {
      await _db.delete('pending_sync').where('id', '=', id);
    } catch (e) {
      print('Error removing pending sync: $e');
    }
  }

  // Convert a database map to a MessageModel
  MessageModel _mapToMessageModel(Map<String, dynamic> map) {
    List<UserData>? userData;
    
    if (map['userData'] != null) {
      final List<dynamic> userDataList = jsonDecode(map['userData'] as String);
      userData = userDataList.map((data) => UserData(
        userId: data['userId'],
        name: data['name'],
        phone: data['phone'],
        //email: data['email'],
        profilePic: data['profilePic'],
        isOnline: data['isOnline'],
        deviceToken: data['deviceToken'],
        //lastSeen: data['lastSeen'] != null ? DateTime.parse(data['lastSeen']) : null,
      )).toList();
    }

    return MessageModel(
      messageId: map['messageId'] as String?,
      message: map['message'] as String,
      sender: map['sender'] as String,
      receiver: map['receiver'] as String,
      timestamp: map['timestamp'] as DateTime,
      isSeenByReceiver: map['isSeenByReceiver'] as bool,
      isImage: map['isImage'] as bool?,
      isGroupInvite: map['isGroupInvite'] as bool,
      replyMessage: map['replyMessage'] as String?,
      replySender: map['replySender'] as String?,
      replyMessageId: map['replyMessageId'] as String?,
      reaction: map['reaction'] as String?,
      isAudio: map['isAudio'] as bool?,
      isVideo: map['isVideo'] as bool?,
      userData: userData,
    );
  }

  // Clear all data (for testing or logout)
  Future<void> clearAllData() async {
    if (!_isInitialized) await initialize();

    try {
      await _db.delete('messages');
      await _db.delete('users');
      await _db.delete('pending_sync');
    } catch (e) {
      print('Error clearing database: $e');
    }
  }
}
