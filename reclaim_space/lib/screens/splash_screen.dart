import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:reclaim_space/screens/login_screen.dart';
import '../widgets/auth_button.dart';
import '../screens/signup_email_screen.dart';
import '../services/auth_services.dart';

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
                        onPressed: () {
                          AuthService.signInWithGoogle(context); //will handle full sign in plus navigation
                        },
                        dark: true,
                      ),
                      AuthButton(
                        icon: Icons.email_outlined,
                        label: 'Sign up with email',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: Colors.black87,
                                title: const Text(
                                  'ReclaimSpace',
                                  style: TextStyle(
                                    color: Colors.yellowAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: const Text(
                                  'You are about to proceed with email sign-up.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(), //cancel
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(
                                        context,
                                      ).pop(); //close dialog
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SignupEmailScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Continue',
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                        },
                        child: const Text(
                          'Log in',
                          style: TextStyle(color: Colors.white, fontSize: 16),
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
