import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyC8tHxGc7fvE80mujdNe39op3D90XTpoig",
        appId: "1:944984505105:web:268419e8a9811956daaab0",
        messagingSenderId: "944984505105",
        projectId: "reclaim-space-df557",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

//apiKey: "AIzaSyC8tHxGc7fvE80mujdNe39op3D90XTpoig",
//  authDomain: "reclaim-space-df557.firebaseapp.com",
//  projectId: "reclaim-space-df557",
//  storageBucket: "reclaim-space-df557.firebasestorage.app",
//  messagingSenderId: "944984505105",
//  appId: "1:944984505105:web:268419e8a9811956daaab0",
//  measurementId: "G-S2XVCD1X0Y"
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
        // body: Center(
          // child: Text(
          //   'Reclaim Space App',
          //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          // ),
      //   ),
      // ),
    );
  }
}
