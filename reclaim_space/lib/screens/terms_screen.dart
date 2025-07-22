import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Use'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'These are the Terms of Use for Reclaim Space.\n\n'
            '1. You agree to use this app responsibly.\n'
            '2. Do not post false or misleading information.\n'
            '3. Respect the privacy and property of others.\n'
            '4. The app is provided as-is, without warranty.\n'
            '5. For full terms, contact support.\n\n'
            'By using this app, you agree to these terms.',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      ),
    );
  }
} 