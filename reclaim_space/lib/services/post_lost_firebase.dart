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

    // Create batch for efficient Firestore operations
    final batch = _firestore.batch();

    // Add the lost post
    final lostDocRef = _firestore.collection('lost_items').doc();
    batch.set(lostDocRef, {
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
    
    bool matchFound = false;
    
    for (final doc in foundQuery.docs) {
      final found = doc.data();
      bool isMatch = false;
      if (type == 'ID') {
        final foundSubType = (found['subType'] ?? '').toString().trim().toLowerCase();
        final foundInstitution = (found['institution'] ?? '').toString().trim().toLowerCase();
        final mySubType = (subType ?? '').toString().trim().toLowerCase();
        final myInstitution = (institution ?? '').toString().trim().toLowerCase();
        isMatch = (foundSubType == mySubType) &&
                  (institution == null || foundInstitution == myInstitution);
      } else if (type == 'Person') {
        final foundDetails = found['details'] ?? {};
        final foundName = (foundDetails['name'] ?? '').toString().trim().toLowerCase();
        final foundAge = (foundDetails['age'] ?? '').toString().trim();
        final foundGender = (foundDetails['gender'] ?? '').toString().trim().toLowerCase();
        final foundDescription = (foundDetails['description'] ?? '').toString().trim().toLowerCase();
        
        final myName = (details['name'] ?? '').toString().trim().toLowerCase();
        final myAge = (details['age'] ?? '').toString().trim();
        final myGender = (details['gender'] ?? '').toString().trim().toLowerCase();
        final myDescription = (details['description'] ?? '').toString().trim().toLowerCase();
        
        // Calculate match score based on multiple criteria
        int matchScore = 0;
        int totalCriteria = 0;
        
        // Name match (if both have names)
        if (myName.isNotEmpty && foundName.isNotEmpty) {
          totalCriteria++;
          if (foundName == myName) {
            matchScore++;
          }
        }
        
        // Age match
        if (myAge.isNotEmpty && foundAge.isNotEmpty) {
          totalCriteria++;
          if (foundAge == myAge) {
            matchScore++;
          }
        }
        
        // Gender match
        if (myGender.isNotEmpty && foundGender.isNotEmpty) {
          totalCriteria++;
          if (foundGender == myGender) {
            matchScore++;
          }
        }
        
        // Description similarity (basic keyword matching)
        if (myDescription.isNotEmpty && foundDescription.isNotEmpty) {
          totalCriteria++;
          final myKeywords = myDescription.split(' ').where((word) => word.length > 2).toSet();
          final foundKeywords = foundDescription.split(' ').where((word) => word.length > 2).toSet();
          final commonKeywords = myKeywords.intersection(foundKeywords);
          if (commonKeywords.length >= 1) { // At least one common keyword
            matchScore++;
          }
        }
        
        // Require at least 2 matching criteria and at least 50% match rate
        isMatch = totalCriteria >= 2 && matchScore >= (totalCriteria / 2);
      }
      if (isMatch) {
        matchFound = true;
        // Fetch both users' phone numbers from Firestore
        final foundUserId = found['uid'] ?? found['userId'];
        final lostUserId = user.uid;
        final foundUserDoc = await _firestore.collection('users').doc(foundUserId).get();
        final lostUserDoc = await _firestore.collection('users').doc(lostUserId).get();
        final foundPhone = foundUserDoc.data()?['phoneNumber'] ?? '';
        final lostPhone = lostUserDoc.data()?['phoneNumber'] ?? '';
        final foundName = foundUserDoc.data()?['name'] ?? '';
        final lostName = lostUserDoc.data()?['name'] ?? '';
        final foundEmail = foundUserDoc.data()?['email'] ?? '';
        final lostEmail = lostUserDoc.data()?['email'] ?? '';
        
        // Mark both as matched using batch
        batch.update(lostDocRef, {'matched': true, 'matchedWith': doc.id});
        batch.update(doc.reference, {'matched': true, 'matchedWith': lostDocRef.id});
        
        // Create match model
        batch.set(_firestore.collection('matches').doc(), {
          'lostItemId': lostDocRef.id,
          'foundItemId': doc.id,
          'lostUserId': lostUserId,
          'foundUserId': foundUserId,
          'matchScore': 1.0,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Notify both users in-app
        batch.set(
          _firestore.collection('notifications').doc(lostUserId).collection('items').doc(),
          {
            'title': 'Match found!',
            'message': 'A possible match for your lost item was found!',
            'timestamp': FieldValue.serverTimestamp(),
            'seen': false,
          }
        );
        batch.set(
          _firestore.collection('notifications').doc(foundUserId).collection('items').doc(),
          {
            'title': 'Match found!',
            'message': 'A possible match for your found item was found!',
            'timestamp': FieldValue.serverTimestamp(),
            'seen': false,
          }
        );
        
        // Send SMS notifications asynchronously (don't wait for them)
        if (lostPhone.isNotEmpty) {
          sendSMSNotification(lostPhone, '''ReclaimSpace:
Dear $lostName,
A matching report has been found for your lost $type .
Contact $foundName (the finder) on $foundPhone, email: $foundEmail to proceed.
Thank you for using ReclaimSpace.''');
        }
        if (foundPhone.isNotEmpty) {
          sendSMSNotification(foundPhone, '''ReclaimSpace:
Dear $foundName,
A matching report has been found for your reported $type.
Contact $lostName (the loser) on $lostPhone, email: $lostEmail to proceed.
Thank you for using ReclaimSpace.''');
        }
        break;
      }
    }
    
    // Create notification
    batch.set(
      _firestore.collection('notifications').doc(user.uid).collection('items').doc(),
      {
        'title': 'Post created',
        'message': 'Your lost post has been saved. We\'ll notify you if we find a match!',
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
      }
    );
    
    // Commit all operations at once
    await batch.commit();
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

  static Future<List<Map<String, dynamic>>> findMatches(String type, Map<String, dynamic> details) async {
    try {
      final foundItems = await FirebaseFirestore.instance
          .collection('found_items')
          .where('type', isEqualTo: type)
          .get();

      final matches = foundItems.docs.where((doc) {
        final foundDetails = doc.data()['details'] as Map<String, dynamic>;
        
        // For Person type
        if (type == 'Person') {
          // Must match exactly
          if (details['age'] != foundDetails['age'] ||
              details['gender'].toLowerCase() != foundDetails['gender'].toLowerCase()) {
            return false;
          }

          // Name match if provided
          if (details['name']?.isNotEmpty && foundDetails['name']?.isNotEmpty) {
            if (!details['name'].toLowerCase().contains(foundDetails['name'].toLowerCase()) &&
                !foundDetails['name'].toLowerCase().contains(details['name'].toLowerCase())) {
              return false;
            }
          }

          // Description keyword matching
          if (details['description']?.isNotEmpty && foundDetails['description']?.isNotEmpty) {
            final lostKeywords = details['description'].toLowerCase().split(' ');
            final foundKeywords = foundDetails['description'].toLowerCase().split(' ');
            
            final matchingKeywords = lostKeywords.where((keyword) => 
              foundKeywords.contains(keyword)).length;
            if (matchingKeywords / lostKeywords.length < 0.3) {
              return false;
            }
          }

          return true;
        }

        // For ID type
        if (type == 'ID') {
          // Must match exactly
          if (doc.data()['subType'] != details['subType']) {
            return false;
          }

          // Institution match for School/Employee IDs
          if (['School ID', 'Employee ID'].contains(details['subType'])) {
            if (details['institution']?.toLowerCase() != 
                foundDetails['institution']?.toLowerCase()) {
              return false;
            }
          }

          // Name on ID match
          if (details['name']?.isNotEmpty && foundDetails['name']?.isNotEmpty) {
            return details['name'].toLowerCase().contains(foundDetails['name'].toLowerCase()) ||
                   foundDetails['name'].toLowerCase().contains(details['name'].toLowerCase());
          }
        }

        return false;
      }).toList();

      return matches.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error finding matches: $e');
      return [];
    }
  }
}
