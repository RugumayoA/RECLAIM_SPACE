import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPasswordScreen extends StatefulWidget {
  final String email;

  const LoginPasswordScreen({super.key, required this.email});

  @override
  State<LoginPasswordScreen> createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends State<LoginPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscureText = true;

  void _login() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.email,
        password: password,
      );
      // Navigate to home screen
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } finally {
      setState(() => _loading = false);
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
                'Enter your password',
                style: TextStyle(color: Colors.yellowAccent, fontSize: 24),
              ),
              const SizedBox(height: 10),
              Text(
                widget.email,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() => _obscureText = !_obscureText);
                    },
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.yellowAccent),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
