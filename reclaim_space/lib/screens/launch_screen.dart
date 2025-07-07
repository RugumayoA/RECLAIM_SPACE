import 'package:flutter/material.dart';
import 'splash_screen.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();

    // Wait for 2 seconds, then go to SplashScreen
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Center(
            child: Image.asset(
              'assets/images/app_logo.png',
              width: 120,
              height: 120,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'ReclaimSpace',
            style: TextStyle(
              color: Colors.yellowAccent,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'from Group6',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}
