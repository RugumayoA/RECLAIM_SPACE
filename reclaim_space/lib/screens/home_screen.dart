import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'launch_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LaunchScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Reclaim_Space'),
        backgroundColor: Colors.yellowAccent,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'welcome to Reclaim_Space',
          style: TextStyle(color: Colors.yellowAccent, fontSize: 24),
        ),
      ),
    );
  }
}
