// views/auth/update_phone_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../home/home_view.dart';  // Import HomeView

class UpdatePhoneView extends ConsumerStatefulWidget {
  const UpdatePhoneView({Key? key}) : super(key: key);

  @override
  ConsumerState<UpdatePhoneView> createState() => _UpdatePhoneViewState();
}

class _UpdatePhoneViewState extends ConsumerState<UpdatePhoneView> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false; // To manage loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Phone Number'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator() // Show loading indicator while updating
                : ElevatedButton(
                    onPressed: () async {
                      if (_phoneController.text.isNotEmpty) {
                        setState(() {
                          _isLoading = true; // Start loading
                        });

                        final user = ref.read(authProvider);
                        if (user != null) {
                          final success = await ref
                              .read(authProvider.notifier)
                              .updatePhoneNumber(user.$id, _phoneController.text);

                          setState(() {
                            _isLoading = false; // Stop loading
                          });

                          if (success) {
                            // On successful update, navigate to HomeView
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => HomeView()),
                            );
                          } else {
                            // Handle failure case, show a message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to update phone number')),
                            );
                          }
                        } else {
                          setState(() {
                            _isLoading = false; // Stop loading if user is null
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User not found')),
                          );
                        }
                      } else {
                        // Show message if phone number field is empty
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a phone number')),
                        );
                      }
                    },
                    child: const Text('Update Phone Number'),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose(); // Dispose of the controller to free up resources
    super.dispose();
  }
}
