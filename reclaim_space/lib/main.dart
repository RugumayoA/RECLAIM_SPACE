import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'screens/splash_screen.dart';
import 'screens/launch_screen.dart';
import 'screens/home_screen.dart';
import 'screens/post_found_verification_screen.dart';
import 'screens/country_city_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/terms_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/help_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_email_screen.dart';

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
      //home: LaunchScreen(),
      initialRoute: '/',
      routes: {
        '/': (context) => const LaunchScreen(),
        '/main': (context) => const MainNavScreen(),
        '/home': (context) => const HomeScreen(), //navigation to home
        '/post-found-verification': (_) => const PostFoundVerificationScreen(),
        '/country-city': (context) => const CountryCityScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/terms': (context) => const TermsScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(),
        '/help': (context) => const HelpScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup-email': (context) => const SignupEmailScreen(),
      },
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

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.yellowAccent,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
