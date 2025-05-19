class UserModel {
  final String id;
  final String email;
  final String name;
  final String phoneNumber;
  final String? profilePic;
  final String? deviceToken;
  final bool isOnline;
  final bool isVerified;
  final String? status;
  final String? activeChat;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phoneNumber,
    this.profilePic,
    this.deviceToken,
    this.isOnline = false,
    this.isVerified = false,
    this.status,
    this.activeChat,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['\$id'],
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePic: map['profile_pic'],
      deviceToken: map['device_token'],
      isOnline: map['isOnline'] ?? false,
      isVerified: map['isVerified'] ?? false,
      status: map['status'],
      activeChat: map['activeChat'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '\$id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'profile_pic': profilePic,
      'device_token': deviceToken,
      'isOnline': isOnline,
      'isVerified': isVerified,
      'status': status,
      'activeChat': activeChat,
    };
  }
}
