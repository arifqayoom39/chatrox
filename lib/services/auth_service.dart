import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final Client _client;
  late final Account _account;
  late final Databases _database;

  AuthService()
      : _client = Client() {
    _client
        .setEndpoint('https://cloud.appwrite.io/v1')
        .setProject('66f81a60001e00a447db'); // Ensure this is your actual project ID
    _account = Account(_client);
    _database = Databases(_client);
  }

  Future<models.User?> signup(String email, String password, String name) async {
    try {
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
      );

      await _database.createDocument(
        databaseId: '66f81b280024be529cdd', // Use your actual Database ID
        collectionId: '66f81e9b0025cc17e32f', // Use your actual Collection ID
        documentId: user.$id,
        data: {
          'email': email,
          'name': name,
          'phoneNumber': '',
          'id': user.$id,
        },
      );

      // Automatically log in the user after signup
      await createEmailPasswordSession(email, password);
      
      return user;
    } catch (e) {
      print('Signup Error: $e');
      return null;
    }
  }

  Future<models.Session?> login(String email, String password) async {
    try {
      return await createEmailPasswordSession(email, password);
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  Future<models.Session?> createEmailPasswordSession(String email, String password) async {
    try {
      final session = await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      return session;
    } catch (e) {
      print('Session Creation Error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
      await clearUserDataFromPreferences(); // Clear user data on logout
    } catch (e) {
      print('Logout Error: $e');
    }
  }

  Future<models.User?> getCurrentUser() async {
    try {
      if (await hasValidSession()) {
        return await _account.get();
      } else {
        print('No valid session found.');
        return null;
      }
    } catch (e) {
      print('Get User Error: $e');
      return null;
    }
  }

  Future<bool> hasValidSession() async {
    try {
      final session = await _account.getSession(sessionId: 'current');
      return session != null; // Session exists
    } catch (e) {
      print('Session Check Error: $e');
      return false; // No valid session
    }
  }

  Future<bool> updatePhoneNumber(String userId, String phoneNumber) async {
    try {
      await _database.updateDocument(
        databaseId: '66f81b280024be529cdd',
        collectionId: '66f81e9b0025cc17e32f',
        documentId: userId,
        data: {'phoneNumber': phoneNumber},
      );
      return true;
    } catch (e) {
      print('Update Phone Number Error: $e');
      return false;
    }
  }

  Future<void> saveUserDataToPreferences(models.User? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user != null) {
      await prefs.setString('userId', user.$id);
      await prefs.setString('email', user.email);
      await prefs.setString('name', user.name);
    }
  }

  Future<void> clearUserDataFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('email');
    await prefs.remove('name');
  }

  // Method to fetch user data by ID
  Future<Map<String, dynamic>?> getUserDataById(String userId) async {
    try {
      final document = await _database.getDocument(
        databaseId: '66f81b280024be529cdd', // Use your actual Database ID
        collectionId: '66f81e9b0025cc17e32f', // Use your actual Collection ID
        documentId: userId,
      );
      return document.data;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Method to update user data
  Future<bool> updateUserData(String userId, String name, String email) async {
    try {
      await _database.updateDocument(
        databaseId: '66f81b280024be529cdd',
        collectionId: '66f81e9b0025cc17e32f',
        documentId: userId,
        data: {
          'name': name,
          'email': email,
        },
      );
      return true;
    } catch (e) {
      print('Update User Data Error: $e');
      return false;
    }
  }
}
