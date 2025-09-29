// Store Service - Integrates with your nearest stores API
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

class StoreService {
  static const String _storesApiUrl = 'https://api-nearest-stores-951551492434.australia-southeast1.run.app/';
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
      
      // Make API call to your stores endpoint
      final response = await _dio.post(
        _storesApiUrl,
        data: {
          'lat': lat,
          'lon': lon,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('✅ API Response received: ${data.runtimeType}');
        
        if (data is Map<String, dynamic> && data.containsKey('results')) {
          // API returns {"count": 11, "results": [...]}
          final results = data['results'];
          if (results is List) {
            debugPrint('✅ Found ${results.length} stores in results');
            return List<Map<String, dynamic>>.from(results);
          }
        }
        
        debugPrint('❌ Unexpected API response format');
        debugPrint('Response: $data');
        return [];
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
  
  static Map<String, dynamic> convertApiStoreToAppStore(Map<String, dynamic> apiStore) {
    // API format: {"id": 37013, "name": "New World New Plymouth", "lat": -39.0578, "lon": 174.0777, "distance_km": 2112.0478, "extra": {"address_1": "78 Courtenay Street", "city": "New Plymouth"}}
    
    final extra = apiStore['extra'] as Map<String, dynamic>? ?? {};
    final name = apiStore['name'] ?? 'Unknown Store';
    final chain = name.toString().split(' ').first; // Extract "New World" from "New World New Plymouth"
    
    return {
      'id': apiStore['id']?.toString() ?? 'unknown',
      'name': name,
      'chain': chain,
      'address': extra['address_1'] ?? '',
      'suburb': extra['suburb'] ?? '',
      'city': extra['city'] ?? '',
      'postcode': extra['postcode'] ?? '',
      'state': extra['state'] ?? '',
      'latitude': (apiStore['lat'] ?? 0.0).toDouble(),
      'longitude': (apiStore['lon'] ?? 0.0).toDouble(),
      'distance': (apiStore['distance_km'] ?? 0.0).toDouble(),
    };
  }
  
  // Test the stores API connection
  static Future<bool> testStoresApi() async {
    try {
      debugPrint('🔍 API TEST: Testing stores API connection...');
      debugPrint('🔍 API TEST: URL: $_storesApiUrl');
      debugPrint('🔍 API TEST: Request data: {"lat": -32.9273, "lon": 151.7817}');
      
      final response = await _dio.post(
        _storesApiUrl,
        data: {
          'lat': -32.9273,
          'lon': 151.7817,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      debugPrint('🔍 API TEST: Response status: ${response.statusCode}');
      debugPrint('🔍 API TEST: Response data type: ${response.data.runtimeType}');
      debugPrint('🔍 API TEST: Response data: ${response.data.toString().substring(0, math.min(200, response.data.toString().length))}...');
      
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
