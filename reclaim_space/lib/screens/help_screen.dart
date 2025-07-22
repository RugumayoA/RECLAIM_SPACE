import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Frequently Asked Questions', style: TextStyle(color: Colors.yellowAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('Q: How do I post a lost or found item?\nA: Use the Home screen and select the appropriate option.', style: TextStyle(color: Colors.white70, fontSize: 16)),
              SizedBox(height: 12),
              Text('Q: How do I contact support?\nA: Email info.aits.groupg@gmail.com or call 0200905814.', style: TextStyle(color: Colors.white70, fontSize: 16)),
              SizedBox(height: 12),
              Text('Q: How do I delete my account?\nA: Go to Settings > Delete Account.', style: TextStyle(color: Colors.white70, fontSize: 16)),
              SizedBox(height: 24),
              Text('For more help, contact us at info.aits.groupg@gmail.com or call 0200905814.', style: TextStyle(color: Colors.white54, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
} 