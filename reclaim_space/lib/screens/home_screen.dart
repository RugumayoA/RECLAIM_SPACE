import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'launch_screen.dart';
import 'post_lost_screen.dart';
import 'post_found_verification_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Hello there, what do you want to do with the app?',
                style: TextStyle(color: Colors.yellowAccent, fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PostLostScreen()),
                  );
                },
                child: const Text('Post Lost'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/post-found-verification');
                    //MaterialPageRoute(builder: (_) => const PostFoundScreen()),
                  //);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Post Found'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
