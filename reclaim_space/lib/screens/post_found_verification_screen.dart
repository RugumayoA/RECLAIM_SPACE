import 'package:flutter/material.dart';

class PostFoundVerificationScreen extends StatefulWidget {
  const PostFoundVerificationScreen({super.key});

  @override
  State<PostFoundVerificationScreen> createState() => _PostFoundVerificationScreenState();
}

class _PostFoundVerificationScreenState extends State<PostFoundVerificationScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;
  bool _emailSent = false;

  Future<void> _sendVerificationPrompt() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields with a valid email')),
      );
      return;
    }

    setState(() => _loading = true);

    // Simulate email being sent
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _loading = false;
      _emailSent = true;
    });
  }

  void _onVerifiedProceed() {
    Navigator.pushNamed(context, '/country-city'); // next step screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Verify Yourself'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _emailSent
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('A verification email has been sent to your address.', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 20),
                  const Text('Was this you?', style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            foregroundColor: Colors.white70,
                          ),
                          child: const Text('No'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _onVerifiedProceed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellowAccent,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text("Yes, it's me"),
                        ),
                      )
                    ],
                  )
                ],
              )
            : Column(
                children: [
                  TextField(
                    controller: _firstNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _lastNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _loading ? null : _sendVerificationPrompt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellowAccent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text('Send Verification'),
                  ),
                ],
              ),
      ),
    );
  }
}
