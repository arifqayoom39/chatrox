import 'package:chat/models/user_data.dart';

class GroupModel {
  String groupId;
  String admin;
  String groupName;
  String? groupDesc;
  bool isPublic;
  String? image;
  List<String> members;
  List<String> moderators;
  bool allowAllToSendMessages; // New field to control message permissions
  List<UserData> userData;

  GroupModel({
    required this.groupId,
    required this.admin,
    required this.groupName,
    this.groupDesc,
    required this.isPublic,
    this.image,
    required this.members,
    this.moderators = const [],
    this.allowAllToSendMessages = true, // Default to true (everyone can send)
    required this.userData,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      groupId: map["\$id"],
      admin: map["admin"],
      groupName: map["group_name"] ?? "",
      groupDesc: map["group_desc"],
      isPublic: map["isPublic"] ?? false,
      image: map["image"],
      members: List<String>.from(map["members"] ?? []),
      moderators: List<String>.from(map["moderators"] ?? []),
      allowAllToSendMessages: map["allowAllToSendMessages"] ?? true, // Default to true if not specified
      userData: List<UserData>.from(
          map["userData"]?.map((x) => UserData.toMap(x)) ?? []),
    );
  }
}
