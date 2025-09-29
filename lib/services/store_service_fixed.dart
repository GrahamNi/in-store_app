// Store Service - Fixed to download ALL stores and calculate distances locally
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoreServiceFixed {
  static const String _storesApiUrl = 'https://api-nearest-stores-951551492434.australia-southeast1.run.app/';
  static final Dio _dio = Dio();
  
  // Cache keys
  static const String _cacheKey = 'cached_stores';
  static const String _lastUpdateKey = 'stores_last_update';
  
  /// Downloads ALL stores from the server
  /// This should be called on login and periodically when the store list is opened
  static Future<List<Map<String, dynamic>>> downloadAllStores() async {
    try {
      debugPrint('📥 STORE SERVICE: Downloading all stores from server...');
      debugPrint('📥 STORE SERVICE: URL: $_storesApiUrl');
      
      // Call API with a default location to get all stores
      // The server returns all stores sorted by distance from this point
      final response = await _dio.post(
        _storesApiUrl,
        data: {
          'lat': -32.9273,  // Default Newcastle location
          'lon': 151.7817,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      
      debugPrint('📥 STORE SERVICE: Response status: ${response.statusCode}');
      debugPrint('📥 STORE SERVICE: Response type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        List<Map<String, dynamic>> stores = [];
        
        // Handle different response formats
        if (data is List) {
          debugPrint('📥 STORE SERVICE: Direct array with ${data.length} stores');
          stores = List<Map<String, dynamic>>.from(data);
        } else if (data is Map<String, dynamic>) {
          debugPrint('📥 STORE SERVICE: Map response with keys: ${data.keys.toList()}');
          
          // Try different possible keys
          if (data.containsKey('results')) {
            debugPrint('📥 STORE SERVICE: Found results key with ${data['results'].length} stores');
            stores = List<Map<String, dynamic>>.from(data['results']);
          } else if (data.containsKey('stores')) {
            stores = List<Map<String, dynamic>>.from(data['stores']);
          } else if (data.containsKey('data')) {
            stores = List<Map<String, dynamic>>.from(data['data']);
          } else {
            // If it's a map but we don't know the key, log it
            debugPrint('📥 STORE SERVICE: Unknown response structure');
            debugPrint('📥 STORE SERVICE: Keys found: ${data.keys.toList()}');
            
            // Try to find the first key that contains a list
            for (String key in data.keys) {
              if (data[key] is List) {
                debugPrint('📥 STORE SERVICE: Found list in key "$key"');
                stores = List<Map<String, dynamic>>.from(data[key]);
                break;
              }
            }
          }
        }
        
        if (stores.isNotEmpty) {
          debugPrint('✅ STORE SERVICE: Downloaded ${stores.length} stores');
          debugPrint('📥 STORE SERVICE: First store example: ${stores.first}');
          
          // Cache the stores locally
          await _cacheStores(stores);
          
          return stores;
        } else {
          debugPrint('⚠️ STORE SERVICE: No stores found in response');
          return [];
        }
      } else {
        debugPrint('❌ STORE SERVICE: API error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ STORE SERVICE: Download error: $e');
      // Try to return cached stores if download fails
      return await _getCachedStores();
    }
  }
  
  /// Get stores with distances calculated from current location
  /// This does NOT call the API - it uses cached stores
  static Future<List<Map<String, dynamic>>> getNearestStores({
    double? latitude,
    double? longitude,
    int limit = 5,
  }) async {
    debugPrint('📍 STORE SERVICE: Getting nearest stores from cache...');
    
    // Get all cached stores
    List<Map<String, dynamic>> allStores = await _getCachedStores();
    
    if (allStores.isEmpty) {
      debugPrint('⚠️ STORE SERVICE: No cached stores, attempting download...');
      allStores = await downloadAllStores();
      
      if (allStores.isEmpty) {
        debugPrint('❌ STORE SERVICE: No stores available');
        return [];
      }
    }
    
    // Get user location
    double lat = latitude ?? 0.0;
    double lon = longitude ?? 0.0;
    
    if (latitude == null || longitude == null) {
      try {
        final position = await _getCurrentLocation();
        lat = position.latitude;
        lon = position.longitude;
        debugPrint('📍 STORE SERVICE: Using GPS location: $lat, $lon');
      } catch (e) {
        // Fallback to Newcastle
        lat = -32.9273;
        lon = 151.7817;
        debugPrint('📍 STORE SERVICE: Using fallback location: Newcastle');
      }
    }
    
    // Calculate distance for each store
    for (var store in allStores) {
      double storeLat = (store['latitude'] ?? store['lat'] ?? 0.0).toDouble();
      double storeLon = (store['longitude'] ?? store['lon'] ?? store['lng'] ?? 0.0).toDouble();
      
      double distance = _calculateDistance(lat, lon, storeLat, storeLon);
      store['distance'] = distance;
      store['distance_km'] = distance;
    }
    
    // Sort by distance
    allStores.sort((a, b) => (a['distance'] ?? 999.0).compareTo(b['distance'] ?? 999.0));
    
    // Return only the nearest stores
    List<Map<String, dynamic>> nearestStores = allStores.take(limit).toList();
    
    debugPrint('✅ STORE SERVICE: Returning ${nearestStores.length} nearest stores');
    if (nearestStores.isNotEmpty) {
      debugPrint('📍 Nearest: ${nearestStores.first['name']} - ${nearestStores.first['distance']?.toStringAsFixed(1)}km');
    }
    
    return nearestStores;
  }
  
  /// Check if we should update stores from server
  static Future<bool> shouldUpdateStores() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Update if more than 1 hour old
    const updateInterval = Duration(hours: 1);
    return (now - lastUpdate) > updateInterval.inMilliseconds;
  }
  
  /// Update stores if needed
  static Future<List<Map<String, dynamic>>> updateStoresIfNeeded() async {
    if (await shouldUpdateStores()) {
      debugPrint('🔄 STORE SERVICE: Stores cache is old, updating...');
      return await downloadAllStores();
    } else {
      debugPrint('✅ STORE SERVICE: Stores cache is fresh');
      return await _getCachedStores();
    }
  }
  
  // Helper: Calculate distance between two points
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }
  
  // Helper: Get current location
  static Future<Position> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever || 
        permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }
    
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );
  }
  
  // Helper: Cache stores locally
  static Future<void> _cacheStores(List<Map<String, dynamic>> stores) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storesJson = jsonEncode(stores);
      await prefs.setString(_cacheKey, storesJson);
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('💾 STORE SERVICE: Cached ${stores.length} stores');
    } catch (e) {
      debugPrint('❌ STORE SERVICE: Failed to cache stores: $e');
    }
  }
  
  // Helper: Get cached stores
  static Future<List<Map<String, dynamic>>> _getCachedStores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storesJson = prefs.getString(_cacheKey);
      
      if (storesJson != null) {
        final stores = List<Map<String, dynamic>>.from(jsonDecode(storesJson));
        debugPrint('💾 STORE SERVICE: Retrieved ${stores.length} stores from cache');
        return stores;
      }
    } catch (e) {
      debugPrint('❌ STORE SERVICE: Failed to get cached stores: $e');
    }
    
    return [];
  }
  
  // Helper: Convert API store format to app format
  static Map<String, dynamic> convertApiStoreToAppStore(Map<String, dynamic> apiStore) {
    // Extract chain from store name (e.g., "New World New Plymouth" -> "New World")
    String storeName = apiStore['name'] ?? apiStore['store_name'] ?? 'Unknown Store';
    String chain = 'Unknown';
    
    // Try to extract chain from store name
    if (storeName.toLowerCase().contains('new world')) {
      chain = 'New World';
    } else if (storeName.toLowerCase().contains('woolworth')) {
      chain = 'Woolworths';
    } else if (storeName.toLowerCase().contains('countdown')) {
      chain = 'Countdown';
    } else if (storeName.toLowerCase().contains('pak')) {
      chain = "Pak'nSave";
    } else if (storeName.toLowerCase().contains('fresh choice')) {
      chain = 'FreshChoice';
    } else if (storeName.toLowerCase().contains('four square')) {
      chain = 'Four Square';
    } else {
      // Fallback: use first word(s) of store name
      chain = storeName.split(' ').take(2).join(' ');
    }
    
    // Get address from extra field
    String address = '';
    String suburb = '';
    String city = '';
    String postcode = '';
    String state = '';
    
    if (apiStore['extra'] != null) {
      final extra = apiStore['extra'];
      address = extra['address_1'] ?? '';
      suburb = extra['city'] ?? '';
      city = extra['city'] ?? '';
      postcode = extra['postcode'] ?? '';
      state = extra['state'] ?? '';
    }
    
    return {
      'id': apiStore['id']?.toString() ?? 'unknown',
      'name': storeName,
      'chain': chain,
      'address': address,
      'suburb': suburb,
      'city': city,
      'postcode': postcode,
      'state': state,
      'latitude': (apiStore['lat'] ?? 0.0).toDouble(),
      'longitude': (apiStore['lon'] ?? 0.0).toDouble(),
      'distance': (apiStore['distance_km'] ?? 0.0).toDouble(),
    };
  }
  
  // Test function
  static Future<void> testStoreService() async {
    debugPrint('🧪 STORE SERVICE TEST: Starting test...');
    
    // 1. Test downloading all stores
    debugPrint('🧪 Test 1: Download all stores');
    List<Map<String, dynamic>> allStores = await downloadAllStores();
    debugPrint('🧪 Downloaded ${allStores.length} stores');
    
    // 2. Test getting nearest stores
    debugPrint('🧪 Test 2: Get nearest stores');
    List<Map<String, dynamic>> nearestStores = await getNearestStores();
    debugPrint('🧪 Found ${nearestStores.length} nearest stores');
    
    if (nearestStores.isNotEmpty) {
      debugPrint('🧪 Nearest store: ${nearestStores.first['name']} - ${nearestStores.first['distance']?.toStringAsFixed(1)}km');
    }
    
    debugPrint('🧪 STORE SERVICE TEST: Complete');
  }
}
