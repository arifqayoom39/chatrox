// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat/constants/colors.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/models/user_data.dart';
import 'package:chat/providers/user_data_provider.dart';

// Signal-like colors
const signalBlue = Color(0xFF2C6BED);
const signalLightBlue = Color(0xFF3A76F0);
const signalBackground = Colors.white;
const signalTextColor = Color(0xFF1B1B1B);
const signalSecondaryText = Color(0xFF6E6E6E);

class EmailLogin extends StatefulWidget {
  const EmailLogin({Key? key}) : super(key: key);

  @override
  State<EmailLogin> createState() => _EmailLoginState();
}

class _EmailLoginState extends State<EmailLogin> {
  final _formKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();
  final TextEditingController _signupNameController = TextEditingController();
  final TextEditingController _resetEmailController = TextEditingController();

  bool _isLoading = false;
  bool _showSignup = false;
  bool _showResetPassword = false;
  String _errorMessage = '';

  void _toggleSignup() {
    setState(() {
      _showSignup = !_showSignup;
      _showResetPassword = false;
      _errorMessage = '';
    });
  }

  void _toggleResetPassword() {
    setState(() {
      _showResetPassword = !_showResetPassword;
      _showSignup = false;
      _errorMessage = '';
    });
  }

  void _switchToPhoneLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final email = _emailController.text.trim();
        final loginSuccess = await loginWithEmail(
          email: email,
          password: _passwordController.text,
        );

