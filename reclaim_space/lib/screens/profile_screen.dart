import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'splash_screen.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tabIndex = 0;
  String? profilePicUrl;
  bool _loadingPic = false;

  @override
  void initState() {
    super.initState();
    loadProfilePic();
  }

  Future<void> loadProfilePic() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      profilePicUrl = userDoc.data()?['profilePicUrl'];
    });
  }

  Future<void> pickProfilePic() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _loadingPic = true);
      // For demo: just use local file path or bytes, in production upload to storage
      String url = picked.path;
      if (kIsWeb) {
        // On web, use bytes as a data URL
        final bytes = await picked.readAsBytes();
        url = 'data:image/png;base64,${base64Encode(bytes)}';
      }
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({'profilePicUrl': url}, SetOptions(merge: true));
      setState(() {
        profilePicUrl = url;
        _loadingPic = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickProfilePic,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundImage: profilePicUrl != null
                          ? (profilePicUrl!.startsWith('data:')
                              ? MemoryImage(base64Decode(profilePicUrl!.split(',').last))
                              : NetworkImage(profilePicUrl!) as ImageProvider)
                          : null,
                      child: _loadingPic
                          ? const CircularProgressIndicator()
                          : (profilePicUrl == null ? const Icon(Icons.person, size: 36) : null),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Edit Profile Picture'),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings & Privacy'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Post count and tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(_tabIndex == 0 ? 'lost_items' : 'found_items')
                    .where('uid', isEqualTo: uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return Text('$count Posts', style: const TextStyle(color: Colors.white, fontSize: 18));
                },
              ),
              const SizedBox(width: 24),
              ToggleButtons(
                isSelected: [_tabIndex == 0, _tabIndex == 1],
                onPressed: (i) => setState(() => _tabIndex = i),
                children: const [Text('Lost'), Text('Found')],
                color: Colors.white,
                selectedColor: Colors.yellow,
                fillColor: Colors.black54,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(_tabIndex == 0 ? 'lost_items' : 'found_items')
                  .where('uid', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No posts yet.', style: TextStyle(color: Colors.white70)));
                }
                return ListView(
                  children: [
                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Card(
                        color: Colors.grey[900],
                        child: ListTile(
                          leading: data['imageUrl'] != null
                              ? (data['imageUrl'].toString().startsWith('http')
                                  ? Image.network(data['imageUrl'], width: 48, height: 48, fit: BoxFit.cover)
                                  : null)
                              : null,
                          title: Text(data['subType'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                          subtitle: Text(data['type'], style: const TextStyle(color: Colors.white70)),
                          trailing: data['matched'] == true
                              ? const Icon(Icons.verified, color: Colors.green)
                              : null,
                        ),
                      );
                    }),
                    const Divider(color: Colors.yellowAccent, height: 32),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('My Matches', style: TextStyle(color: Colors.yellowAccent, fontSize: 18)),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('matches')
                          .where('lostUserId', isEqualTo: uid)
                          .snapshots(),
                      builder: (context, matchSnapshot) {
                        if (!matchSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final matches = matchSnapshot.data!.docs;
                        if (matches.isEmpty) {
                          return const Center(child: Text('No matches yet.', style: TextStyle(color: Colors.white70)));
                        }
                        return Column(
                          children: matches.map((matchDoc) {
                            final match = matchDoc.data() as Map<String, dynamic>;
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('found_items').doc(match['foundItemId']).get(),
                              builder: (context, foundSnapshot) {
                                if (!foundSnapshot.hasData) return const SizedBox.shrink();
                                final foundData = foundSnapshot.data!.data() as Map<String, dynamic>?;
                                if (foundData == null) return const SizedBox.shrink();
                                return Card(
                                  color: Colors.green[900],
                                  child: ListTile(
                                    leading: foundData['imageUrl'] != null
                                        ? (foundData['imageUrl'].toString().startsWith('http')
                                            ? Image.network(foundData['imageUrl'], width: 48, height: 48, fit: BoxFit.cover)
                                            : null)
                                        : null,
                                    title: Text(foundData['subType'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                                    subtitle: Text('Matched Found Item', style: const TextStyle(color: Colors.white70)),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
