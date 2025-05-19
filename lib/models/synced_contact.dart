class SyncedContact {
  final String name;
  final String phoneNumber;
  final String userId;
  final String? profilePic;

  SyncedContact({
    required this.name,
    required this.phoneNumber,
    required this.userId,
    this.profilePic,
  });

  factory SyncedContact.fromMap(Map<String, dynamic> map) {
    return SyncedContact(
      name: map['name'] ?? '',
      phoneNumber: map['phone_no'] ?? '',
      userId: map['userId'] ?? '',
      profilePic: map['profile_pic'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone_no': phoneNumber,
      'userId': userId,
      'profile_pic': profilePic,
    };
  }
}
