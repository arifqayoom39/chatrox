import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class ProfileView extends ConsumerStatefulWidget {
  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = ref.read(authProvider.notifier);
    final currentUser = await user.getCurrentUser();

    // Debug print for current user
    print('Current User: $currentUser');

    if (currentUser != null) {
      print('Current User ID: ${currentUser.$id}'); // Print the current user ID
      _nameController.text = currentUser.name;
      _emailController.text = currentUser.email;

      // Fetch user data from database
      final userData = await _authService.getUserDataById(currentUser.$id);
      if (userData != null) {
        print('User Data: $userData');
        // Update the UI with fetched data
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _emailController.text = userData['email'] ?? '';
        });
      } else {
        print('No data found for user ID: ${currentUser.$id}');
      }
    } else {
      print('No current user found.');
    }
  }

  Future<void> _updateProfile() async {
    final user = ref.read(authProvider.notifier);
    final currentUserId = user.state?.$id;

    // Debug print for current user ID during update
    print('Updating Profile for User ID: $currentUserId');

    if (currentUserId != null) {
      final success = await user.updatePhoneNumber(currentUserId, _emailController.text);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile')),
        );
      }
    } else {
      print('Cannot update profile: No current user ID.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
