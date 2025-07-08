import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostLostService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> uploadLostPost({
    required String type, // 'ID' or 'Person'
    required String? subType, // like 'National ID' or 'Employee ID'
    required String? institution, // school or org name
    required Map<String, dynamic> details, // name, age etc.
    required String imageUrl, // download url from Firebase Storage
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Add the lost post
    await _firestore.collection('lost_items').add({
      'uid': user.uid,
      'type': type,
      'subType': subType,
      'institution': institution,
      'details': details,
      'imageUrl': imageUrl,
      'matched': false,
      'matchedWith': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Create notification
    await _firestore
        .collection('notifications')
        .doc(user.uid)
        .collection('items')
        .add({
      'title': 'Post created',
      'message': 'Your lost post has been saved. We’ll notify you if we find a match!',
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
    });
  }
}
