import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;
// import 'image_upload_service.dart';

class PostLostService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> uploadLostPost({
    required String type, // 'ID' or 'Person'
    required String? subType, // like 'National ID' or 'Employee ID'
    required String? institution, // school or org name
    required Map<String, dynamic> details, // name, age etc.
    required String imageUrl, // download url from imgbb
    required String imageHash, // hash of the image for matching
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
      'imageHash': imageHash,
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
      print('Checking found item: ${doc.id}');
      if (type == 'ID') {
        isMatch = (found['subType'] == subType) &&
                  (institution == null || found['institution'] == institution);
        print('ID match: subType=${found['subType']} == $subType, institution=${found['institution']} == $institution, isMatch=$isMatch');
      } else if (type == 'Person') {
        isMatch = (details['name'] != null && found['name'] == details['name']);
        print('Person match: name=${found['name']} == ${details['name']}, isMatch=$isMatch');
      }
      if (isMatch) {
        /*
        // Compare images for similarity (skipped for demo)
        try {
          final lostImageUrl = imageUrl;
          final foundImageUrl = found['imageUrl'];
          if (lostImageUrl != null && foundImageUrl != null) {
            final lostImageBytes = await http.readBytes(Uri.parse(lostImageUrl));
            final foundImageBytes = await http.readBytes(Uri.parse(foundImageUrl));
            final similarity = await ImageUploadService.compareImages(lostImageBytes, foundImageBytes);
            print('Image similarity: $similarity');
            if (similarity < 0.3) {
              print('Images not similar enough, skipping.');
              continue; // Only match if images are at least 30% similar
            }
          }
        } catch (e) {
          print('Image comparison failed: $e');
          continue;
        }
        */
        // Mark both as matched
        await lostDoc.update({'matched': true, 'matchedWith': doc.id});
        await doc.reference.update({'matched': true, 'matchedWith': lostDoc.id});
        // Create match model
        await _firestore.collection('matches').add({
          'lostItemId': lostDoc.id,
          'foundItemId': doc.id,
          'lostUserId': user.uid,
          'foundUserId': found['uid'] ?? found['userId'],
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
        await _firestore.collection('notifications').doc(found['uid'] ?? found['userId']).collection('items').add({
          'title': 'Match found!',
          'message': 'A possible match for your found item was found!',
          'timestamp': FieldValue.serverTimestamp(),
          'seen': false,
        });
        // Send SMS notifications (placeholder)
        if (found['phoneNumber'] != null) {
          await sendSMSNotification(found['phoneNumber'], 'A match for your found item was found!');
        }
        // You can also get the user's phone number from Firestore if needed
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

  static Future<void> sendSMSNotification(String phoneNumber, String message) async {
    // TODO: Integrate with Twilio or other SMS provider
    print('SMS to $phoneNumber: $message');
  }
}
