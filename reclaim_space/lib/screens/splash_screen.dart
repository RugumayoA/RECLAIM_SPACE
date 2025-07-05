import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import '../widgets/auth_button.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final List<Color> backgroundColors = [
    Colors.green.shade900,
    Colors.blue.shade800,
    Colors.deepPurple.shade700,
    Colors.black,
  ];

  final List<String> animatedWords = [
    'Welcome to',
    'Reclaim_Space',
    'let’s go find it',
    'let’s collaborate',
  ];

  int _bgColorIndex = 0;

  @override
  void initState() {
    super.initState();

    // Change background every 4 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return false;
      setState(() {
        _bgColorIndex = (_bgColorIndex + 1) % backgroundColors.length;
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated top background
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            color: backgroundColors[_bgColorIndex],
            height: screenSize.height * 0.65,
            width: double.infinity,
            child: Center(
              child: AnimatedTextKit(
                animatedTexts: animatedWords.map((word) {
                  return TypewriterAnimatedText(
                    word,
                    textStyle: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellowAccent,
                    ),
                    speed: const Duration(milliseconds: 100),
                  );
                }).toList(),
                isRepeatingAnimation: true,
                repeatForever: true,
                pause: const Duration(milliseconds: 1000),
              ),
            ),
          ),

          // Static Auth Bottom Section
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: screenSize.height * 0.40,
              padding: const EdgeInsets.only(top: 20, bottom: 30),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SafeArea(
                top: false, // only care about bottom
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AuthButton(
                        icon: Icons.apple,
                        label: 'Continue with Apple',
                        onPressed: () {},
                      ),
                      AuthButton(
                        icon: Icons.g_mobiledata,
                        label: 'Continue with Google',
                        onPressed: () {},
                        dark: true,
                      ),
                      AuthButton(
                        icon: Icons.email_outlined,
                        label: 'Sign up with email',
                        onPressed: () {},
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
