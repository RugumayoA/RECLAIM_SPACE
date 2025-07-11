import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImageUploadService {
  static const String _apiKey = '332a824ca7c586cc88850a24b7896875'; // User's imgbb API key

  static Future<String> uploadImage(dynamic image) async {
    // image: io.File (mobile) or Uint8List (web)
    String base64Image;
    if (kIsWeb && image is Uint8List) {
      base64Image = base64Encode(image);
    } else if (image is io.File) {
      base64Image = base64Encode(await image.readAsBytes());
    } else {
      throw Exception('Unsupported image type');
    }
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey');
    final response = await http.post(
      url,
      body: {
        'image': base64Image,
      },
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return data['data']['url'];
    } else {
      throw Exception('Image upload failed: ${data['error']['message']}');
    }
  }
} 