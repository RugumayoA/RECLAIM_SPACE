import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

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

  static Future<Map<String, String>> uploadImageWithHash(dynamic image) async {
    // image: io.File (mobile) or Uint8List (web)
    List<int> bytes;
    if (kIsWeb && image is Uint8List) {
      bytes = image;
    } else if (image is io.File) {
      bytes = await image.readAsBytes();
    } else {
      throw Exception('Unsupported image type');
    }
    final base64Image = base64Encode(bytes);
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey');
    final response = await http.post(
      url,
      body: {
        'image': base64Image,
      },
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      final hash = md5.convert(bytes).toString();
      return {'url': data['data']['url'], 'hash': hash};
    } else {
      throw Exception('Image upload failed: ${data['error']['message']}');
    }
  }

  static Future<double> compareImages(dynamic image1, dynamic image2) async {
    // Accept io.File, Uint8List, or List<int>
    List<int> bytes1;
    List<int> bytes2;
    if (image1 is Uint8List) {
      bytes1 = image1;
    } else if (image1 is List<int>) {
      bytes1 = Uint8List.fromList(image1);
    } else if (image1 is io.File) {
      bytes1 = await image1.readAsBytes();
    } else {
      throw Exception('Unsupported image type');
    }
    if (image2 is Uint8List) {
      bytes2 = image2;
    } else if (image2 is List<int>) {
      bytes2 = Uint8List.fromList(image2);
    } else if (image2 is io.File) {
      bytes2 = await image2.readAsBytes();
    } else {
      throw Exception('Unsupported image type');
    }
    // Ensure bytes are Uint8List for decodeImage
    final img1 = img.decodeImage(Uint8List.fromList(bytes1));
    final img2 = img.decodeImage(Uint8List.fromList(bytes2));
    if (img1 == null || img2 == null) return 0.0;
    // Resize to same size for comparison
    final img1Resized = img.copyResize(img1, width: 100, height: 100);
    final img2Resized = img.copyResize(img2, width: 100, height: 100);
    // Calculate pixel difference
    int diff = 0;
    for (int y = 0; y < 100; y++) {
      for (int x = 0; x < 100; x++) {
        if (img1Resized.getPixel(x, y) != img2Resized.getPixel(x, y)) {
          diff++;
        }
      }
    }
    final total = 100 * 100;
    final similarity = 1.0 - (diff / total);
    return similarity; // 1.0 = identical, 0.0 = completely different
  }
} 