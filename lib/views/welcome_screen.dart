import 'package:flutter/material.dart';
import 'package:chat/constants/colors.dart';

// Signal-like colors (matching email_login.dart)
const signalBlue = Color(0xFF2C6BED);
const signalLightBlue = Color(0xFF3A76F0);
const signalBackground = Colors.white;
const signalTextColor = Color(0xFF1B1B1B);
const signalSecondaryText = Color(0xFF6E6E6E);

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  void _handlePhoneNumberClick(BuildContext context) {
    // Show warning dialog
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text('Limited SMS', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: const Text(
            'Due to high volume of SMS sending, Appwrite supports only 10 messages per month. Email login is recommended.',
            style: TextStyle(fontSize: 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: signalSecondaryText),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: signalBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Proceed Anyway'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: signalBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              // App Logo - Signal-like circle with icon
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: signalBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outlined,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // App Name
              const Text(
                "Chat Messenger",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: signalTextColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Fast, simple, and secure messaging",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: signalSecondaryText,
                ),
              ),
              const Spacer(),
              // Authentication Options - simplified like Signal
              const SizedBox(height: 24),
              // Phone Authentication Button - Updated with warning
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handlePhoneNumberClick(context),
                  icon: const Icon(Icons.phone, size: 20),
                  label: const Text(
                    'Use phone number',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: signalBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Email Authentication Button
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/email_login');
                  },
                  icon: const Icon(Icons.email_outlined, size: 20),
                  label: const Text(
                    'Use email address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: signalBlue,
                    side: const BorderSide(color: signalBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Privacy focus message - Signal style
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "End-to-end encrypted. Your messages will stay private.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: signalSecondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Terms and Privacy Text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "By continuing, you agree to our Terms of Service and Privacy Policy",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: signalSecondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
