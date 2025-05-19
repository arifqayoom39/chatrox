import 'package:chat/models/user_data.dart';

class StatusModel {
  final String statusId;
  final String userId;
  final String imageUrl;
  final String? caption;
  final DateTime timestamp;
  final List<String> viewedBy;
  UserData? userData; // For storing user details who created the status

  StatusModel({
    required this.statusId,
    required this.userId,
    required this.imageUrl,
    this.caption,
    required this.timestamp,
    required this.viewedBy,
    this.userData,
  });

  // Convert from Map (Appwrite document) to StatusModel
  factory StatusModel.fromMap(Map<String, dynamic> map) {
    // Handle viewedBy properly (could be List<dynamic> from Appwrite)
    List<String> processedViewedBy = [];
    if (map['viewedBy'] != null) {
      if (map['viewedBy'] is List) {
        processedViewedBy = (map['viewedBy'] as List).map((item) => item.toString()).toList();
      }
    }
    
    // Extract userData if it exists
    UserData? userDataObj;
    if (map['userData'] != null && map['userData'] is List && map['userData'].isNotEmpty) {
      try {
        userDataObj = UserData.toMap(map['userData'][0]);
      } catch (e) {
        print("Error parsing user data: $e");
      }
    }
    
    return StatusModel(
      statusId: map['statusId'] ?? '',
      userId: map['userId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'],
      timestamp: DateTime.parse(map['timestamp']),
      viewedBy: processedViewedBy,
      userData: userDataObj,
    );
  }

  // Convert to Map for Appwrite database
  Map<String, dynamic> toMap() {
    return {
      'statusId': statusId,
      'userId': userId,
      'imageUrl': imageUrl,
      'caption': caption,
      'timestamp': timestamp.toIso8601String(),
      'viewedBy': viewedBy,
    };
  }

  // Check if a user has viewed this status
  bool isViewedBy(String userId) {
    return viewedBy.contains(userId);
  }
  
  // Get the number of views
  int get viewCount => viewedBy.length;
}
