import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String color;
  final GeoPoint location;
  final String? imageUrl;
  final String? extractedText;
  final String status; // 'active', 'matched', 'resolved'
  final String? matchedWithId;
  final DateTime createdAt;
  final List<String> keywords;
  final bool isLost; // true for lost items, false for found items

  ItemModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.color,
    required this.location,
    this.imageUrl,
    this.extractedText,
    this.status = 'active',
    this.matchedWithId,
    required this.createdAt,
    this.keywords = const [],
    required this.isLost,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map, String id) {
    return ItemModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      color: map['color'] ?? '',
      location: map['location'] ?? const GeoPoint(0, 0),
      imageUrl: map['imageUrl'],
      extractedText: map['extractedText'],
      status: map['status'] ?? 'active',
      matchedWithId: map['matchedWithId'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      keywords: List<String>.from(map['keywords'] ?? []),
      isLost: map['isLost'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'color': color,
      'location': location,
      'imageUrl': imageUrl,
      'extractedText': extractedText,
      'status': status,
      'matchedWithId': matchedWithId,
      'createdAt': createdAt,
      'keywords': keywords,
      'isLost': isLost,
    };
  }
}