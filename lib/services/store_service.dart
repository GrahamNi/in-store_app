// Store Service - Integrates with your nearest stores API
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'auth_token_manager.dart';

class StoreService {
  static const String _storesApiUrl = 'https://api-token-stores-951551492434.europe-west1.run.app';
  static final Dio _dio = Dio();
  
  static Future<List<Map<String, dynamic>>> getNearestStores({
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Get user location if not provided
      double lat = latitude ?? 0.0;
      double lon = longitude ?? 0.0;
      
      if (latitude == null || longitude == null) {
        try {
          final position = await _getCurrentLocation();
          lat = position.latitude;
          lon = position.longitude;
        } catch (e) {
          // Fallback to default Newcastle location
          lat = -32.9273;
          lon = 151.7817;
          debugPrint('Using fallback location: Newcastle');
        }
      }
      
      debugPrint('Fetching stores for location: $lat, $lon');
      
      // Get user ID from auth - this is what we send as 'token' to the stores API
      final userId = await AuthTokenManager.getUserId();
      
      // CRITICAL: If userId is 'unknown' or null, use RDAS fallback
      final token = (userId == null || userId == 'unknown') ? 'RDAS' : userId;
      
      debugPrint('🔐 Using token (user_id) for stores API: $token');
      if (token == 'RDAS') {
        debugPrint('⚠️ WARNING: Using fallback token RDAS because user_id is: $userId');
        debugPrint('⚠️ This means authentication did not return a valid user_id');
      }
      
      // Make API call with token in request body - INCREASED TIMEOUTS for 642 stores
      final response = await _dio.post(
        _storesApiUrl,
        data: {
          'token': token,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 30), // Increased from 10
          receiveTimeout: const Duration(seconds: 30), // Increased from 10
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('✅ API Response received: ${data.runtimeType}');
        
        // DON'T print full response - it's 642 stores and causes timeout!
        // debugPrint(const JsonEncoder.withIndent('  ').convert(data));
        
        // New API returns array of stores directly or wrapped in results
        List<dynamic> storesList;
        
        if (data is List) {
          storesList = data;
          debugPrint('✅ Response is a direct list');
        } else if (data is Map<String, dynamic>) {
          debugPrint('📋 Response is a map with keys: ${data.keys.toList()}');
          
          if (data.containsKey('results')) {
            storesList = data['results'] as List;
            debugPrint('✅ Using results array from response');
          } else if (data.containsKey('stores')) {
            storesList = data['stores'] as List;
            debugPrint('✅ Using stores array from response');
          } else {
            debugPrint('❌ Map has no results or stores key');
            debugPrint('Available keys: ${data.keys.toList()}');
            return [];
          }
        } else {
          debugPrint('❌ Unexpected API response format');
          return [];
        }
        
        debugPrint('✅ Found ${storesList.length} stores in response');
        
        if (storesList.isEmpty) {
          debugPrint('⚠️ WARNING: API returned empty stores list');
          debugPrint('⚠️ This means the token "$token" has no associated stores');
          debugPrint('⚠️ Try logging in with different credentials or check backend data');
        }
        
        // Calculate distances for each store
        final storesWithDistance = storesList.map((store) {
          final storeMap = store as Map<String, dynamic>;
          
          // API returns lat/lon as strings - safely parse them
          final storeLat = _parseDouble(storeMap['latitude'] ?? storeMap['lat']);
          final storeLon = _parseDouble(storeMap['longitude'] ?? storeMap['lon']);
          
          // Calculate distance from user location
          final distance = _calculateDistanceKm(lat, lon, storeLat, storeLon);
          storeMap['distance_km'] = distance;
          
          return storeMap;
        }).toList();
        
        // Sort by distance
        storesWithDistance.sort((a, b) {
          final distA = (a['distance_km'] ?? 99999.0) as double;
          final distB = (b['distance_km'] ?? 99999.0) as double;
          return distA.compareTo(distB);
        });
        
        return List<Map<String, dynamic>>.from(storesWithDistance);
      } else {
        debugPrint('❌ Stores API error: ${response.statusCode}');
        return [];
      }
      
    } on DioException catch (e) {
      debugPrint('Stores API network error: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Stores API unexpected error: $e');
      return [];
    }
  }
  
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
  
  // Safe conversion to double from various types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    debugPrint('⚠️ Failed to parse as double: $value (${value.runtimeType})');
    return 0.0;
  }
  
  // Calculate distance between two coordinates in kilometers
  static double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000.0;
  }
  
  static Map<String, dynamic> convertApiStoreToAppStore(Map<String, dynamic> apiStore) {
    // API format: {"store_id": "5865", "store_name": "Aldi Unlisted Store", "latitude": "-37.815916", "longitude": "145.223147", ...}
    
    final extra = apiStore['extra'] as Map<String, dynamic>? ?? {};
    final name = apiStore['store_name'] ?? apiStore['name'] ?? 'Unknown Store';
    final chain = name.toString().split(' ').first; // Extract first word as chain name
    
    return {
      'id': apiStore['store_id']?.toString() ?? apiStore['id']?.toString() ?? 'unknown',
      'name': name,
      'chain': chain,
      'address': apiStore['address_1'] ?? extra['address_1'] ?? '',
      'suburb': apiStore['suburb'] ?? extra['suburb'] ?? '',
      'city': apiStore['city'] ?? extra['city'] ?? '',
      'postcode': apiStore['postcode'] ?? extra['postcode'] ?? '',
      'state': apiStore['state'] ?? extra['state'] ?? '',
      'country': apiStore['country'] ?? extra['country'] ?? '',
      'latitude': _parseDouble(apiStore['latitude'] ?? apiStore['lat']),
      'longitude': _parseDouble(apiStore['longitude'] ?? apiStore['lon']),
      'distance': _parseDouble(apiStore['distance_km']),
    };
  }
  
  // Test the stores API connection
  static Future<bool> testStoresApi() async {
    try {
      debugPrint('🔍 API TEST: Testing stores API connection...');
      debugPrint('🔍 API TEST: URL: $_storesApiUrl');
      
      // Get user ID from auth - this is what we send as 'token' to the stores API
      final userId = await AuthTokenManager.getUserId();
      final token = userId ?? 'RDAS'; // Use user ID as token, fallback to RDAS for demo
      
      debugPrint('🔍 API TEST: Using token (user_id): $token');
      
      final response = await _dio.post(
        _storesApiUrl,
        data: {
          'token': token,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      debugPrint('🔍 API TEST: Response status: ${response.statusCode}');
      debugPrint('🔍 API TEST: Response data type: ${response.data.runtimeType}');
      
      if (response.data != null) {
        final dataStr = response.data.toString();
        debugPrint('🔍 API TEST: Response preview: ${dataStr.substring(0, math.min(200, dataStr.length))}...');
      }
      
      final isSuccess = response.statusCode == 200;
      debugPrint('🔍 API TEST: Test result: $isSuccess');
      return isSuccess;
    } catch (e) {
      debugPrint('🔍 API TEST: Exception occurred: $e');
      debugPrint('🔍 API TEST: Exception type: ${e.runtimeType}');
      return false;
    }
  }
}
