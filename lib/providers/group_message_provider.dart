import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/models/group_message_model.dart';
import 'package:chat/models/group_model.dart';

class GroupMessageProvider extends ChangeNotifier {
  List<GroupModel> _joinedGroups = [];
  Map<String, List<GroupMessageModel>>? _groupMessages = {};

  // read joined groups
  List<GroupModel> get getJoinedGroups => _joinedGroups;
  // read all group messages
  Map<String, List<GroupMessageModel>> get getGroupMessages =>
      _groupMessages ?? {};

  Timer? _debounce;

  loadAllGroupRequiredData(String userId) async {
    await loadAllGroupData(userId);
    await readAllGroupMsg();
  }

  // read all the group , the current user is joined and then update it in provider
  loadAllGroupData(String userId) async {
    final results = await readAllGroups(currentUserId: userId);
    if (results != null) {
      _joinedGroups =
          results.documents.map((e) => GroupModel.fromMap(e.data)).toList();
    }
    notifyListeners();
  }

  // read all the group messages where the user is present
  readAllGroupMsg() {
    List<String> groupIds = [];
    for (var group in _joinedGroups) {
      groupIds.add(group.groupId);
    }
    print("total groups ${groupIds.length}");
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(seconds: 1), () async {
      if (groupIds.isNotEmpty) {
        final result = await readGroupMessages(groupIds: groupIds);
        if (result != null) {
          result.forEach((key, value) {
            // sorting in descending timestamp
            value.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          });
          _groupMessages = result;
        }
        notifyListeners();
      }
    });
  }

  // add group message
  addGroupMessage({required String groupId, required GroupMessageModel msg}) {
    try {
      if (_groupMessages == null) {
        _groupMessages = {};
      }

      if (_groupMessages![groupId] == null) {
        _groupMessages![groupId] = [];
      }

      _groupMessages![groupId]!.add(msg);
      notifyListeners();
    } catch (e) {
      print("error on adding chats on provider: $e");
    }
  }

  // Add a reaction to a message
  Future<bool> addReaction({
    required String groupId,
    required String messageId,
    required String reaction,
  }) async {
    try {
      bool success = await addReactionToGroupMessage(
        messageId: messageId,
        reaction: reaction,
      );

      if (success) {
        // Update locally if backend update succeeded
        if (_groupMessages != null && _groupMessages![groupId] != null) {
          int messageIndex = _groupMessages![groupId]!
              .indexWhere((msg) => msg.messageId == messageId);

          if (messageIndex != -1) {
            _groupMessages![groupId]![messageIndex].reaction = reaction;
            notifyListeners();
          }
        }
        
        // Also force a refresh to ensure we have the latest data
        await loadAllGroupData(messageId.split("_").first);
      }

      return success;
    } catch (e) {
      print("Error adding reaction in provider: $e");
      return false;
    }
  }
}
