import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
//import 'dart:convert';
import 'egosms_config.dart' show egosmsUsername, egosmsPassword, egosmsSenderId;
import 'image_upload_service.dart'; // Add this import
import 'location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class PostFoundService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // Add hybrid image comparison method
  static Future<double> calculateImageSimilarity(String imageUrl1, String imageUrl2) async {
    try {
      print('🔍 Starting image similarity comparison...');
      print(' Image 1: $imageUrl1');
      print(' Image 2: $imageUrl2');
      
      return await ImageUploadService.compareImagesHybrid(imageUrl1, imageUrl2);
      
    } catch (e) {
      print('❌ Error calculating image similarity: $e');
      return 0.0;
    }
  }

  static Future<void> debugPrintAllLostItems() async {
    final lostQuery = await _firestore.collection('lost_items').get();
    print('--- DEBUG: All lost_items in Firestore ---');
    for (final doc in lostQuery.docs) {
      print('lost_item: id=${doc.id}, data=${doc.data()}');
    }
    print('--- END DEBUG ---');
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
      print('EgoSMS response:  [32m${response.body} [0m');
    } catch (e) {
      print('EgoSMS error:  [31m${e.toString()} [0m');
    }
  }

  static Future<void> uploadFoundPost({
    required String type,
    required String? subType,
    required String? institution,
    required Map<String, dynamic> details,
    required String imageUrl,
    required String imageHash,
    required BuildContext context,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    print('📤 Uploading found item with location...');

    // Get current location
    Position? position = await LocationService.getCurrentLocation(context);
    String locationName = 'Unknown Location';
    String address = 'Unknown Address';
    
    if (position != null) {
      locationName = await LocationService.getLocationName(position);
      address = await LocationService.getFullAddress(position);
      print('📍 Location data obtained: $locationName ($address)');
    } else {
      print('⚠️ Could not get location, proceeding without location data');
    }

    final batch = _firestore.batch();
    final foundDocRef = _firestore.collection('found_items').doc();
    
    Map<String, dynamic> postData = {
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
    };
    
    // Add location data if available
    if (position != null) {
      postData.addAll({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'locationName': locationName,
        'address': address,
      });
      print('📊 Location data added to post');
    }
    
    batch.set(foundDocRef, postData);
    
    await batch.commit();
    print('✅ Found item uploaded successfully with location data');

    // Try to find a match in lost_items
    final lostQuery = await _firestore.collection('lost_items')
      .where('type', isEqualTo: type)
      .where('matched', isEqualTo: false)
      .get();
    
    bool matchFound = false;
    double bestMatchScore = 0.0;
    DocumentSnapshot? bestMatch;
    
    print('🔍 Searching for matches among ${lostQuery.docs.length} lost items...');
    
    // Early termination threshold - if we find a very good match, stop searching
    const double earlyTerminationThreshold = 0.8; // 80% match score
    
    // Add timeout to prevent hanging
    final startTime = DateTime.now();
    const maxSearchTime = Duration(seconds: 15); // 15 second timeout
    
    for (final doc in lostQuery.docs) {
      // Check timeout
      if (DateTime.now().difference(startTime) > maxSearchTime) {
        print('⏰ Search timeout reached, stopping search');
        break;
      }
      
      final lost = doc.data();
      bool isMatch = false;
      double imageSimilarity = 0.0;
      
      // Quick text-based pre-filter to avoid expensive image comparison
      bool textMatch = false;
      
      if (type == 'ID') {
        final lostSubType = (lost['subType'] ?? '').toString().trim().toLowerCase();
        final lostInstitution = (lost['institution'] ?? '').toString().trim().toLowerCase();
        final mySubType = (subType ?? '').toString().trim().toLowerCase();
        final myInstitution = (institution ?? '').toString().trim().toLowerCase();
        
        textMatch = (lostSubType == mySubType) &&
                    (institution == null || lostInstitution == myInstitution);
      } else {
        // For other types, do basic text matching first
        final lostDetails = lost['details'] ?? {};
        final myDetails = details;
        
        // Simple text matching based on type
        if (type == 'Person') {
          final lostName = (lostDetails['name'] ?? '').toString().trim().toLowerCase();
          final myName = (myDetails['name'] ?? '').toString().trim().toLowerCase();
          textMatch = lostName.isNotEmpty && myName.isNotEmpty && lostName == myName;
        } else if (type == 'Electronics') {
          final lostDeviceType = (lostDetails['deviceType'] ?? '').toString().trim().toLowerCase();
          final myDeviceType = (myDetails['deviceType'] ?? '').toString().trim().toLowerCase();
          textMatch = lostDeviceType.isNotEmpty && myDeviceType.isNotEmpty && lostDeviceType == myDeviceType;
        } else {
          // For other types, assume text match to proceed with image comparison
          textMatch = true;
        }
      }
      
      // Only proceed with image comparison if text matches or for certain types
      if (textMatch || type == 'Other' || type == 'Clothing & Bags') {
        // Calculate image similarity using hybrid approach
        if (lost['imageUrl'] != null) {
          imageSimilarity = await calculateImageSimilarity(imageUrl, lost['imageUrl']);
          print('📊 Image similarity with ${doc.id}: ${(imageSimilarity * 100).toStringAsFixed(1)}%');
        }
        
        // Location is only used for SMS notifications, not for matching
        
        if (type == 'ID') {
          final lostSubType = (lost['subType'] ?? '').toString().trim().toLowerCase();
          final lostInstitution = (lost['institution'] ?? '').toString().trim().toLowerCase();
          final mySubType = (subType ?? '').toString().trim().toLowerCase();
          final myInstitution = (institution ?? '').toString().trim().toLowerCase();
          
          // Enhanced ID matching with image similarity and location
          bool textMatch = (lostSubType == mySubType) &&
                          (institution == null || lostInstitution == myInstitution);
          
          print('🆔 ID Text match: $textMatch (SubType: $mySubType == $lostSubType)');
          
          // For IDs, require both text match AND good image similarity
          isMatch = textMatch && imageSimilarity > 0.5; // 50% similarity threshold
          
          print('🆔 ID Final match: $isMatch (Image similarity: ${(imageSimilarity * 100).toStringAsFixed(1)}%)');
          
          // Calculate overall score (image similarity only)
          if (isMatch) {
            double overallScore = imageSimilarity; // Only image similarity matters for matching
            print('🎯 ID match found! Overall score: ${(overallScore * 100).toStringAsFixed(1)}%');
            
            if (overallScore > bestMatchScore) {
              bestMatchScore = overallScore;
              bestMatch = doc;
              
              // Early termination for very good matches
              if (overallScore >= earlyTerminationThreshold) {
                print('🏆 Early termination: Found excellent match (${(overallScore * 100).toStringAsFixed(1)}%)');
                break;
              }
            }
          }
          
        } else if (type == 'Person') {
          final lostDetails = lost['details'] ?? {};
          final lostName = (lostDetails['name'] ?? '').toString().trim().toLowerCase();
          final lostAge = (lostDetails['age'] ?? '').toString().trim();
          final lostGender = (lostDetails['gender'] ?? '').toString().trim().toLowerCase();
          final lostDescription = (lostDetails['description'] ?? '').toString().trim().toLowerCase();
          
          final myName = (details['name'] ?? '').toString().trim().toLowerCase();
          final myAge = (details['age'] ?? '').toString().trim();
          final myGender = (details['gender'] ?? '').toString().trim().toLowerCase();
          final myDescription = (details['description'] ?? '').toString().trim().toLowerCase();
          
          // Calculate text-based match score
          int matchScore = 0;
          int totalCriteria = 0;
          
          if (myName.isNotEmpty && lostName.isNotEmpty) {
            totalCriteria++;
            if (lostName == myName) matchScore++;
          }
          
          if (myAge.isNotEmpty && lostAge.isNotEmpty) {
            totalCriteria++;
            if (lostAge == myAge) matchScore++;
          }
          
          if (myGender.isNotEmpty && lostGender.isNotEmpty) {
            totalCriteria++;
            if (lostGender == myGender) matchScore++;
          }
          
          if (myDescription.isNotEmpty && lostDescription.isNotEmpty) {
            totalCriteria++;
            final myKeywords = myDescription.split(' ').where((word) => word.length > 2).toSet();
            final lostKeywords = lostDescription.split(' ').where((word) => word.length > 2).toSet();
            final commonKeywords = myKeywords.intersection(lostKeywords);
            if (commonKeywords.length >= 1) matchScore++;
          }
          
          bool textMatch = totalCriteria >= 2 && matchScore >= (totalCriteria / 2);
          
          print('👤 Person Text match: $textMatch (Score: $matchScore/$totalCriteria)');
          
          // For people, use both text matching AND image similarity
          isMatch = textMatch && imageSimilarity > 0.3; // 30% similarity threshold
          
          print('👤 Person Final match: $isMatch (Image similarity: ${(imageSimilarity * 100).toStringAsFixed(1)}%)');
          
          // Calculate overall match score for Person (text + image only)
          if (isMatch) {
            final textScore = totalCriteria > 0 ? matchScore / totalCriteria : 0.0;
            final overallScore = (textScore * 0.4) + (imageSimilarity * 0.6); // No location in matching
            print('🎯 Person match found! Overall score: ${(overallScore * 100).toStringAsFixed(1)}%');
            
            if (overallScore > bestMatchScore) {
              bestMatchScore = overallScore;
              bestMatch = doc;
              
              // Early termination for very good matches
              if (overallScore >= earlyTerminationThreshold) {
                print('🏆 Early termination: Found excellent match (${(overallScore * 100).toStringAsFixed(1)}%)');
                break;
              }
            }
          }
          
        } else if (type == 'Electronics') {
          final lostDetails = lost['details'] ?? {};
          final lostDeviceType = (lostDetails['deviceType'] ?? '').toString().trim().toLowerCase();
          final lostBrandModel = (lostDetails['brandModel'] ?? '').toString().trim().toLowerCase();
          final lostColor = (lostDetails['color'] ?? '').toString().trim().toLowerCase();
          final lostSerialNumber = (lostDetails['serialNumber'] ?? '').toString().trim();
          
          final myDeviceType = (details['deviceType'] ?? '').toString().trim().toLowerCase();
          final myBrandModel = (details['brandModel'] ?? '').toString().trim().toLowerCase();
          final myColor = (details['color'] ?? '').toString().trim().toLowerCase();
          final mySerialNumber = (details['serialNumber'] ?? '').toString().trim();
          
          // Calculate text-based match score
          int matchScore = 0;
          int totalCriteria = 0;
          
          if (myDeviceType.isNotEmpty && lostDeviceType.isNotEmpty) {
            totalCriteria++;
            if (lostDeviceType == myDeviceType) matchScore++;
          }
          
          if (myBrandModel.isNotEmpty && lostBrandModel.isNotEmpty) {
            totalCriteria++;
            if (lostBrandModel == myBrandModel) matchScore++;
          }
          
          if (myColor.isNotEmpty && lostColor.isNotEmpty) {
            totalCriteria++;
            if (lostColor == myColor) matchScore++;
          }
          
          if (mySerialNumber.isNotEmpty && lostSerialNumber.isNotEmpty) {
            totalCriteria++;
            if (lostSerialNumber == mySerialNumber) matchScore++;
          }
          
          bool textMatch = totalCriteria >= 2 && matchScore >= (totalCriteria / 2);
          
          print('📱 Electronics Text match: $textMatch (Score: $matchScore/$totalCriteria)');
          
          // For electronics, use both text matching AND image similarity
          isMatch = textMatch && imageSimilarity > 0.4; // 40% similarity threshold
          
          print('📱 Electronics Final match: $isMatch (Image similarity: ${(imageSimilarity * 100).toStringAsFixed(1)}%)');
          
          // Calculate overall match score for Electronics (text + image only)
          if (isMatch) {
            final textScore = totalCriteria > 0 ? matchScore / totalCriteria : 0.0;
            final overallScore = (textScore * 0.4) + (imageSimilarity * 0.6); // No location in matching
            print('🎯 Electronics match found! Overall score: ${(overallScore * 100).toStringAsFixed(1)}%');
            
            if (overallScore > bestMatchScore) {
              bestMatchScore = overallScore;
              bestMatch = doc;
              
              // Early termination for very good matches
              if (overallScore >= earlyTerminationThreshold) {
                print('🏆 Early termination: Found excellent match (${(overallScore * 100).toStringAsFixed(1)}%)');
                break;
              }
            }
          }
          
        } else if (type == 'Jewelry & Watches') {
          final lostDetails = lost['details'] ?? {};
          final lostJewelryType = (lostDetails['jewelryType'] ?? '').toString().trim().toLowerCase();
          final lostMaterial = (lostDetails['material'] ?? '').toString().trim().toLowerCase();
          final lostBrand = (lostDetails['brand'] ?? '').toString().trim().toLowerCase();
          final lostDistinctiveFeatures = (lostDetails['distinctiveFeatures'] ?? '').toString().trim().toLowerCase();
          
          final myJewelryType = (details['jewelryType'] ?? '').toString().trim().toLowerCase();
          final myMaterial = (details['material'] ?? '').toString().trim().toLowerCase();
          final myBrand = (details['brand'] ?? '').toString().trim().toLowerCase();
          final myDistinctiveFeatures = (details['distinctiveFeatures'] ?? '').toString().trim().toLowerCase();
          
          // Calculate text-based match score
          int matchScore = 0;
          int totalCriteria = 0;
          
          if (myJewelryType.isNotEmpty && lostJewelryType.isNotEmpty) {
            totalCriteria++;
            if (lostJewelryType == myJewelryType) matchScore++;
          }
          
          if (myMaterial.isNotEmpty && lostMaterial.isNotEmpty) {
            totalCriteria++;
            if (lostMaterial == myMaterial) matchScore++;
          }
          
          if (myBrand.isNotEmpty && lostBrand.isNotEmpty) {
            totalCriteria++;
            if (lostBrand == myBrand) matchScore++;
          }
          
          if (myDistinctiveFeatures.isNotEmpty && lostDistinctiveFeatures.isNotEmpty) {
            totalCriteria++;
            final myKeywords = myDistinctiveFeatures.split(' ').where((word) => word.length > 2).toSet();
            final lostKeywords = lostDistinctiveFeatures.split(' ').where((word) => word.length > 2).toSet();
            final commonKeywords = myKeywords.intersection(lostKeywords);
            if (commonKeywords.length >= 1) matchScore++;
          }
          
          bool textMatch = totalCriteria >= 2 && matchScore >= (totalCriteria / 2);
          
          print('💍 Jewelry Text match: $textMatch (Score: $matchScore/$totalCriteria)');
          
          // For jewelry, use both text matching AND image similarity
          isMatch = textMatch && imageSimilarity > 0.45; // 45% similarity threshold
          
          print('💍 Jewelry Final match: $isMatch (Image similarity: ${(imageSimilarity * 100).toStringAsFixed(1)}%)');
          
          // Calculate overall match score for Jewelry & Watches (text + image only)
          if (isMatch) {
            final textScore = totalCriteria > 0 ? matchScore / totalCriteria : 0.0;
            final overallScore = (textScore * 0.4) + (imageSimilarity * 0.6); // No location in matching
            print('🎯 Jewelry match found! Overall score: ${(overallScore * 100).toStringAsFixed(1)}%');
            
            if (overallScore > bestMatchScore) {
              bestMatchScore = overallScore;
              bestMatch = doc;
              
              // Early termination for very good matches
              if (overallScore >= earlyTerminationThreshold) {
                print('🏆 Early termination: Found excellent match (${(overallScore * 100).toStringAsFixed(1)}%)');
                break;
              }
            }
          }
          
        } else if (type == 'Clothing & Bags') {
          final lostDetails = lost['details'] ?? {};
          final lostItemType = (lostDetails['itemType'] ?? '').toString().trim().toLowerCase();
          final lostBrand = (lostDetails['brand'] ?? '').toString().trim().toLowerCase();
          final lostColor = (lostDetails['color'] ?? '').toString().trim().toLowerCase();
          final lostSize = (lostDetails['size'] ?? '').toString().trim().toLowerCase();
          final lostDistinctiveFeatures = (lostDetails['distinctiveFeatures'] ?? '').toString().trim().toLowerCase();
          
          final myItemType = (details['itemType'] ?? '').toString().trim().toLowerCase();
          final myBrand = (details['brand'] ?? '').toString().trim().toLowerCase();
          final myColor = (details['color'] ?? '').toString().trim().toLowerCase();
          final mySize = (details['size'] ?? '').toString().trim().toLowerCase();
          final myDistinctiveFeatures = (details['distinctiveFeatures'] ?? '').toString().trim().toLowerCase();
          
          // Calculate text-based match score
          int matchScore = 0;
          int totalCriteria = 0;
          
          if (myItemType.isNotEmpty && lostItemType.isNotEmpty) {
            totalCriteria++;
            if (lostItemType == myItemType) matchScore++;
          }
          
          if (myBrand.isNotEmpty && lostBrand.isNotEmpty) {
            totalCriteria++;
            if (lostBrand == myBrand) matchScore++;
          }
          
          if (myColor.isNotEmpty && lostColor.isNotEmpty) {
            totalCriteria++;
            if (lostColor == myColor) matchScore++;
          }
          
          if (mySize.isNotEmpty && lostSize.isNotEmpty) {
            totalCriteria++;
            if (lostSize == mySize) matchScore++;
          }
          
          if (myDistinctiveFeatures.isNotEmpty && lostDistinctiveFeatures.isNotEmpty) {
            totalCriteria++;
            final myKeywords = myDistinctiveFeatures.split(' ').where((word) => word.length > 2).toSet();
            final lostKeywords = lostDistinctiveFeatures.split(' ').where((word) => word.length > 2).toSet();
            final commonKeywords = myKeywords.intersection(lostKeywords);
            if (commonKeywords.length >= 1) matchScore++;
          }
          
          bool textMatch = totalCriteria >= 2 && matchScore >= (totalCriteria / 2);
          
          print('👕 Clothing Text match: $textMatch (Score: $matchScore/$totalCriteria)');
          
          // For clothing, use both text matching AND image similarity
          isMatch = textMatch && imageSimilarity > 0.35; // 35% similarity threshold
          
          print('👕 Clothing Final match: $isMatch (Image similarity: ${(imageSimilarity * 100).toStringAsFixed(1)}%)');
          
          // Calculate overall match score for Clothing & Bags (text + image only)
          if (isMatch) {
            final textScore = totalCriteria > 0 ? matchScore / totalCriteria : 0.0;
            final overallScore = (textScore * 0.3) + (imageSimilarity * 0.7); // No location in matching
            print('🎯 Clothing match found! Overall score: ${(overallScore * 100).toStringAsFixed(1)}%');
            
            if (overallScore > bestMatchScore) {
              bestMatchScore = overallScore;
              bestMatch = doc;
              
              // Early termination for very good matches
              if (overallScore >= earlyTerminationThreshold) {
                print('🏆 Early termination: Found excellent match (${(overallScore * 100).toStringAsFixed(1)}%)');
                break;
              }
            }
          }
          
        } else if (type == 'Documents') {
          final lostDetails = lost['details'] ?? {};
          final lostDocumentType = (lostDetails['documentType'] ?? '').toString().trim().toLowerCase();
          final lostIssuingAuthority = (lostDetails['issuingAuthority'] ?? '').toString().trim().toLowerCase();
          final lostDocumentNumber = (lostDetails['documentNumber'] ?? '').toString().trim();
          final lostExpiryDate = (lostDetails['expiryDate'] ?? '').toString().trim();
          
          final myDocumentType = (details['documentType'] ?? '').toString().trim().toLowerCase();
          final myIssuingAuthority = (details['issuingAuthority'] ?? '').toString().trim().toLowerCase();
          final myDocumentNumber = (details['documentNumber'] ?? '').toString().trim();
          final myExpiryDate = (details['expiryDate'] ?? '').toString().trim();
          
          // Calculate text-based match score
          int matchScore = 0;
          int totalCriteria = 0;
          
          if (myDocumentType.isNotEmpty && lostDocumentType.isNotEmpty) {
            totalCriteria++;
            if (lostDocumentType == myDocumentType) matchScore++;
          }
          
          if (myIssuingAuthority.isNotEmpty && lostIssuingAuthority.isNotEmpty) {
            totalCriteria++;
            if (lostIssuingAuthority == myIssuingAuthority) matchScore++;
          }
          
          if (myDocumentNumber.isNotEmpty && lostDocumentNumber.isNotEmpty) {
            totalCriteria++;
            if (lostDocumentNumber == myDocumentNumber) matchScore++;
          }
          
          if (myExpiryDate.isNotEmpty && lostExpiryDate.isNotEmpty) {
            totalCriteria++;
            if (lostExpiryDate == myExpiryDate) matchScore++;
          }
          
          bool textMatch = totalCriteria >= 2 && matchScore >= (totalCriteria / 2);
          
          print('📄 Documents Text match: $textMatch (Score: $matchScore/$totalCriteria)');
          
          // For documents, require both text match AND good image similarity
          isMatch = textMatch && imageSimilarity > 0.5; // 50% similarity threshold
          
          print('📄 Documents Final match: $isMatch (Image similarity: ${(imageSimilarity * 100).toStringAsFixed(1)}%)');
          
          // Calculate overall match score for Documents (text + image only)
          if (isMatch) {
            final textScore = totalCriteria > 0 ? matchScore / totalCriteria : 0.0;
            final overallScore = (textScore * 0.5) + (imageSimilarity * 0.5); // No location in matching
            print('🎯 Documents match found! Overall score: ${(overallScore * 100).toStringAsFixed(1)}%');
            
            if (overallScore > bestMatchScore) {
              bestMatchScore = overallScore;
              bestMatch = doc;
              
              // Early termination for very good matches
              if (overallScore >= earlyTerminationThreshold) {
                print('🏆 Early termination: Found excellent match (${(overallScore * 100).toStringAsFixed(1)}%)');
                break;
              }
            }
          }
          
        } else if (type == 'Other') {
          final lostDetails = lost['details'] ?? {};
          final lostDescription = (lostDetails['description'] ?? '').toString().trim().toLowerCase();
          
          final myDescription = (details['description'] ?? '').toString().trim().toLowerCase();
          
          // For other items, rely heavily on description matching and image similarity
          bool textMatch = false;
          if (myDescription.isNotEmpty && lostDescription.isNotEmpty) {
            final myKeywords = myDescription.split(' ').where((word) => word.length > 2).toSet();
            final lostKeywords = lostDescription.split(' ').where((word) => word.length > 2).toSet();
            final commonKeywords = myKeywords.intersection(lostKeywords);
            textMatch = commonKeywords.length >= 2; // Require at least 2 common keywords
          }
          
          print('🔍 Other Text match: $textMatch');
          
          // For other items, use both text matching AND image similarity
          isMatch = textMatch && imageSimilarity > 0.4; // 40% similarity threshold
          
          print('🔍 Other Final match: $isMatch (Image similarity: ${(imageSimilarity * 100).toStringAsFixed(1)}%)');
          
          // Calculate overall match score for Other (image similarity only)
          if (isMatch) {
            final overallScore = imageSimilarity; // For Other, just use image similarity
            print('🎯 Other match found! Overall score: ${(overallScore * 100).toStringAsFixed(1)}%');
            
            if (overallScore > bestMatchScore) {
              bestMatchScore = overallScore;
              bestMatch = doc;
              
              // Early termination for very good matches
              if (overallScore >= earlyTerminationThreshold) {
                print('🏆 Early termination: Found excellent match (${(overallScore * 100).toStringAsFixed(1)}%)');
                break;
              }
            }
          }
        }
      }
    }
    
    // Process the best match if found
    if (bestMatch != null && bestMatchScore > 0.5) {
      matchFound = true;
      final lost = bestMatch.data() as Map<String, dynamic>;
      
      print('🏆 Processing best match with score: ${(bestMatchScore * 100).toStringAsFixed(1)}%');
      
      // Create a new batch for matching operations
      final matchBatch = _firestore.batch();
      
      // Fetch both users' phone numbers from Firestore
      final lostUserId = lost['uid'] ?? lost['userId'];
      final foundUserId = user.uid;
      final lostUserDoc = await _firestore.collection('users').doc(lostUserId).get();
      final foundUserDoc = await _firestore.collection('users').doc(foundUserId).get();
      final lostPhone = lostUserDoc.data()?['phoneNumber'] ?? '';
      final foundPhone = foundUserDoc.data()?['phoneNumber'] ?? '';
      final lostName = lostUserDoc.data()?['name'] ?? '';
      final foundName = foundUserDoc.data()?['name'] ?? '';
      final lostEmail = lostUserDoc.data()?['email'] ?? '';
      final foundEmail = foundUserDoc.data()?['email'] ?? '';
      
      // Mark both as matched using new batch
      matchBatch.update(foundDocRef, {'matched': true, 'matchedWith': bestMatch.id});
      matchBatch.update(bestMatch.reference, {'matched': true, 'matchedWith': foundDocRef.id});
      
      // Create match model with actual score
      matchBatch.set(_firestore.collection('matches').doc(), {
        'lostItemId': bestMatch.id,
        'foundItemId': foundDocRef.id,
        'lostUserId': lostUserId,
        'foundUserId': foundUserId,
        'matchScore': bestMatchScore, // Use calculated score
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Create in-app notifications for both users
      matchBatch.set(
        _firestore.collection('notifications').doc(lostUserId).collection('items').doc(),
        {
          'title': 'Match Found! 🎉',
          'message': 'Someone found a $type that matches what you lost!',
          'timestamp': FieldValue.serverTimestamp(),
          'seen': false,
          'type': 'match',
          'matchScore': bestMatchScore,
        }
      );
      
      matchBatch.set(
        _firestore.collection('notifications').doc(foundUserId).collection('items').doc(),
        {
          'title': 'Match Found! 🎉',
          'message': 'Someone reported losing a $type that matches what you found!',
          'timestamp': FieldValue.serverTimestamp(),
          'seen': false,
          'type': 'match',
          'matchScore': bestMatchScore,
        }
      );
      
      // Commit the match batch
      await matchBatch.commit();
      
      // Send SMS notifications (only if SMS is available)
      if (foundPhone.isNotEmpty && lostPhone.isNotEmpty) {
        print('📱 Attempting to send SMS notifications...');
        print('📞 Lost user phone: $lostPhone');
        print('📞 Found user phone: $foundPhone');
        
        try {
          // Get location information for SMS
          String lostLocation = 'Unknown location';
          String foundLocation = 'Unknown location';
          
          // Get found location (current user's location)
          if (position != null) {
            foundLocation = await LocationService.getLocationName(position);
            print('📍 Found location: $foundLocation');
          }
          
          // Get lost location (from the matched lost item)
          if (lost['locationName'] != null && lost['locationName'].isNotEmpty) {
            lostLocation = lost['locationName'];
            print('📍 Lost location from stored name: $lostLocation');
          } else if (lost['latitude'] != null && lost['longitude'] != null) {
            // Convert coordinates to location name
            Position lostPos = Position(
              latitude: lost['latitude'],
              longitude: lost['longitude'],
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
            lostLocation = await LocationService.getLocationName(lostPos);
            print('📍 Lost location from coordinates: $lostLocation');
          } else {
            print('⚠️ No location data available for lost item');
          }
          
          // SMS for lost user (who lost the item)
          final lostSms = '''ReclaimSpace:
Dear $lostName,
Someone found a $type that matches what you lost!
Contact $foundName (the finder) on $foundPhone, email: $foundEmail to proceed.
Found at: $foundLocation
Your location: $lostLocation
Match Score: ${(bestMatchScore * 100).toStringAsFixed(1)}%''';
          
          print('📤 Sending SMS to lost user: $lostPhone');
          await sendSMSNotification(lostPhone, lostSms);
          
          // SMS for found user (who found the item)
          final foundSms = '''ReclaimSpace:
Dear $foundName,
Someone reported losing a $type that matches what you found!
Contact $lostName (the owner) on $lostPhone, email: $lostEmail to proceed.
Lost at: $lostLocation
Your location: $foundLocation
Match Score: ${(bestMatchScore * 100).toStringAsFixed(1)}%''';
          
          print('📤 Sending SMS to found user: $foundPhone');
          await sendSMSNotification(foundPhone, foundSms);
          
          if (lostPhone.isNotEmpty && foundPhone.isNotEmpty) {
            print('✅ SMS notifications sent successfully');
          } else {
            print('⚠️ SMS responses indicate potential issues');
          }
        } catch (e) {
          print('❌ Error in SMS notification: $e');
        }
      } else {
        print('⚠️ Cannot send SMS: Missing phone numbers');
        print('📞 Lost user phone: $lostPhone');
        print('📞 Found user phone: $foundPhone');
      }
    }
    
    if (matchFound) {
      print('🎉 Match found and processed successfully!');
    } else {
      print('📝 No matches found for this item');
    }
  }
}
