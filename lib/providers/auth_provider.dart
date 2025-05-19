import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'package:appwrite/models.dart';

final authProvider = StateNotifierProvider<AuthController, User?>((ref) {
  return AuthController(ref);
});

final currentUserProvider = FutureProvider<User?>((ref) async {
  final authController = ref.read(authProvider.notifier);
  return await authController.getCurrentUser();
});

class AuthController extends StateNotifier<User?> {
  final Ref _ref;
  final AuthService _authService;

  AuthController(this._ref) : _authService = AuthService(), super(null);

  // Signup method now returns a boolean indicating success or failure
  Future<bool> signup(String email, String password, String name) async {
    try {
      final user = await _authService.signup(email, password, name);
      if (user != null) {
        state = user;
        // Save user data to SharedPreferences
        await _authService.saveUserDataToPreferences(user);
        return true; // Indicate success
      }
      return false; // Indicate failure
    } catch (e) {
      // Handle error
      print('Signup error: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final session = await _authService.login(email, password);
      if (session != null) {
        state = await _authService.getCurrentUser();
        // Save user data to SharedPreferences
        await _authService.saveUserDataToPreferences(state);
        return true; // Indicate success
      }
      return false; // Indicate failure
    } catch (e) {
      // Handle error
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = null;
    // Clear SharedPreferences
    await _authService.clearUserDataFromPreferences();
  }

  Future<User?> getCurrentUser() async {
    try {
      return await _authService.getCurrentUser();
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  Future<bool> updatePhoneNumber(String userId, String phoneNumber) async {
    try {
      return await _authService.updatePhoneNumber(userId, phoneNumber);
    } catch (e) {
      print('Update phone number error: $e');
      return false;
    }
  }
}
