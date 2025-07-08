import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
class SignupPasswordScreen extends StatefulWidget {
  final String email;
  final bool isPhone; // NEW

  const SignupPasswordScreen({
    super.key,
    required this.email,
    this.isPhone = false,
  });

  @override
  State<SignupPasswordScreen> createState() => _SignupPasswordScreenState();
}

class _SignupPasswordScreenState extends State<SignupPasswordScreen> {
  final TextEditingController _pass1 = TextEditingController();
  final TextEditingController _pass2 = TextEditingController();
  bool _loading = false;

  void _createAccount() async {
    final p1 = _pass1.text.trim();
    final p2 = _pass2.text.trim();

    if (p1.length < 6 || !RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(p1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters and include uppercase, lowercase, and a number')),
      );
      return;
    }

    if (p1 != p2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      User? user;
      if (widget.isPhone) {
        user = FirebaseAuth.instance.currentUser;
        await user!.updatePassword(p1);
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: widget.email,
          password: p1,
        );
        user = cred.user;
      }

      if (user != null) {
        // Save user in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': widget.email,
          'name': '', //asking for name later or in profile update screen
          'photoUrl': '',
          'role': 'user',
          'isActive': true,
          'verified': false, 
          'auth_method': widget.isPhone ? 'phone' : 'email',
          'created_at': Timestamp.now(),
          'lastLogin': Timestamp.now(),
        });

        if (mounted) {
          // Go to home screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Account creation failed')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Text(
                'Create Password',
                style: TextStyle(color: Colors.yellowAccent, fontSize: 24),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _pass1,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pass2,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _loading ? null : _createAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
