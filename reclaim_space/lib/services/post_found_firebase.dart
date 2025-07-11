import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostFoundService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> uploadFoundPost({
    required String type, // 'ID' or 'Person' or 'Other'
    required String? subType, // like 'National ID' or 'Employee ID'
    required String? institution, // school or org name
    required Map<String, dynamic> details, // name, description, etc.
    required String imageUrl, // download url from imgbb
    required String? location,
    required String? foundDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final foundDoc = await _firestore.collection('found_items').add({
      'uid': user.uid,
      'type': type,
      'subType': subType,
      'institution': institution,
      'details': details,
      'imageUrl': imageUrl,
      'location': location,
      'foundDate': foundDate,
      'matched': false,
      'matchedWith': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Try to find a match in lost_items
    final lostQuery = await _firestore.collection('lost_items')
      .where('type', isEqualTo: type)
      .where('matched', isEqualTo: false)
      .get();
    for (final doc in lostQuery.docs) {
      final lost = doc.data();
      bool isMatch = false;
      if (type == 'ID') {
        isMatch = (lost['subType'] == subType) &&
                  (institution == null || lost['institution'] == institution) &&
                  (details['name'] == null || lost['details']['name'] == details['name']);
      } else if (type == 'Person') {
        isMatch = (details['name'] != null && lost['details']['name'] == details['name']);
      }
      if (isMatch) {
        // Mark both as matched
        await foundDoc.update({'matched': true, 'matchedWith': doc.id});
        await doc.reference.update({'matched': true, 'matchedWith': foundDoc.id});
        // Create match model
        await _firestore.collection('matches').add({
          'lostItemId': doc.id,
          'foundItemId': foundDoc.id,
          'lostUserId': lost['uid'],
          'foundUserId': user.uid,
          'matchScore': 1.0,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        // Notify both users
        await _firestore.collection('notifications').doc(user.uid).collection('items').add({
          'title': 'Match found!',
          'message': 'A possible match for your found item was found!',
          'timestamp': FieldValue.serverTimestamp(),
          'seen': false,
        });
        await _firestore.collection('notifications').doc(lost['uid']).collection('items').add({
          'title': 'Match found!',
          'message': 'A possible match for your lost item was found!',
          'timestamp': FieldValue.serverTimestamp(),
          'seen': false,
        });
        break;
      }
    }

    await _firestore
        .collection('notifications')
        .doc(user.uid)
        .collection('items')
        .add({
      'title': 'Post created',
      'message': 'Your found post has been saved. We’ll notify you if we find a match!',
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
    });
  }
} 