import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import 'package:geolocator/geolocator.dart';

class StoreService {
  // ✅ CORRECT API URL
 static const String baseUrl = 
'https://api-token-stores-951551492434.europe-west1.run.app';
  
  /// Fetch stores from the API with proper error handling and user_id
  static Future<List<Store>> fetchStores() async {
    try {
      debugPrint('🏪 STORES API: Starting store fetch...');
      
      // ✅ LOAD USER_ID FROM SHARED PREFERENCES
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      debugPrint('🏪 STORES API: User ID from prefs: $userId');
      
      if (userId == null || userId.isEmpty) {
        debugPrint('⚠️ STORES API WARNING: No user_id found in SharedPreferences!');
        throw Exception('No user_id found. Please log in again.');
      }
      
      debugPrint('🏪 STORES API: Fetching from: $baseUrl');
      debugPrint('🏪 STORES API: User ID (token): $userId');
      
      // ✅ API USES POST, NOT GET
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': userId,
          'lat': -32.9273,  // Default location to get all stores
          'lon': 151.7817,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Store API request timed out'),
      );

      debugPrint('🏪 STORES API: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('🏪 STORES API: Parsing response...');
        
        final dynamic data = json.decode(response.body);
        
        List<dynamic> storesList;
        
        // Handle different response formats
        if (data is List) {
          storesList = data;
        } else if (data is Map<String, dynamic>) {
          // Try different possible keys
          if (data.containsKey('results')) {
            storesList = data['results'] as List;
          } else if (data.containsKey('stores')) {
            storesList = data['stores'] as List;
          } else if (data.containsKey('data')) {
            storesList = data['data'] as List;
          } else {
            debugPrint('⚠️ STORES API: Unknown response structure: ${data.keys}');
            throw Exception('Unknown API response structure');
          }
        } else {
          throw Exception('Unexpected response type: ${data.runtimeType}');
        }
        
        debugPrint('🏪 STORES API: Found ${storesList.length} stores');
        
        if (storesList.isEmpty) {
          debugPrint('⚠️ STORES API: Empty store list returned!');
          debugPrint('⚠️ STORES API: Check if user_id "$userId" has stores assigned');
        }
        
        final stores = storesList.map((json) => Store.fromJson(json)).toList();
        
        debugPrint('✅ STORES API: Successfully parsed ${stores.length} stores');
        if (stores.isNotEmpty) {
          debugPrint('📍 STORES API: First store: ${stores.first.name}');
          debugPrint('📍 STORES API: Last store: ${stores.last.name}');
        }
        
        return stores;
      } else {
        debugPrint('❌ STORES API: Error ${response.statusCode}');
        debugPrint('❌ STORES API: Response body: ${response.body}');
        throw Exception('Failed to load stores: HTTP ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ STORES API: Exception: $e');
      debugPrint('❌ STORES API: Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get nearest stores with distance calculation (legacy compatibility method)
  static Future<List<Store>> getNearestStores({
    required double latitude,
    required double longitude,
  }) async {
    debugPrint('📍 NEAREST STORES: Fetching stores for location ($latitude, $longitude)');
    
    // Fetch all stores
    final stores = await fetchStores();
    
    // Calculate distances
    for (var store in stores) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        store.latitude,
        store.longitude,
      );
      store.distance = distance / 1000; // Convert to km
    }
    
    // Sort by distance
    stores.sort((a, b) => (a.distance ?? 999999).compareTo(b.distance ?? 999999));
    
    debugPrint('✅ NEAREST STORES: Sorted ${stores.length} stores by distance');
    if (stores.isNotEmpty) {
      debugPrint('📍 NEAREST STORES: Closest store: ${stores.first.name} (${stores.first.distance?.toStringAsFixed(2)} km)');
    }
    
    return stores;
  }

  /// Helper to check if we have a valid user_id
  static Future<bool> hasValidUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    return userId != null && userId.isNotEmpty && userId != 'unknown';
  }

  /// Get the current user_id for debugging
  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
}
