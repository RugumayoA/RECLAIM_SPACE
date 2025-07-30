import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
//import 'dart:convert';
import 'egosms_config.dart' show egosmsUsername, egosmsPassword, egosmsSenderId;
import 'image_upload_service.dart'; // Add this import
import 'location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class PostLostService {
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

  static Future<void> debugPrintAllFoundItems() async {
    final foundQuery = await _firestore.collection('found_items').get();
    print('--- DEBUG: All found_items in Firestore ---');
    for (final doc in foundQuery.docs) {
      print('found_item: id=${doc.id}, data=${doc.data()}');
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

  static Future<void> uploadLostPost({
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

    print('📤 Uploading lost item with location...');

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
    final lostDocRef = _firestore.collection('lost_items').doc();
    
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
    
    batch.set(lostDocRef, postData);
    
    await batch.commit();
    print('✅ Lost item uploaded successfully with location data');

    // Try to find a match in found_items
    final foundQuery = await _firestore.collection('found_items')
      .where('type', isEqualTo: type)
      .where('matched', isEqualTo: false)
      .get();
    
    bool matchFound = false;
    double bestMatchScore = 0.0;
    DocumentSnapshot? bestMatch;
    
    print('🔍 Searching for matches among ${foundQuery.docs.length} found items...');
    
    // Early termination threshold - if we find a very good match, stop searching
    const double earlyTerminationThreshold = 0.8; // 80% match score
    
    // Add timeout to prevent hanging
    final startTime = DateTime.now();
    const maxSearchTime = Duration(seconds: 15); // 15 second timeout
    
    for (final doc in foundQuery.docs) {
      // Check timeout
      if (DateTime.now().difference(startTime) > maxSearchTime) {
        print('⏰ Search timeout reached, stopping search');
        break;
      }
      
      final found = doc.data();
      bool isMatch = false;
      double imageSimilarity = 0.0;
      
      // Quick text-based pre-filter to avoid expensive image comparison
      bool textMatch = false;
      
      if (type == 'ID') {
        final foundSubType = (found['subType'] ?? '').toString().trim().toLowerCase();
        final foundInstitution = (found['institution'] ?? '').toString().trim().toLowerCase();
        final mySubType = (subType ?? '').toString().trim().toLowerCase();
        final myInstitution = (institution ?? '').toString().trim().toLowerCase();
        
        textMatch = (foundSubType == mySubType) &&
                    (institution == null || foundInstitution == myInstitution);
      } else {
        // For other types, do basic text matching first
        final foundDetails = found['details'] ?? {};
        final myDetails = details;
        
        // Simple text matching based on type
        if (type == 'Person') {
          final foundName = (foundDetails['name'] ?? '').toString().trim().toLowerCase();
          final myName = (myDetails['name'] ?? '').toString().trim().toLowerCase();
          textMatch = foundName.isNotEmpty && myName.isNotEmpty && foundName == myName;
        } else if (type == 'Electronics') {
          final foundDeviceType = (foundDetails['deviceType'] ?? '').toString().trim().toLowerCase();
          final myDeviceType = (myDetails['deviceType'] ?? '').toString().trim().toLowerCase();
          textMatch = foundDeviceType.isNotEmpty && myDeviceType.isNotEmpty && foundDeviceType == myDeviceType;
        } else {
          // For other types, assume text match to proceed with image comparison
          textMatch = true;
        }
      }
      
      // Only proceed with image comparison if text matches or for certain types
      if (textMatch || type == 'Other' || type == 'Clothing & Bags') {
        // Calculate image similarity using hybrid approach
        if (found['imageUrl'] != null) {
          imageSimilarity = await calculateImageSimilarity(imageUrl, found['imageUrl']);
          print('📊 Image similarity with ${doc.id}: ${(imageSimilarity * 100).toStringAsFixed(1)}%');
        }
        
        // Calculate location-based score if both items have location
        double locationScore = 0.0;
        if (position != null && found['latitude'] != null && found['longitude'] != null) {
          Position foundPosition = Position(
            latitude: found['latitude'],
            longitude: found['longitude'],
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
          
          double distance = LocationService.calculateDistance(position, foundPosition);
          
          if (distance <= 100) { locationScore = 1.0; }
          else if (distance <= 1000) { locationScore = 0.8; }
          else if (distance <= 5000) { locationScore = 0.5; }
          else { locationScore = 0.1; }
        }
        
        if (type == 'ID') {
          final foundSubType = (found['subType'] ?? '').toString().trim().toLowerCase();
          final foundInstitution = (found['institution'] ?? '').toString().trim().toLowerCase();
          final mySubType = (subType ?? '').toString().trim().toLowerCase();
          final myInstitution = (institution ?? '').toString().trim().toLowerCase();
          
          // Enhanced ID matching with image similarity and location
          bool textMatch = (foundSubType == mySubType) &&
                          (institution == null || foundInstitution == myInstitution);
          
          print('🆔 ID Text match: $textMatch (SubType: $mySubType == $foundSubType)');
          
          // For IDs, require both text match AND good image similarity
          isMatch = textMatch && imageSimilarity > 0.5; // 50% similarity threshold
          
          print('🆔 ID Final match: $isMatch (Image similarity: ${(imageSimilarity * 100).toStringAsFixed(1)}%)');
          
          // Calculate overall score including location
          if (isMatch) {
            double overallScore = (imageSimilarity * 0.6) + (locationScore * 0.4);
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
          final foundDetails = found['details'] ?? {};
          final foundName = (foundDetails['name'] ?? '').toString().trim().toLowerCase();
          final foundAge = (foundDetails['age'] ?? '').toString().trim();
          final foundGender = (foundDetails['gender'] ?? '').toString().trim().toLowerCase();
          final foundDescription = (foundDetails['description'] ?? '').toString().trim().toLowerCase();
          
          final myName = (details['name'] ?? '').toString().trim().toLowerCase();
          final myAge = (details['age'] ?? '').toString().trim();
          final myGender = (details['gender'] ?? '').toString().trim().toLowerCase();
          final myDescription = (details['description'] ?? '').toString().trim().toLowerCase();
          
          // Calculate text-based match score
          int matchScore = 0;
          int totalCriteria = 0;
          
          if (myName.isNotEmpty && foundName.isNotEmpty) {
            totalCriteria++;
            if (foundName == myName) matchScore++;
          }
          
          if (myAge.isNotEmpty && foundAge.isNotEmpty) {
            totalCriteria++;
            if (foundAge == myAge) matchScore++;
          }
          
          if (myGender.isNotEmpty && foundGender.isNotEmpty) {
            totalCriteria++;
            if (foundGender == myGender) matchScore++;
          }
          
          if (myDescription.isNotEmpty && foundDescription.isNotEmpty) {
            totalCriteria++;
            final myKeywords = myDescription.split(' ').where((word) => word.length > 2).toSet();
            final foundKeywords = foundDescription.split(' ').where((word) => word.length > 2).toSet();
            final commonKeywords = myKeywords.intersection(foundKeywords);
            if (commonKeywords.length >= 1) matchScore++;
          }
          
          bool textMatch = totalCriteria >= 2 && matchScore >= (totalCriteria / 2);
          
          print('👤 Person Text match: $textMatch (Score: $matchScore/$totalCriteria)');
          
          // For people, use both text matching AND image similarity
          isMatch = textMatch && imageSimilarity > 0.3; // 30% similarity threshold
          
          print('👤 Person Final match: $isMatch (Image similarity: ${(imageSimilarity * 100).toStringAsFixed(1)}%)');
          
          // Calculate overall match score for Person including location
          if (isMatch) {
            final textScore = totalCriteria > 0 ? matchScore / totalCriteria : 0.0;
            final overallScore = (textScore * 0.4) + (imageSimilarity * 0.3) + (locationScore * 0.3);
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
          final foundDetails = found['details'] ?? {};
          final foundDeviceType = (foundDetails['deviceType'] ?? '').toString().trim().toLowerCase();
          final foundBrandModel = (foundDetails['brandModel'] ?? '').toString().trim().toLowerCase();
          final foundColor = (foundDetails['color'] ?? '').toString().trim().toLowerCase();
          final foundSerialNumber = (foundDetails['serialNumber'] ?? '').toString().trim();
          
          final myDeviceType = (details['deviceType'] ?? '').toString().trim().toLowerCase();
          final myBrandModel = (details['brandModel'] ?? '').toString().trim().toLowerCase();
          final myColor = (details['color'] ?? '').toString().trim().toLowerCase();
          final mySerialNumber = (details['serialNumber'] ?? '').toString().trim();
          
          // Calculate text-based match score
          int matchScore = 0;
          int totalCriteria = 0;
          
          if (myDeviceType.isNotEmpty && foundDeviceType.isNotEmpty) {
            totalCriteria++;
            if (foundDeviceType == myDeviceType) matchScore++;
          }
          
          if (myBrandModel.isNotEmpty && foundBrandModel.isNotEmpty) {
            totalCriteria++;
            if (foundBrandModel == myBrandModel) matchScore++;
          }
          
          if (myColor.isNotEmpty && foundColor.isNotEmpty) {
            totalCriteria++;
            if (foundColor == myColor) matchScore++;
          }
          
          if (mySerialNumber.isNotEmpty && foundSerialNumber.isNotEmpty) {
            totalCriteria++;
            if (foundSerialNumber == mySerialNumber) matchScore++;
          }
          
          bool textMatch = totalCriteria >= 2 && matchScore >= (totalCriteria / 2);
          
          print('📱 Electronics Text match: $textMatch (Score: $matchScore/$totalCriteria)');
          
          // For electronics, use both text matching AND image similarity
          isMatch = textMatch && imageSimilarity > 0.4; // 40% similarity threshold
          
          print('📱 Electronics Final match: $isMatch (Image similarity: ${(imageSimilarity * 100).toStringAsFixed(1)}%)');
          
          // Calculate overall match score for Electronics including location
          if (isMatch) {
            final textScore = totalCriteria > 0 ? matchScore / totalCriteria : 0.0;
            final overallScore = (textScore * 0.4) + (imageSimilarity * 0.3) + (locationScore * 0.3);
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
          final foundDetails = found['details'] ?? {};
          final foundJewelryType = (foundDetails['jewelryType'] ?? '').toString().trim().toLowerCase();
          final foundMaterial = (foundDetails['material'] ?? '').toString().trim().toLowerCase();
          final foundBrand = (foundDetails['brand'] ?? '').toString().trim().toLowerCase();
          final foundDistinctiveFeatures = (foundDetails['distinctiveFeatures'] ?? '').toString().trim().toLowerCase();
          
          final myJewelryType = (details['jewelryType'] ?? '').toString().trim().toLowerCase();
          final myMaterial = (details['material'] ?? '').toString().trim().toLowerCase();
          final myBrand = (details['brand'] ?? '').toString().trim().toLowerCase();
          final myDistinctiveFeatures = (details['distinctiveFeatures'] ?? '').toString().trim().toLowerCase();
          
          // Calculate text-based match score
          int matchScore = 0;
          int totalCriteria = 0;
          
          if (myJewelryType.isNotEmpty && foundJewelryType.isNotEmpty) {
            totalCriteria++;
            if (foundJewelryType == myJewelryType) matchScore++;
          }
          
          if (myMaterial.isNotEmpty && foundMaterial.isNotEmpty) {
            totalCriteria++;
            if (foundMaterial == myMaterial) matchScore++;
          }
          
          if (myBrand.isNotEmpty && foundBrand.isNotEmpty) {
            totalCriteria++;
            if (foundBrand == myBrand) matchScore++;
          }
          
          if (myDistinctiveFeatures.isNotEmpty && foundDistinctiveFeatures.isNotEmpty) {
            totalCriteria++;
            final myKeywords = myDistinctiveFeatures.split(' ').where((word) => word.length > 2).toSet();
            final foundKeywords = foundDistinctiveFeatures.split(' ').where((word) => word.length > 2).toSet();
            final commonKeywords = myKeywords.intersection(foundKeywords);
            if (commonKeywords.length >= 1) matchScore++;
          }
          
          bool textMatch = totalCriteria >= 2 && matchScore >= (totalCriteria / 2);
          
          print('💍 Jewelry Text match: $textMatch (Score: $matchScore/$totalCriteria)');
          
          // For jewelry, use both text matching AND image similarity
          isMatch = textMatch && imageSimilarity > 0.45; // 45% similarity threshold
          
          print('💍 Jewelry Final match: $isMatch (Image similarity: ${(imageSimilarity * 100).toStringAsFixed(1)}%)');
          
          // Calculate overall match score for Jewelry & Watches including location
          if (isMatch) {
            final textScore = totalCriteria > 0 ? matchScore / totalCriteria : 0.0;
            final overallScore = (textScore * 0.4) + (imageSimilarity * 0.3) + (locationScore * 0.3);
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
          final foundDetails = found['details'] ?? {};
          final foundItemType = (foundDetails['itemType'] ?? '').toString().trim().toLowerCase();
          final foundBrand = (foundDetails['brand'] ?? '').toString().trim().toLowerCase();
          final foundColor = (foundDetails['color'] ?? '').toString().trim().toLowerCase();
          final foundSize = (foundDetails['size'] ?? '').toString().trim().toLowerCase();
          final foundDistinctiveFeatures = (foundDetails['distinctiveFeatures'] ?? '').toString().trim().toLowerCase();
          
          final myItemType = (details['itemType'] ?? '').toString().trim().toLowerCase();
          final myBrand = (details['brand'] ?? '').toString().trim().toLowerCase();
          final myColor = (details['color'] ?? '').toString().trim().toLowerCase();
          final mySize = (details['size'] ?? '').toString().trim().toLowerCase();
          final myDistinctiveFeatures = (details['distinctiveFeatures'] ?? '').toString().trim().toLowerCase();
          
          // Calculate text-based match score
          int matchScore = 0;
          int totalCriteria = 0;
          
          if (myItemType.isNotEmpty && foundItemType.isNotEmpty) {
            totalCriteria++;
            if (foundItemType == myItemType) matchScore++;
          }
          
          if (myBrand.isNotEmpty && foundBrand.isNotEmpty) {
            totalCriteria++;
            if (foundBrand == myBrand) matchScore++;
          }
          
          if (myColor.isNotEmpty && foundColor.isNotEmpty) {
            totalCriteria++;
            if (foundColor == myColor) matchScore++;
          }
          
          if (mySize.isNotEmpty && foundSize.isNotEmpty) {
            totalCriteria++;
            if (foundSize == mySize) matchScore++;
          }
          
          if (myDistinctiveFeatures.isNotEmpty && foundDistinctiveFeatures.isNotEmpty) {
            totalCriteria++;
            final myKeywords = myDistinctiveFeatures.split(' ').where((word) => word.length > 2).toSet();
            final foundKeywords = foundDistinctiveFeatures.split(' ').where((word) => word.length > 2).toSet();
            final commonKeywords = myKeywords.intersection(foundKeywords);
            if (commonKeywords.length >= 1) matchScore++;
          }
          
          bool textMatch = totalCriteria >= 2 && matchScore >= (totalCriteria / 2);
          
          print('👕 Clothing Text match: $textMatch (Score: $matchScore/$totalCriteria)');
          
          // For clothing, use both text matching AND image similarity
          isMatch = textMatch && imageSimilarity > 0.35; // 35% similarity threshold
          
          print('👕 Clothing Final match: $isMatch (Image similarity: ${(imageSimilarity * 100).toStringAsFixed(1)}%)');
          
          // Calculate overall match score for Clothing & Bags including location
          if (isMatch) {
            final textScore = totalCriteria > 0 ? matchScore / totalCriteria : 0.0;
            final overallScore = (textScore * 0.3) + (imageSimilarity * 0.4) + (locationScore * 0.3);
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
          final foundDetails = found['details'] ?? {};
          final foundDocumentType = (foundDetails['documentType'] ?? '').toString().trim().toLowerCase();
          final foundIssuingAuthority = (foundDetails['issuingAuthority'] ?? '').toString().trim().toLowerCase();
          final foundDocumentNumber = (foundDetails['documentNumber'] ?? '').toString().trim();
          final foundExpiryDate = (foundDetails['expiryDate'] ?? '').toString().trim();
          
          final myDocumentType = (details['documentType'] ?? '').toString().trim().toLowerCase();
          final myIssuingAuthority = (details['issuingAuthority'] ?? '').toString().trim().toLowerCase();
          final myDocumentNumber = (details['documentNumber'] ?? '').toString().trim();
          final myExpiryDate = (details['expiryDate'] ?? '').toString().trim();
          
          // Calculate text-based match score
          int matchScore = 0;
          int totalCriteria = 0;
          
          if (myDocumentType.isNotEmpty && foundDocumentType.isNotEmpty) {
            totalCriteria++;
            if (foundDocumentType == myDocumentType) matchScore++;
          }
          
          if (myIssuingAuthority.isNotEmpty && foundIssuingAuthority.isNotEmpty) {
            totalCriteria++;
            if (foundIssuingAuthority == myIssuingAuthority) matchScore++;
          }
          
          if (myDocumentNumber.isNotEmpty && foundDocumentNumber.isNotEmpty) {
            totalCriteria++;
            if (foundDocumentNumber == myDocumentNumber) matchScore++;
          }
          
          if (myExpiryDate.isNotEmpty && foundExpiryDate.isNotEmpty) {
            totalCriteria++;
            if (foundExpiryDate == myExpiryDate) matchScore++;
          }
          
          bool textMatch = totalCriteria >= 2 && matchScore >= (totalCriteria / 2);
          
          print('📄 Documents Text match: $textMatch (Score: $matchScore/$totalCriteria)');
          
          // For documents, require both text match AND good image similarity
          isMatch = textMatch && imageSimilarity > 0.5; // 50% similarity threshold
          
          print('📄 Documents Final match: $isMatch (Image similarity: ${(imageSimilarity * 100).toStringAsFixed(1)}%)');
          
          // Calculate overall match score for Documents including location
          if (isMatch) {
            final textScore = totalCriteria > 0 ? matchScore / totalCriteria : 0.0;
            final overallScore = (textScore * 0.5) + (imageSimilarity * 0.3) + (locationScore * 0.2);
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
          final foundDetails = found['details'] ?? {};
          final foundDescription = (foundDetails['description'] ?? '').toString().trim().toLowerCase();
          
          final myDescription = (details['description'] ?? '').toString().trim().toLowerCase();
          
          // For other items, rely heavily on description matching and image similarity
          bool textMatch = false;
          if (myDescription.isNotEmpty && foundDescription.isNotEmpty) {
            final myKeywords = myDescription.split(' ').where((word) => word.length > 2).toSet();
            final foundKeywords = foundDescription.split(' ').where((word) => word.length > 2).toSet();
            final commonKeywords = myKeywords.intersection(foundKeywords);
            textMatch = commonKeywords.length >= 2; // Require at least 2 common keywords
          }
          
          print('🔍 Other Text match: $textMatch');
          
          // For other items, use both text matching AND image similarity
          isMatch = textMatch && imageSimilarity > 0.4; // 40% similarity threshold
          
          print('🔍 Other Final match: $isMatch (Image similarity: ${(imageSimilarity * 100).toStringAsFixed(1)}%)');
          
          // Calculate overall match score for Other including location
          if (isMatch) {
            final overallScore = (imageSimilarity * 0.5) + (locationScore * 0.5); // For other items, rely more on image similarity and location
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
      final found = bestMatch.data() as Map<String, dynamic>;
      
      print('🏆 Processing best match with score: ${(bestMatchScore * 100).toStringAsFixed(1)}%');
      
      // Create a new batch for matching operations
      final matchBatch = _firestore.batch();
      
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
      
      // Mark both as matched using new batch
      matchBatch.update(lostDocRef, {'matched': true, 'matchedWith': bestMatch.id});
      matchBatch.update(bestMatch.reference, {'matched': true, 'matchedWith': lostDocRef.id});
      
      // Create match model with actual score
      matchBatch.set(_firestore.collection('matches').doc(), {
        'lostItemId': lostDocRef.id,
        'foundItemId': bestMatch.id,
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
          'message': 'A matching $type has been found! Contact the finder to proceed.',
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
          
          // Get lost location (current user's location)
          if (position != null) {
            lostLocation = await LocationService.getLocationName(position);
            print('📍 Lost location: $lostLocation');
          }
          
          // Get found location (from the matched found item)
          if (found['locationName'] != null && found['locationName'].isNotEmpty) {
            foundLocation = found['locationName'];
            print('📍 Found location from stored name: $foundLocation');
          } else if (found['latitude'] != null && found['longitude'] != null) {
            // Convert coordinates to location name
            Position foundPos = Position(
              latitude: found['latitude'],
              longitude: found['longitude'],
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
            foundLocation = await LocationService.getLocationName(foundPos);
            print('📍 Found location from coordinates: $foundLocation');
          } else {
            print('⚠️ No location data available for found item');
          }
          
          // SMS for lost user (who lost the item)
          final lostSms = '''ReclaimSpace:
Dear $lostName,
A matching $type has been found!
Contact $foundName (the finder) on $foundPhone, email: $foundEmail to proceed.
Found at: $foundLocation
Your location: $lostLocation
Match Score: ${(bestMatchScore * 100).toStringAsFixed(1)}%''';
          
          print('📤 Sending SMS to lost user: $lostPhone');
          await sendSMSNotification(lostPhone, lostSms);
          
          // SMS for found user (who found the item)
          final foundSms = '''ReclaimSpace:
Dear $foundName,
Someone has reported losing a $type that matches what you found!
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
