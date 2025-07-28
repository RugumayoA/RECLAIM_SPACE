import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class GooglePhoneScreen extends StatefulWidget {
  final String email;
  final String name;
  final String photoUrl;

  const GooglePhoneScreen({
    super.key,
    required this.email,
    required this.name,
    required this.photoUrl,
  });

  @override
  State<GooglePhoneScreen> createState() => _GooglePhoneScreenState();
}

class _GooglePhoneScreenState extends State<GooglePhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _loading = false;

  void _savePhoneNumber() async {
    final phoneInput = _phoneController.text.trim();
    String phone = phoneInput.replaceAll('+', '');
    
    // Format phone number for Uganda
    if (phone.startsWith('07')) {
      phone = '256' + phone.substring(1);
    }
    
    if (phone.isEmpty || !RegExp(r'^2567\d{8}').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Ugandan phone number (e.g. 2567XXXXXXXX)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update user document with phone number
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'phoneNumber': phone,
          'lastlogin': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to home screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving phone number: $e'),
            backgroundColor: Colors.red,
          ),
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
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Welcome!',
                style: TextStyle(
                  color: Colors.yellowAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Add your phone number',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will be used for SMS notifications when items are matched.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: '2567XXXXXXXX',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.yellowAccent),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _savePhoneNumber,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellowAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : () {
                    // Skip phone number and go to home
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 