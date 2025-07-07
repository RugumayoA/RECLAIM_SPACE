import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'signup_password_screen.dart';
import 'otp_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _countryCode = '+256'; // Default Uganda
  bool _loading = false;

  void _sendOTP() async {
    final phone = _countryCode + _phoneController.text.trim();

    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    setState(() => _loading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto-retrieval on Android
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Verification failed')),
        );
        setState(() => _loading = false);
      },
      codeSent: (String verificationId, int? resendToken) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPScreen(verificationId: verificationId),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Text(
                'Phone Sign-In',
                style: TextStyle(color: Colors.yellowAccent, fontSize: 24),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      controller: TextEditingController(text: _countryCode),
                      onChanged: (val) => _countryCode = val,
                      decoration: const InputDecoration(
                        labelText: 'Code',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _loading ? null : _sendOTP,
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
