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
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data is List) {
          // API returns array of stores
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map<String, dynamic>) {
          // API returns object - check for different possible keys
          if (data.containsKey('results')) {
            // Your API uses 'results' key!
            return List<Map<String, dynamic>>.from(data['results']);
          } else if (data.containsKey('stores')) {
            // Alternative: 'stores' key
            return List<Map<String, dynamic>>.from(data['stores']);
          } else if (data.containsKey('data')) {
            // Alternative: 'data' key
            return List<Map<String, dynamic>>.from(data['data']);
          } else {
            debugPrint('🔍 STORE SERVICE: Map response with unexpected keys: ${data.keys.toList()}');
            debugPrint('🔍 STORE SERVICE: Full response: $data');
            return [];
          }
        } else {
          debugPrint('Unexpected API response format: $data');
          return [];
        }
      } else {
        debugPrint('Stores API error: ${response.statusCode}');
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
    // Debug the incoming store data
    debugPrint('🔍 CONVERT: Converting API store: $apiStore');
    
    return {
      'id': apiStore['id']?.toString() ?? apiStore['store_id']?.toString() ?? 'unknown',
      'name': apiStore['name'] ?? apiStore['store_name'] ?? 'Unknown Store',
      'chain': apiStore['chain'] ?? apiStore['brand'] ?? apiStore['store_name']?.toString().split(' ').first ?? 'Unknown',
      'address': apiStore['address'] ?? apiStore['address_1'] ?? '',
      'suburb': apiStore['suburb'] ?? apiStore['locality'] ?? apiStore['city'] ?? '',
      'city': apiStore['city'] ?? apiStore['suburb'] ?? '',
      'postcode': apiStore['postcode'] ?? apiStore['postal_code'] ?? '',
      'state': apiStore['state'] ?? apiStore['region'] ?? '',
      'latitude': (apiStore['latitude'] ?? apiStore['lat'] ?? 0.0).toDouble(),
      'longitude': (apiStore['longitude'] ?? apiStore['lon'] ?? 0.0).toDouble(),
      'distance': (apiStore['distance'] ?? apiStore['distance_km'] ?? 0.0).toDouble(),
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
