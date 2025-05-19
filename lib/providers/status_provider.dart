import 'package:flutter/material.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/controllers/local_saved_data.dart';
import 'package:chat/models/status_model.dart';
import 'package:chat/models/user_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatusProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<StatusModel> _userOwnStatuses = [];
  Map<String, List<StatusModel>> _contactStatuses = {};
  static const String VIEWED_STATUSES_KEY = "viewed_statuses";

  // Getters
  bool get isLoading => _isLoading;
  List<StatusModel> get userOwnStatuses => _userOwnStatuses;
  Map<String, List<StatusModel>> get contactStatuses => _contactStatuses;

  // Load user's own statuses
  Future<void> loadUserOwnStatuses(String userId, {bool notify = true}) async {
    if (notify) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _userOwnStatuses = await getUserOwnStatuses(userId: userId);
      if (notify) {
        notifyListeners();
      }
    } catch (e) {
      print("Error loading user statuses: $e");
    }

    if (notify) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load contact statuses
  Future<void> loadContactStatuses(List<String> contactIds, String currentUserId, {bool notify = true}) async {
    if (notify) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      List<StatusModel> allStatuses = await getContactStatuses(
        contactIds: contactIds,
        currentUserId: currentUserId,
      );

      // Group statuses by userId
      _contactStatuses = {};
      for (var status in allStatuses) {
        if (status.userId != currentUserId) { // Don't include current user's statuses here
          if (_contactStatuses[status.userId] == null) {
            _contactStatuses[status.userId] = [];
          }
          _contactStatuses[status.userId]!.add(status);
        }
      }
      
      if (notify) {
        notifyListeners();
      }
    } catch (e) {
      print("Error loading contact statuses: $e");
    }

    if (notify) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Initialize data without triggering UI updates during build
  Future<void> initializeData(String currentUserId, List<String> contactIds) async {
    // First load without notifying
    await loadUserOwnStatuses(currentUserId, notify: false);
    await loadContactStatuses(contactIds, currentUserId, notify: false);
    
    // Only notify once at the end
    _isLoading = false;
    notifyListeners();
  }

  // Create a new status
  Future<bool> createNewStatus(String userId, String imageUrl, String? caption) async {
    _isLoading = true;
    notifyListeners();

    bool result = await createStatus(
      userId: userId,
      imageUrl: imageUrl,
      caption: caption,
    );

    if (result) {
      await loadUserOwnStatuses(userId);
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  // Mark a status as viewed
  Future<void> viewStatus(String statusId, String userId) async {
    await markStatusAsViewed(statusId: statusId, userId: userId);
    await _saveViewedStatusLocally(statusId);
    
    // Update the status in memory too
    for (var status in _userOwnStatuses) {
      if (status.statusId == statusId && !status.viewedBy.contains(userId)) {
        status.viewedBy.add(userId);
      }
    }
    
    for (var entry in _contactStatuses.entries) {
      for (var status in entry.value) {
        if (status.statusId == statusId && !status.viewedBy.contains(userId)) {
          status.viewedBy.add(userId);
        }
      }
    }
    
    notifyListeners();
  }

  // Save viewed status ID to local storage
  Future<void> _saveViewedStatusLocally(String statusId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      Set<String> viewedIds = Set<String>.from(
        prefs.getStringList(VIEWED_STATUSES_KEY) ?? []
      );
      viewedIds.add(statusId);
      await prefs.setStringList(VIEWED_STATUSES_KEY, viewedIds.toList());
    } catch (e) {
      print("Error saving viewed status locally: $e");
    }
  }

  // Check if a status is viewed locally (to avoid network call)
  Future<bool> isStatusViewedLocally(String statusId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> viewedIds = prefs.getStringList(VIEWED_STATUSES_KEY) ?? [];
      return viewedIds.contains(statusId);
    } catch (e) {
      print("Error checking if status is viewed locally: $e");
      return false;
    }
  }

  // Delete a status
  Future<bool> removeStatus(String statusId, String userId) async {
    bool result = await deleteStatus(statusId: statusId);
    if (result) {
      await loadUserOwnStatuses(userId);
    }
    return result;
  }
}
