import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'splash_screen.dart';
import 'dart:convert';
import 'post_story_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tabIndex = 0;
  String? profilePicUrl;
  String? userName;
  bool _loadingPic = false;
  bool _isSelectionMode = false;
  Set<String> _selectedPosts = {};

  @override
  void initState() {
    super.initState();
    loadProfilePic();
  }

  Future<void> loadProfilePic() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    setState(() {
      profilePicUrl = userDoc.data()?['profilePicUrl'];
      userName =
          userDoc.data()?['displayName'] ??
          FirebaseAuth.instance.currentUser?.displayName ??
          'User';
    });
  }

  Future<void> pickProfilePic() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _loadingPic = true);
      try {
        // For demo: just use local file path or bytes, in production upload to storage
        String url = picked.path;
        if (kIsWeb) {
          // On web, use bytes as a data URL
          final bytes = await picked.readAsBytes();
          url = 'data:image/png;base64,${base64Encode(bytes)}';
        }
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'profilePicUrl': url,
            'displayName': userName ?? 'User',
          }, SetOptions(merge: true));

          setState(() {
            profilePicUrl = url;
            _loadingPic = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        setState(() => _loadingPic = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating profile picture: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deletePost(
    String postId,
    String collection,
    String postType,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Delete $postType Post',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete this $postType post? This action cannot be undone.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Delete the post
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(postId)
          .delete();

      // If the post was matched, also delete the match record
      final matchQuery = await FirebaseFirestore.instance
          .collection('matches')
          .where(
            collection == 'lost_items' ? 'lostItemId' : 'foundItemId',
            isEqualTo: postId,
          )
          .get();

      if (matchQuery.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final matchDoc in matchQuery.docs) {
          batch.delete(matchDoc.reference);
        }
        await batch.commit();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$postType post deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting $postType post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSelectedPosts() async {
    if (_selectedPosts.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final collection = _tabIndex == 0 ? 'lost_items' : 'found_items';
    final postType = _tabIndex == 0 ? 'Lost' : 'Found';

    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Delete ${_selectedPosts.length} $postType Posts',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete ${_selectedPosts.length} $postType post${_selectedPosts.length == 1 ? '' : 's'}? This action cannot be undone.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Delete all selected posts
      final batch = FirebaseFirestore.instance.batch();
      for (final postId in _selectedPosts) {
        final docRef = FirebaseFirestore.instance
            .collection(collection)
            .doc(postId);
        batch.delete(docRef);
      }
      await batch.commit();

      // Delete associated match records
      final matchQuery = await FirebaseFirestore.instance
          .collection('matches')
          .where(
            collection == 'lost_items' ? 'lostItemId' : 'foundItemId',
            whereIn: _selectedPosts.toList(),
          )
          .get();

      if (matchQuery.docs.isNotEmpty) {
        final matchBatch = FirebaseFirestore.instance.batch();
        for (final matchDoc in matchQuery.docs) {
          matchBatch.delete(matchDoc.reference);
        }
        await matchBatch.commit();
        _selectedPosts.clear();
        _isSelectionMode = false;
      }
      ;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedPosts.length} $postType post${_selectedPosts.length == 1 ? '' : 's'} deleted successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting posts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting $postType posts'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedPosts.clear();
      }
    });
  }

  void _togglePostSelection(String postId) {
    setState(() {
      if (_selectedPosts.contains(postId)) {
        _selectedPosts.remove(postId);
      } else {
        _selectedPosts.add(postId);
      }
    });
  }

  void _selectAllPosts(List<QueryDocumentSnapshot> docs) {
    setState(() {
      if (_selectedPosts.length == docs.length) {
        _selectedPosts.clear();
      } else {
        _selectedPosts = docs.map((doc) => doc.id).toSet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? 'Select Posts' : 'Your Profile'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (!_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectionMode,
              tooltip: 'Select posts',
            ),
          ] else ...[
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(_tabIndex == 0 ? 'lost_items' : 'found_items')
                  .where('uid', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final allSelected =
                    _selectedPosts.length == docs.length && docs.isNotEmpty;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _selectAllPosts(docs),
                      child: Text(
                        allSelected ? 'Deselect all' : 'Select all',
                        style: const TextStyle(color: Colors.yellowAccent),
                      ),
                    ),
                    if (_selectedPosts.isNotEmpty)
                      TextButton(
                        onPressed: _deleteSelectedPosts,
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _toggleSelectionMode,
                      tooltip: 'Cancel selection',
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.grey[900]),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: pickProfilePic,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 34, // reduced from 40
                            backgroundImage: profilePicUrl != null
                                ? (profilePicUrl!.startsWith('data:')
                                      ? MemoryImage(
                                          base64Decode(
                                            profilePicUrl!.split(',').last,
                                          ),
                                        )
                                      : NetworkImage(profilePicUrl!)
                                            as ImageProvider)
                                : null,
                            child: _loadingPic
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : (profilePicUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 34,
                                          color: Colors.white,
                                        )
                                      : null),
                          ),
                          if (!_loadingPic)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.yellowAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14, // reduced from 16
                                  color: Colors.black,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8), // reduced from 12
                    Text(
                      FirebaseAuth.instance.currentUser?.displayName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16, // reduced from 18
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2), // reduced from 4
                    Text(
                      'Tap to change photo',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11, // reduced from 12
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings & Privacy'),
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help / FAQ'),
              onTap: () {
                Navigator.pushNamed(context, '/help');
              },
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
                  final count = snapshot.hasData
                      ? snapshot.data!.docs.length
                      : 0;
                  return Text(
                    '$count Posts',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  );
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
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No posts yet.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                return GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 1, // reduced from 4
                        mainAxisSpacing: 1, // reduced from 4
                        childAspectRatio: 0.8, // slightly taller for IG style
                      ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isSelected = _selectedPosts.contains(doc.id);
                    final isMatched = data['matched'] == true;
                    return GestureDetector(
                      onTap: () {
                        if (_isSelectionMode) {
                          _togglePostSelection(doc.id);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostStoryScreen(
                                postId: doc.id,
                                collection: _tabIndex == 0
                                    ? 'lost_items'
                                    : 'found_items',
                                postType: _tabIndex == 0
                                    ? 'Lost'
                                    : 'Found',
                              ),
                            ),
                          );
                        }
                      },
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          _toggleSelectionMode();
                          _togglePostSelection(doc.id);
                        }
                      },
                      child: Card(
                        color: isSelected
                            ? Colors.yellowAccent.withAlpha(136)
                            : Colors.grey[900],
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child:
                                  data['imageUrl'] != null &&
                                      data['imageUrl']
                                          .toString()
                                          .startsWith('http')
                                  ? Image.network(
                                      data['imageUrl'],
                                      fit: BoxFit.cover,
                                    )
                                  : Container(color: Colors.black12),
                            ),
                            if (isMatched)
                              const Positioned(
                                bottom: 6, // moved from top: 6
                                right: 6,
                                child: Icon(
                                  Icons.verified,
                                  color: Colors.green,
                                  size: 24,
                                ),
                              ),
                            if (_isSelectionMode)
                              Align(
                                alignment: Alignment.topLeft,
                                child: Checkbox(
                                  value: isSelected,
                                  onChanged: (value) =>
                                      _togglePostSelection(doc.id),
                                  activeColor: Colors.yellowAccent,
                                ),
                              ),
                            Align(
                              alignment: Alignment.topRight,
                              child: PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white70,
                                ),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deletePost(
                                      doc.id,
                                      _tabIndex == 0
                                          ? 'lost_items'
                                          : 'found_items',
                                      _tabIndex == 0 ? 'Lost' : 'Found',
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Delete Post'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
