import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/google_phone_screen.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<void> signInWithGoogle(BuildContext context) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          'Sign in with Google?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'ReclaimSpace wants to sign in using your Google account.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue', style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return;

    try {
      GoogleSignInAccount? googleUser;

      if (kIsWeb) {
        // 🔄 Use signInSilently on web first
        googleUser = await _googleSignIn.signInSilently();
        googleUser ??= await _googleSignIn.signIn(); // fallback if needed
      } else {
        googleUser = await _googleSignIn.signIn();
      }

      if (googleUser == null) return; // User canceled

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc = _firestore.collection('users').doc(user.uid);
        final doc = await userDoc.get();

        if (!doc.exists) {
          // New user - create user document
          await userDoc.set({
            'uid': user.uid,
            'email': user.email,
            'name': user.displayName ?? '',
            'photoUrl': user.photoURL ?? '',
            'role': 'user',
            'isActive': true,
            'verified': false,
            'authMethod': 'google',
            'createdAt': FieldValue.serverTimestamp(),
            'lastlogin': FieldValue.serverTimestamp(),
          });

          // Navigate to phone number collection screen for new users
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => GooglePhoneScreen(
                email: user.email ?? '',
                name: user.displayName ?? '',
                photoUrl: user.photoURL ?? '',
              ),
            ),
            (route) => false,
          );
        } else {
          // Existing user - update last login and go to home
          await userDoc.update({'lastlogin': FieldValue.serverTimestamp()});
          
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to sign in: $e')),
      );
    }
  }
}
