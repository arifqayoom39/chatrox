class UserData {
  final String? name;
  final String phone;
  final String userId;
  final String? profilePic;
  final String? deviceToken;
  final bool? isOnline;
  final bool? isVerified;
  final String? status;
  final String? activeChat;
  final String? email;

  UserData({
      this.name,
      required this.phone,
      required this.userId,
      this.profilePic,
      this.deviceToken,
      this.isOnline,
      this.isVerified,
      this.status,
      this.activeChat,
      this.email
  });

  // to convert Document data to userdata
  factory UserData.toMap(Map<String, dynamic> map) {
    return UserData(
        phone: map["phone_no"] ?? "",
        userId: map["userId"] ?? "",
        name: map["name"] ?? "",
        deviceToken: map["device_token"] ?? "",
        isOnline: map["isOnline"] ?? false,
        profilePic: map["profile_pic"] ?? "",
        isVerified: map["isVerified"] ?? false,
        status: map["status"] ?? "",
        activeChat: map["activeChat"] ?? "",
        email: map["email"] ?? ""
    );
  }
}
