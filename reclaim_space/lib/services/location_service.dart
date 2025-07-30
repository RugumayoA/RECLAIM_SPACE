import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  static Future<Position?> getCurrentLocation(BuildContext context) async {
    try {
      print('📍 Getting user location...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        _showLocationError(context, 'Location services are disabled. Please enable location services in your device settings.');
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print('🔐 Requesting location permission...');
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied');
          _showLocationError(context, 'Location permission is required to post items with location data.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission denied forever');
        _showLocationError(context, 'Location permission is permanently denied. Please enable it in app settings.');
        return null;
      }

      // Get current position
      print('📱 Getting current GPS coordinates...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('✅ Location permission granted');
      print('📱 Current GPS: ${position.latitude}° N, ${position.longitude}° E');
      print('📊 Accuracy: ${position.accuracy} meters');

      return position;

    } catch (e) {
      print('❌ Error getting location: $e');
      _showLocationError(context, 'Failed to get location. Please try again.');
      return null;
    }
  }

  static Future<String> getLocationName(Position position) async {
    try {
      print('🏢 Getting location name from coordinates...');

      // Use OpenStreetMap Nominatim API for reverse geocoding
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1'
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'ReclaimSpace/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['display_name'] as String?;
        
        if (address != null && address.isNotEmpty) {
          // Extract a shorter, more readable location name
          final parts = address.split(', ');
          String locationName = '';
          
          // Try to get the most relevant parts (usually first 2-3 parts)
          if (parts.length >= 2) {
            locationName = parts.take(3).join(', ');
          } else {
            locationName = address;
          }
          
          print('🏢 Location name: $locationName');
          return locationName;
        }
      }

      // Fallback to coordinates if geocoding fails
      String locationName = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      print('🏢 Fallback location name: $locationName');
      return locationName;

    } catch (e) {
      print('❌ Error getting location name: $e');
      return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }
  }

  static Future<String> getFullAddress(Position position) async {
    try {
      print('🏢 Getting full address from coordinates...');

      // Use OpenStreetMap Nominatim API for reverse geocoding
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1'
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'ReclaimSpace/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['display_name'] as String?;
        
        if (address != null && address.isNotEmpty) {
          print('🏢 Full address: $address');
          return address;
        }
      }

      // Fallback to coordinates if geocoding fails
      String address = 'Location at ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      print('🏢 Fallback address: $address');
      return address;

    } catch (e) {
      print('❌ Error getting full address: $e');
      return 'Location at ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }
  }

  static double calculateDistance(Position pos1, Position pos2) {
    double distance = Geolocator.distanceBetween(
      pos1.latitude, pos1.longitude,
      pos2.latitude, pos2.longitude,
    );

    print('📏 Distance between points: ${distance.toStringAsFixed(1)} meters');
    return distance;
  }

  static void _showLocationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
} 