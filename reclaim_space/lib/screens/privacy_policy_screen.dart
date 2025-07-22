import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'Privacy Policy for Reclaim Space\n\n'
            '1. We collect only necessary information for lost and found matching.\n'
            '2. Your data is stored securely and not shared with third parties except as required by law.\n'
            '3. You can request deletion of your data at any time.\n'
            '4. For questions, contact support.\n\n'
            'By using this app, you consent to this policy.',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      ),
    );
  }
} 