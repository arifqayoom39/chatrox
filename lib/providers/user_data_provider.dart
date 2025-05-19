import 'package:flutter/foundation.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/controllers/local_saved_data.dart';
import 'package:chat/models/user_data.dart';

class UserDataProvider extends ChangeNotifier {
  String _userId = "";
  String _userName = "";
  String _userProfilePic = "";
  String _userPhoneNumber = "";
  String _userDeviceToken = "";
  String _userEmail = ""; // Add email property

  String get getUserId => _userId;
  String get getUserName => _userName;
  String get getUserProfile => _userProfilePic;
  String get getUserNumber => _userPhoneNumber;
  String get getUserToken => _userDeviceToken;
  String get getUserEmail => _userEmail; // Add getter for email

  // to load the data from the device
  void loadDatafromLocal() {
    _userId = LocalSavedData.getUserId();
    _userPhoneNumber = LocalSavedData.getUserPhone() ?? "";
    _userName = LocalSavedData.getUserName();
    _userProfilePic = LocalSavedData.getUserProfile();
    _userEmail = LocalSavedData.getUserEmail() ?? ""; // Add email loading
    print("data loaded from local $_userId , $_userPhoneNumber, $_userName, $_userEmail");
    notifyListeners();
  }

  // to load the data from our appwrite database user collection
  void loadUserData(String userId) async {
    UserData? userData = await getUserDetails(userId: userId);
    if (userData != null) {
      _userName = userData.name ?? "";
      _userProfilePic = userData.profilePic ?? "";
      _userPhoneNumber = userData.phone ?? "";
      _userEmail = userData.email ?? "";
      notifyListeners();
    }
  }

  // set User id
  void setUserId(String id) {
    _userId = id;
    LocalSavedData.saveUserid(id);
    notifyListeners();
  }

  // set User Phone
  void setUserPhone(String phone) {
    _userPhoneNumber = phone;
    LocalSavedData.saveUserPhone(phone);
    notifyListeners();
  }

  // set user email
  void setUserEmail(String email) {
    _userEmail = email;
    LocalSavedData.saveUserEmail(email);
    notifyListeners();
  }

  // set user name
  void setUserName(String name) {
    _userName = name;
    LocalSavedData.saveUserName(name);
    notifyListeners();
  }

  // set profile pic of user
  void setProfilePic(String pic) {
    _userProfilePic = pic;
    LocalSavedData.saveUserProfile(pic);
    print("saved profile pic :$pic,");
    notifyListeners();
  }

  // set device token
  void setDeviceToken(String token) {
    _userDeviceToken = token;
    notifyListeners();
  }

  // clear add values
  void clearAllProvider() {
    _userId = "";
    _userName = "";
    _userProfilePic = "";
    _userPhoneNumber = "";
    _userDeviceToken = "";
    _userEmail = "";
    notifyListeners();
  }
}
