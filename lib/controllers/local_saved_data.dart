import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat/models/synced_contact.dart';

class LocalSavedData {
  static late SharedPreferences _preferences;

  // initialize
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // save the userId
  static Future<void> saveUserid(String id) async {
    print("save user id to local");
    await _preferences.setString("userId", id);
  }

  // read the userId
  static String getUserId() {
    return _preferences.getString("userId") ?? "";
  }

  // save the user name
  static Future<void> saveUserName(String name) async {
    print("save user name to local: $name");

    await _preferences.setString("userName", name);
  }

  // read the user name
  static String getUserName() {
    return _preferences.getString("userName") ?? "";
  }

  // save the user phone
  static Future<void> saveUserPhone(String phone) async {
    print("save user phone number to local:$phone");

    await _preferences.setString("userPhone", phone);
  }

  // read the user phone
  static String? getUserPhone() {
    return _preferences.getString("userPhone");
  }

  // save the user email
  static Future<void> saveUserEmail(String email) async {
    print("save user email to local:$email");

    await _preferences.setString("userEmail", email);
  }

  // read the user email
  static String? getUserEmail() {
    return _preferences.getString("userEmail");
  }

  // save the user profile picture
  static Future<void> saveUserProfile(String profile) async {
    print("save user profile to local");
    await _preferences.setString("userPic", profile);
  }

  // read the user profile picture
  static String getUserProfile() {
    return _preferences.getString("userPic") ?? "";
  }

  // clear all the saved data
  static Future<void> clearAll() async {
    final bool data = await _preferences.clear();
    print("cleared all data from local :$data");
  }

  // Function to save the lastseen msg on group map to shared preferences
  static Future<void> saveLastSeenMessages(Map<String, String> lastSeenMessages) async {
    print("saving last seen");
    String jsonString = jsonEncode(lastSeenMessages);
    await _preferences.setString('lastSeenMessages', jsonString);
  }

  // Function to get the map from shared preferences
  static Future<Map<String, String>> getLastSeenMessages() async {
    print("getting last seen");
    String? jsonString = _preferences.getString('lastSeenMessages');

    if (jsonString != null) {
      Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      print("json map: $jsonMap");
      return jsonMap.map((key, value) => MapEntry(key, value as String));
    }

    return {};
  }

  // Static key for synced contacts
  static const String SYNCED_CONTACTS_KEY = "synced_contacts";
  static const String LAST_SYNC_TIME_KEY = "last_sync_time";

  // Save synced contacts to SharedPreferences
  static Future<bool> saveSyncedContacts(List<SyncedContact> contacts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> contactMaps =
          contacts.map((contact) => contact.toMap()).toList();
      String contactsJson = jsonEncode(contactMaps);
      await prefs.setString(SYNCED_CONTACTS_KEY, contactsJson);
      print("Saved ${contacts.length} synced contacts to local storage");
      return true;
    } catch (e) {
      print("Error saving synced contacts: $e");
      return false;
    }
  }

  // Get synced contacts from SharedPreferences
  static Future<List<SyncedContact>> getSyncedContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? contactsJson = prefs.getString(SYNCED_CONTACTS_KEY);

      if (contactsJson == null || contactsJson.isEmpty) {
        return [];
      }

      List<dynamic> contactMaps = jsonDecode(contactsJson);
      List<SyncedContact> contacts =
          contactMaps.map((map) => SyncedContact.fromMap(map)).toList();

      print("Retrieved ${contacts.length} synced contacts from local storage");
      return contacts;
    } catch (e) {
      print("Error getting synced contacts: $e");
      return [];
    }
  }

  // Get timestamp of last sync
  static Future<String> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(LAST_SYNC_TIME_KEY) ?? '';
  }

  // Save timestamp of last sync
  static Future<void> saveLastSyncTime(String timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LAST_SYNC_TIME_KEY, timestamp);
  }

  // Static key for viewed statuses
  static const String VIEWED_STATUSES_KEY = "viewed_statuses";

  // Save viewed status IDs to SharedPreferences
  static Future<bool> saveViewedStatusIds(List<String> statusIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(VIEWED_STATUSES_KEY, statusIds);
      return true;
    } catch (e) {
      print("Error saving viewed status IDs: $e");
      return false;
    }
  }

  // Add a single status ID to viewed statuses
  static Future<void> addViewedStatusId(String statusId) async {
    try {
      List<String> currentIds = _preferences.getStringList(VIEWED_STATUSES_KEY) ?? [];
      if (!currentIds.contains(statusId)) {
        currentIds.add(statusId);
        await _preferences.setStringList(VIEWED_STATUSES_KEY, currentIds);
      }
    } catch (e) {
      print("Error adding viewed status ID: $e");
    }
  }

  // Get viewed status IDs from SharedPreferences
  static Set<String> getViewedStatusIds() {
    List<String> list = _preferences.getStringList(VIEWED_STATUSES_KEY) ?? [];
    return Set<String>.from(list);
  }

  // Check if a status has been viewed locally
  static Future<bool> isStatusViewed(String statusId) async {
    try {
      List<String> viewedIds = _preferences.getStringList(VIEWED_STATUSES_KEY) ?? [];
      return viewedIds.contains(statusId);
    } catch (e) {
      print("Error checking if status is viewed: $e");
      return false;
    }
  }

  // Clean up old status IDs (older than 24 hours)
  static Future<void> cleanupOldStatusIds() async {
    // This would require storing timestamps with IDs
    // Implementation would depend on how you want to track status age
  }
}
