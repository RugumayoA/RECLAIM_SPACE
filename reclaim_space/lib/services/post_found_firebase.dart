import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
//import 'dart:convert';
import 'egosms_config.dart';
// import 'image_upload_service.dart';

class PostLostService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> debugPrintAllFoundItems() async {
    final foundQuery = await _firestore.collection('found_items').get();
    print('--- DEBUG: All found_items in Firestore ---');
    for (final doc in foundQuery.docs) {
      print('found_item: id=${doc.id}, data=${doc.data()}');
    }
    print('--- END DEBUG ---');
  }

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

    // DEBUG: Print all found_items before matching
    await debugPrintAllFoundItems();

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
    print('Querying found_items for type: $type, matched: false');
    final foundQuery = await _firestore.collection('found_items')
      .where('type', isEqualTo: type)
      .where('matched', isEqualTo: false)
      .get();
    print('Found ${foundQuery.docs.length} found_items to check for matches');
    for (final doc in foundQuery.docs) {
      final found = doc.data();
      bool isMatch = false;
      print('Checking found item: ${doc.id}');
      if (type == 'ID') {
        final foundSubType = (found['subType'] ?? '').toString().trim().toLowerCase();
        final foundInstitution = (found['institution'] ?? '').toString().trim().toLowerCase();
        final mySubType = (subType ?? '').toString().trim().toLowerCase();
        final myInstitution = (institution ?? '').toString().trim().toLowerCase();
        print('Comparing fields:');
        print('  type: ${type.toLowerCase()} == ${found['type']?.toString().trim().toLowerCase()}');
        print('  subType: $mySubType == $foundSubType');
        print('  institution: $myInstitution == $foundInstitution');
        print('  matched: ${found['matched']}');
        isMatch = (foundSubType == mySubType) &&
                  (institution == null || foundInstitution == myInstitution);
        print('ID match: subType=$foundSubType == $mySubType, institution=$foundInstitution == $myInstitution, isMatch=$isMatch');
      } else if (type == 'Person') {
        final foundName = (found['name'] ?? '').toString().trim().toLowerCase();
        final myName = (details['name'] ?? '').toString().trim().toLowerCase();
        print('Comparing fields:');
        print('  name: $myName == $foundName');
        print('  matched: ${found['matched']}');
        isMatch = (myName.isNotEmpty && foundName == myName);
        print('Person match: name=$foundName == $myName, isMatch=$isMatch');
      }
      if (isMatch) {
        print('MATCH FOUND! Preparing to notify users and update records.');
        // Fetch both users' phone numbers from Firestore
        final foundUserId = found['uid'] ?? found['userId'];
        final lostUserId = user.uid;
        final foundUserDoc = await _firestore.collection('users').doc(foundUserId).get();
        final lostUserDoc = await _firestore.collection('users').doc(lostUserId).get();
        final foundPhone = foundUserDoc.data()?['phoneNumber'] ?? '';
        final lostPhone = lostUserDoc.data()?['phoneNumber'] ?? '';
        print('Found user phone: $foundPhone, Lost user phone: $lostPhone');
        final foundName = foundUserDoc.data()?['name'] ?? '';
        final lostName = lostUserDoc.data()?['name'] ?? '';
        final foundEmail = foundUserDoc.data()?['email'] ?? '';
        final lostEmail = lostUserDoc.data()?['email'] ?? '';
        // Compose SMS for lost user (who lost the item)
        final lostSms = '''ReclaimSpace:
Dear User,
A matching report has been found for your lost item.
Contact $foundName (the finder) on $foundPhone, email: $foundEmail to proceed.
Thank you for using ReclaimSpace.''';
        // Compose SMS for found user (who found the item)
        final foundSms = '''ReclaimSpace:
Dear User,
A matching report has been found for your found item.
Contact $lostName (the loser) on $lostPhone, email: $lostEmail to proceed.
Thank you for using ReclaimSpace.''';
        // Mark both as matched
        await lostDoc.update({'matched': true, 'matchedWith': doc.id});
        await doc.reference.update({'matched': true, 'matchedWith': lostDoc.id});
        print('Updated matched status for both lost and found items.');
        // Create match model
        await _firestore.collection('matches').add({
          'lostItemId': lostDoc.id,
          'foundItemId': doc.id,
          'lostUserId': lostUserId,
          'foundUserId': foundUserId,
          'matchScore': 1.0,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Match document created in Firestore.');
        // Notify both users in-app
        await _firestore.collection('notifications').doc(lostUserId).collection('items').add({
          'title': 'Match found!',
          'message': 'A possible match for your lost item was found!',
          'timestamp': FieldValue.serverTimestamp(),
          'seen': false,
        });
        await _firestore.collection('notifications').doc(foundUserId).collection('items').add({
          'title': 'Match found!',
          'message': 'A possible match for your found item was found!',
          'timestamp': FieldValue.serverTimestamp(),
          'seen': false,
        });
        print('In-app notifications created for both users.');
        // Send SMS notifications (placeholder)
        if (lostPhone.isNotEmpty) {
          print('Sending SMS to lost user: $lostPhone');
          await sendSMSNotification(lostPhone, lostSms);
        } else {
          print('No phone number for lost user, SMS not sent.');
        }
        if (foundPhone.isNotEmpty) {
          print('Sending SMS to found user: $foundPhone');
          await sendSMSNotification(foundPhone, foundSms);
        } else {
          print('No phone number for found user, SMS not sent.');
        }
        break;
      } else {
        print('No match for found item: ${doc.id}');
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
    print('Post created notification added for user ${user.uid}');
  }

  static Future<void> uploadFoundPost({
    required String type,
    required String? subType,
    required String? institution,
    required Map<String, dynamic> details,
    required String imageUrl,
    required String imageHash,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore.collection('found_items').add({
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

    // Optionally, add a notification or other logic here
  }

  static Future<void> sendSMSNotification(String phoneNumber, String message) async {
    final params = {
      'username': egosmsUsername,
      'password': egosmsPassword,
      'number': phoneNumber, // e.g., '+256788200915'
      'message': message,
      'sender': egosmsSenderId,
      'priority': '1', // optional, 0=highest, 4=lowest
    };
    final queryString = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final url = Uri.parse('https://www.egosms.co/api/v1/plain/?$queryString');
    try {
      final response = await http.get(url);
      print('EgoSMS response: ${response.body}');
    } catch (e) {
      print('EgoSMS error: ${e.toString()}');
    }
  }
}
