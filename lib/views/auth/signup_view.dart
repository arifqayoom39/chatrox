// views/auth/signup_view.dart
import 'package:chat/views/auth/update_phone_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_view.dart'; // Import the LoginView
 // Import the UpdatePhoneView

class SignupView extends ConsumerStatefulWidget {
  const SignupView({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends ConsumerState<SignupView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text;
                final email = _emailController.text;
                final password = _passwordController.text;

                // Attempt to sign up
                final success = await ref.read(authProvider.notifier).signup(email, password, name);
                if (success) {
                  // If signup is successful, navigate to UpdatePhoneView
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const UpdatePhoneView()),
                  );
                } else {
                  // Handle signup failure (optional: show a message)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signup failed. Please try again.')),
                  );
                }
              },
              child: const Text('Sign Up'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Navigate to the LoginView
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginView()),
                );
              },
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
