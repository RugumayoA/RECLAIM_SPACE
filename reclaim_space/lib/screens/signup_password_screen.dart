import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
class SignupPasswordScreen extends StatefulWidget {
  final String email;
  final String name;
  final bool isPhone; 

  const SignupPasswordScreen({
    super.key,
    required this.email,
    required this.name,
    this.isPhone = false,
  });

  @override
  State<SignupPasswordScreen> createState() => _SignupPasswordScreenState();
}

class _SignupPasswordScreenState extends State<SignupPasswordScreen> {
  final TextEditingController _pass1 = TextEditingController();
  final TextEditingController _pass2 = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); 
  bool _loading = false;
  bool _obscurePass1 = true;
  bool _obscurePass2 = true;

  void _createAccount() async {
    final p1 = _pass1.text.trim();
    final p2 = _pass2.text.trim();
    final phoneInput = _phoneController.text.trim();
    String phone = phoneInput.replaceAll('+', '');
    if (phone.startsWith('07')) {
      phone = '256' + phone.substring(1);
    }
    if (phone.isEmpty || !RegExp(r'^2567\d{8}').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Ugandan phone number (e.g. 2567XXXXXXXX)')),
      );
      return;
    }

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
        await user.updateDisplayName(widget.name);
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: widget.email,
          password: p1,
        );
        user = cred.user;
        await user?.updateDisplayName(widget.name);
      }
      await user?.reload();

      if (user != null) {
        // Save user in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': widget.email,
          'name': widget.name,
          'photoUrl': '',
          'role': 'user',
          'isActive': true,
          'verified': false, 
          'auth_method': widget.isPhone ? 'phone' : 'email',
          'created_at': Timestamp.now(),
          'lastLogin': Timestamp.now(),
          'phoneNumber': phone, // Always formatted as 2567XXXXXXX
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error: ${e.toString()}')),
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
                controller: _phoneController, // NEW
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+2567XXXXXXXX',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintStyle: TextStyle(color: Colors.white38),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pass1,
                obscureText: _obscurePass1,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass1 ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePass1 = !_obscurePass1;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pass2,
                obscureText: _obscurePass2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass2 ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePass2 = !_obscurePass2;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () {
                        _createAccount();
                      },
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
