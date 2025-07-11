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
    required String imageUrl, // download url from imgbb
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Add the lost post
    final lostDoc = await _firestore.collection('lost_items').add({
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

    // Try to find a match in found_items
    final foundQuery = await _firestore.collection('found_items')
      .where('type', isEqualTo: type)
      .where('matched', isEqualTo: false)
      .get();
    for (final doc in foundQuery.docs) {
      final found = doc.data();
      bool isMatch = false;
      if (type == 'ID') {
        isMatch = (found['subType'] == subType) &&
                  (institution == null || found['institution'] == institution) &&
                  (details['name'] == null || found['details']['name'] == details['name']);
      } else if (type == 'Person') {
        isMatch = (details['name'] != null && found['details']['name'] == details['name']);
      }
      if (isMatch) {
        // Mark both as matched
        await lostDoc.update({'matched': true, 'matchedWith': doc.id});
        await doc.reference.update({'matched': true, 'matchedWith': lostDoc.id});
        // Create match model
        await _firestore.collection('matches').add({
          'lostItemId': lostDoc.id,
          'foundItemId': doc.id,
          'lostUserId': user.uid,
          'foundUserId': found['uid'],
          'matchScore': 1.0,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        // Notify both users
        await _firestore.collection('notifications').doc(user.uid).collection('items').add({
          'title': 'Match found!',
          'message': 'A possible match for your lost item was found!',
          'timestamp': FieldValue.serverTimestamp(),
          'seen': false,
        });
        await _firestore.collection('notifications').doc(found['uid']).collection('items').add({
          'title': 'Match found!',
          'message': 'A possible match for your found item was found!',
          'timestamp': FieldValue.serverTimestamp(),
          'seen': false,
        });
        break;
      }
    }

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
