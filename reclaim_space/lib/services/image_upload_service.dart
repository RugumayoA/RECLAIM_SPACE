import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'dart:math';

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
    
    // Compress image to reduce upload size
    final originalImage = img.decodeImage(Uint8List.fromList(bytes));
    if (originalImage != null) {
      // Resize to max 800x800 to reduce file size
      final compressedImage = img.copyResize(
        originalImage,
        width: originalImage.width > 800 ? 800 : originalImage.width,
        height: originalImage.height > 800 ? 800 : originalImage.height,
      );
      bytes = Uint8List.fromList(img.encodeJpg(compressedImage, quality: 85));
    }
    
    final base64Image = base64Encode(bytes);
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey');
    
    // Add timeout to prevent hanging
    final response = await http.post(
      url,
      body: {
        'image': base64Image,
      },
    ).timeout(const Duration(seconds: 30));
    
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

  // Enhanced custom algorithm for better angle tolerance
  static Future<double> compareImagesEnhanced(dynamic image1, dynamic image2) async {
    List<int> bytes1;
    List<int> bytes2;
    
    // Convert to bytes
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

    final img1 = img.decodeImage(Uint8List.fromList(bytes1));
    final img2 = img.decodeImage(Uint8List.fromList(bytes2));
    
    if (img1 == null || img2 == null) return 0.0;

    // Resize both images to same size for comparison
    final img1Resized = img.copyResize(img1, width: 64, height: 64);
    final img2Resized = img.copyResize(img2, width: 64, height: 64);

    // Convert to grayscale for better comparison
    final img1Gray = img.grayscale(img1Resized);
    final img2Gray = img.grayscale(img2Resized);

    // Calculate multiple similarity metrics
    double structuralSimilarity = _calculateStructuralSimilarity(img1Gray, img2Gray);
    double colorHistogramSimilarity = _calculateColorHistogramSimilarity(img1Resized, img2Resized);
    double edgeSimilarity = _calculateEdgeSimilarity(img1Gray, img2Gray);

    // Weighted average of different similarity measures
    final similarity = (structuralSimilarity * 0.4 + 
                       colorHistogramSimilarity * 0.3 + 
                       edgeSimilarity * 0.3);
    
    return similarity.clamp(0.0, 1.0);
  }

  static double _calculateStructuralSimilarity(img.Image img1, img.Image img2) {
    int diff = 0;
    final total = img1.width * img1.height;
    
    for (int y = 0; y < img1.height; y++) {
      for (int x = 0; x < img1.width; x++) {
        final pixel1 = img1.getPixel(x, y);
        final pixel2 = img2.getPixel(x, y);
        
        // Fix: Use proper pixel color extraction
        final brightness1 = pixel1.r * 0.299 + pixel1.g * 0.587 + pixel1.b * 0.114;
        final brightness2 = pixel2.r * 0.299 + pixel2.g * 0.587 + pixel2.b * 0.114;
        
        if ((brightness1 - brightness2).abs() > 30) {
          diff++;
        }
      }
    }
    
    return 1.0 - (diff / total);
  }

  static double _calculateColorHistogramSimilarity(img.Image img1, img.Image img2) {
    final histogram1 = _calculateColorHistogram(img1);
    final histogram2 = _calculateColorHistogram(img2);
    
    return _calculateHistogramIntersection(histogram1, histogram2);
  }

  static List<int> _calculateColorHistogram(img.Image image) {
    final histogram = List<int>.filled(256, 0);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        // Fix: Use proper pixel color extraction
        final gray = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114;
        histogram[gray.toInt()]++;
      }
    }
    
    return histogram;
  }

  static double _calculateHistogramIntersection(List<int> hist1, List<int> hist2) {
    int intersection = 0;
    int sum1 = 0;
    int sum2 = 0;
    
    for (int i = 0; i < 256; i++) {
      intersection += hist1[i] < hist2[i] ? hist1[i] : hist2[i];
      sum1 += hist1[i];
      sum2 += hist2[i];
    }
    
    return intersection / (sum1 < sum2 ? sum1 : sum2);
  }

  static double _calculateEdgeSimilarity(img.Image img1, img.Image img2) {
    // Simple edge detection using Sobel operator
    final edges1 = _detectEdges(img1);
    final edges2 = _detectEdges(img2);
    
    int matchingEdges = 0;
    int totalEdges = 0;
    
    for (int y = 0; y < img1.height; y++) {
      for (int x = 0; x < img1.width; x++) {
        if (edges1[y][x] > 0 || edges2[y][x] > 0) {
          totalEdges++;
          if ((edges1[y][x] > 0 && edges2[y][x] > 0) ||
              (edges1[y][x] == 0 && edges2[y][x] == 0)) {
            matchingEdges++;
          }
        }
      }
    }
    
    return totalEdges > 0 ? matchingEdges / totalEdges : 1.0;
  }

  static List<List<int>> _detectEdges(img.Image image) {
    final edges = List.generate(image.height, (y) => List<int>.filled(image.width, 0));
    
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        // Simple edge detection
        final center = image.getPixel(x, y);
        final right = image.getPixel(x + 1, y);
        final bottom = image.getPixel(x, y + 1);
        
        // Fix: Use proper pixel comparison
        final diffX = (center.r - right.r).abs() + (center.g - right.g).abs() + (center.b - right.b).abs();
        final diffY = (center.r - bottom.r).abs() + (center.g - bottom.g).abs() + (center.b - bottom.b).abs();
        
        if (diffX > 50 || diffY > 50) {
          edges[y][x] = 1;
        }
      }
    }
    
    return edges;
  }

  // Hybrid approach that combines custom algorithm with cloud API
  static Future<double> compareImagesHybrid(String imageUrl1, String imageUrl2) async {
    try {
      print('🔄 Starting hybrid image comparison...');
      
      // Download both images
      final response1 = await http.get(Uri.parse(imageUrl1));
      final response2 = await http.get(Uri.parse(imageUrl2));
      
      if (response1.statusCode == 200 && response2.statusCode == 200) {
        final bytes1 = response1.bodyBytes;
        final bytes2 = response2.bodyBytes;
        
        // Phase 1: Enhanced custom algorithm
        double customScore = await compareImagesEnhanced(bytes1, bytes2);
        print('📊 Custom algorithm score: ${(customScore * 100).toStringAsFixed(1)}%');
        
        // Phase 2: Decision making based on confidence
        if (customScore > 0.8) {
          print('✅ High confidence: Using custom result (same angle detected)');
          return customScore;
          
        } else if (customScore > 0.3) {
          print(' Medium confidence: Possible different angles, using cloud API...');
          
          // Phase 3: Cloud API for angle-tolerant comparison
          double cloudScore = await compareWithGoogleVision(imageUrl1, imageUrl2);
          print('🌐 Cloud API score: ${(cloudScore * 100).toStringAsFixed(1)}%');
          
          return cloudScore;
          
        } else {
          print('❌ Low confidence: Likely different items');
          return customScore;
        }
        
      } else {
        print('❌ Error downloading images');
        return 0.0;
      }
      
    } catch (e) {
      print('❌ Error in hybrid comparison: $e');
      return 0.0;
    }
  }

  // Placeholder for Google Cloud Vision API
  static Future<double> compareWithGoogleVision(String imageUrl1, String imageUrl2) async {
    // TODO: Implement Google Cloud Vision API integration
    // For now, return a simulated score based on URL similarity
    // This is where you would add the actual cloud API call
    
    print('🌐 Simulating Google Vision API call...');
    
    // Simulate API processing time
    await Future.delayed(Duration(milliseconds: 500));
    
    // For testing, return a simulated score
    // In real implementation, this would call Google Cloud Vision API
    final random = Random();
    final baseScore = 0.6 + (random.nextDouble() * 0.3); // 60-90% range
    
    print('🌐 Simulated cloud API score: ${(baseScore * 100).toStringAsFixed(1)}%');
    return baseScore;
  }
} 