        if (loginSuccess) {
          final userId = await getUserAccount();
          if (userId != null) {
            bool docExists = await userDocumentExists(userId: userId);
            if (!docExists) {
              await createUserDocumentIfNotExists(
                userId: userId,
                email: email,
              );
            }

            UserData? userData = await getUserDetails(userId: userId);

            Provider.of<UserDataProvider>(context, listen: false).setUserId(userId);
            Provider.of<UserDataProvider>(context, listen: false).setUserEmail(email);

            if (userData != null) {
              if (userData.name != null && userData.name!.isNotEmpty) {
                Provider.of<UserDataProvider>(context, listen: false).setUserName(userData.name!);
              }

              if (userData.profilePic != null && userData.profilePic!.isNotEmpty) {
                Provider.of<UserDataProvider>(context, listen: false).setProfilePic(userData.profilePic ?? "");
              }

              if (userData.phone != null && userData.phone.isNotEmpty) {
                Provider.of<UserDataProvider>(context, listen: false).setUserPhone(userData.phone);
              }
            }

            if (userData == null || userData.name == null || userData.name!.isEmpty) {
              Navigator.pushNamedAndRemoveUntil(
                context, "/email_update", (route) => false
              );
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context, "/home", (route) => false
              );
            }
          }
        } else {
          setState(() {
            _errorMessage = 'Invalid email or password. Please try again.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
        print('Login error: $e');
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignup() async {
    if (_signupFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final email = _signupEmailController.text.trim();
        final name = _signupNameController.text.trim();
        final password = _signupPasswordController.text;

        final userId = await createEmailAccount(
          email: email,
          password: password,
          name: name,
        );

        if (userId != "signup_error" && userId != "email_exists") {
          bool docCreated = await createUserDocumentIfNotExists(
            userId: userId,
            email: email,
            name: name,
          );

          if (!docCreated) {
            throw Exception("Failed to create user document");
          }

          Provider.of<UserDataProvider>(context, listen: false).setUserId(userId);
          Provider.of<UserDataProvider>(context, listen: false).setUserEmail(email);
          Provider.of<UserDataProvider>(context, listen: false).setUserName(name);

          Navigator.pushNamedAndRemoveUntil(
            context, "/email_update", (route) => false
          );
        } else if (userId == "email_exists") {
          setState(() {
            _errorMessage = 'Email already exists. Please use a different email or login.';
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to create account. Please try again.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
        print('Signup error: $e');
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleResetPassword() async {
    if (_resetFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final success = await resetPassword(
          email: _resetEmailController.text.trim(),
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset email sent. Check your inbox.'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _showResetPassword = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to send reset email. Please try again.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
        });
        print('Reset password error: $e');
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: signalBackground,
      appBar: AppBar(
        backgroundColor: signalBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: signalTextColor),
        centerTitle: true,
        title: Text(
          _showSignup ? 'Create account' : (_showResetPassword ? 'Reset password' : 'Sign in'),
          style: const TextStyle(
            color: signalTextColor, 
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _isLoading 
              ? const CircularProgressIndicator(color: signalBlue)
              : _showSignup 
                ? _buildSignupForm() 
                : (_showResetPassword ? _buildResetPasswordForm() : _buildLoginForm()),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: signalBlue,
            ),
            child: const Icon(
              Icons.lock_outline,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            "Enter your email and password",
            style: TextStyle(
              fontSize: 16,
              color: signalSecondaryText,
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (_errorMessage.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage,
              style: TextStyle(color: Colors.red.shade800, fontSize: 14),
            ),
          ),
        if (_errorMessage.isNotEmpty) const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: signalBlue, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                style: const TextStyle(fontSize: 16),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: signalBlue, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                style: const TextStyle(fontSize: 16),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _toggleResetPassword,
            style: TextButton.styleFrom(
              foregroundColor: signalBlue,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(10, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('Forgot your password?'),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: signalBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Sign in',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Don't have an account? ",
              style: TextStyle(color: signalSecondaryText),
            ),
            TextButton(
              onPressed: _toggleSignup,
              style: TextButton.styleFrom(
                foregroundColor: signalBlue,
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text("Sign up"),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _switchToPhoneLogin,
            icon: const Icon(Icons.phone),
            label: const Text('Continue with phone number'),
            style: OutlinedButton.styleFrom(
              foregroundColor: signalBlue,
              side: const BorderSide(color: signalBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            "End-to-end encrypted. Your data stays private.",
            style: TextStyle(
              fontSize: 13,
              color: signalSecondaryText,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: signalBlue,
          ),
          child: const Icon(
            Icons.person_add_outlined,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Create your account",
          style: TextStyle(
            fontSize: 16,
            color: signalSecondaryText,
          ),
        ),
        const SizedBox(height: 32),
        if (_errorMessage.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage,
              style: TextStyle(color: Colors.red.shade800, fontSize: 14),
            ),
          ),
        if (_errorMessage.isNotEmpty) const SizedBox(height: 16),
        Form(
          key: _signupFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _signupNameController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: signalBlue, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                style: const TextStyle(fontSize: 16),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _signupEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: signalBlue, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                style: const TextStyle(fontSize: 16),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _signupPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password (minimum 8 characters)',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: signalBlue, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                style: const TextStyle(fontSize: 16),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters long';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: signalBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Next',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Already have an account? ",
              style: TextStyle(color: signalSecondaryText),
            ),
            TextButton(
              onPressed: _toggleSignup,
              style: TextButton.styleFrom(
                foregroundColor: signalBlue,
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text("Sign in"),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              "By creating an account, you agree to the Terms of Service and Privacy Policy",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: signalSecondaryText,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildResetPasswordForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: signalBlue,
          ),
          child: const Icon(
            Icons.lock_reset_outlined,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Enter your email to reset your password",
          style: TextStyle(
            fontSize: 16,
            color: signalSecondaryText,
          ),
        ),
        const SizedBox(height: 32),
        if (_errorMessage.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage,
              style: TextStyle(color: Colors.red.shade800, fontSize: 14),
            ),
          ),
        if (_errorMessage.isNotEmpty) const SizedBox(height: 16),
        Form(
          key: _resetFormKey,
          child: TextFormField(
            controller: _resetEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: signalBlue, width: 2),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            style: const TextStyle(fontSize: 16),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleResetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: signalBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Send Link',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: _toggleResetPassword,
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to Sign in'),
          style: TextButton.styleFrom(
            foregroundColor: signalBlue,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
