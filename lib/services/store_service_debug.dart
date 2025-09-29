// Enhanced Store Service with detailed debugging
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

class StoreServiceDebug {
  static const String _storesApiUrl = 'https://api-nearest-stores-951551492434.australia-southeast1.run.app/';
  static final Dio _dio = Dio();
  
  // ENHANCED API TEST WITH COMPREHENSIVE LOGGING
  static Future<bool> testStoresApiEnhanced() async {
    try {
      debugPrint('🔍 ENHANCED API TEST: ========== STARTING ==========');
      debugPrint('🔍 ENHANCED API TEST: URL: $_storesApiUrl');
      debugPrint('🔍 ENHANCED API TEST: Current time: ${DateTime.now()}');
      
      // Test network connectivity first
      debugPrint('🔍 ENHANCED API TEST: Testing basic connectivity...');
      
      final response = await _dio.post(
        _storesApiUrl,
        data: {
          'lat': -32.9273,
          'lon': 151.7817,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          validateStatus: (status) => true, // Accept any status code
        ),
      );
      
      debugPrint('🔍 ENHANCED API TEST: Response received!');
      debugPrint('🔍 ENHANCED API TEST: Status code: ${response.statusCode}');
      debugPrint('🔍 ENHANCED API TEST: Status message: ${response.statusMessage}');
      debugPrint('🔍 ENHANCED API TEST: Headers: ${response.headers}');
      debugPrint('🔍 ENHANCED API TEST: Data type: ${response.data.runtimeType}');
      
      if (response.data != null) {
        final dataStr = response.data.toString();
        final previewLength = math.min(500, dataStr.length);
        debugPrint('🔍 ENHANCED API TEST: Data preview (${previewLength}/${dataStr.length} chars): ${dataStr.substring(0, previewLength)}');
      } else {
        debugPrint('🔍 ENHANCED API TEST: Response data is null');
      }
      
      final isSuccess = response.statusCode == 200;
      debugPrint('🔍 ENHANCED API TEST: Final result: $isSuccess');
      debugPrint('🔍 ENHANCED API TEST: ========== COMPLETE ==========');
      
      return isSuccess;
      
    } on DioException catch (e) {
      debugPrint('🔍 ENHANCED API TEST: ========== DIO EXCEPTION ==========');
      debugPrint('🔍 ENHANCED API TEST: DioException type: ${e.type}');
      debugPrint('🔍 ENHANCED API TEST: Error message: ${e.message}');
      debugPrint('🔍 ENHANCED API TEST: Request options: ${e.requestOptions}');
      
      if (e.response != null) {
        debugPrint('🔍 ENHANCED API TEST: Error response status: ${e.response?.statusCode}');
        debugPrint('🔍 ENHANCED API TEST: Error response data: ${e.response?.data}');
      } else {
        debugPrint('🔍 ENHANCED API TEST: No response received (network/timeout issue)');
      }
      
      debugPrint('🔍 ENHANCED API TEST: Stack trace: ${e.stackTrace}');
      debugPrint('🔍 ENHANCED API TEST: ========== END EXCEPTION ==========');
      return false;
      
    } catch (e, stackTrace) {
      debugPrint('🔍 ENHANCED API TEST: ========== GENERAL EXCEPTION ==========');
      debugPrint('🔍 ENHANCED API TEST: Exception type: ${e.runtimeType}');
      debugPrint('🔍 ENHANCED API TEST: Exception message: $e');
      debugPrint('🔍 ENHANCED API TEST: Stack trace: $stackTrace');
      debugPrint('🔍 ENHANCED API TEST: ========== END EXCEPTION ==========');
      return false;
    }
  }
  
  // TEST THE EXACT SAME API CALL USED BY StoreService.getNearestStores()
  static Future<bool> testExactStoreApiCall() async {
    try {
      debugPrint('🎯 EXACT API TEST: ========== TESTING EXACT STORE CALL ==========');
      
      // Use the exact same coordinates
      const lat = -32.9273;
      const lon = 151.7817;
      
      debugPrint('🎯 EXACT API TEST: Calling exact same API as StoreService.getNearestStores()');
      debugPrint('🎯 EXACT API TEST: URL: $_storesApiUrl');
      debugPrint('🎯 EXACT API TEST: Lat: $lat, Lon: $lon');
      
      final response = await _dio.post(
        _storesApiUrl,
        data: {
          'lat': lat,
          'lon': lon,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          validateStatus: (status) => true, // Accept any status to see what we get
        ),
      );
      
      debugPrint('🎯 EXACT API TEST: Response received!');
      debugPrint('🎯 EXACT API TEST: Status: ${response.statusCode}');
      debugPrint('🎯 EXACT API TEST: Status Message: ${response.statusMessage}');
      debugPrint('🎯 EXACT API TEST: Headers: ${response.headers}');
      
      if (response.statusCode == 200 && response.data != null) {
        // Try to parse as JSON
        final dynamic data = response.data;
        debugPrint('🎯 EXACT API TEST: Response data type: ${data.runtimeType}');
        debugPrint('🎯 EXACT API TEST: Full response data: $data');
        
        if (data is List) {
          debugPrint('🎯 EXACT API TEST: ✅ Response is a List with ${data.length} items');
          if (data.isNotEmpty) {
            debugPrint('🎯 EXACT API TEST: First store data: ${data.first}');
            debugPrint('🎯 EXACT API TEST: All store data: $data');
            return true;
          } else {
            debugPrint('🎯 EXACT API TEST: ⚠️ Response is empty list - NO STORES IN DATABASE?');
            return false;
          }
        } else if (data is Map) {
          debugPrint('🎯 EXACT API TEST: ℹ️ Response is a Map: $data');
          // Check if it has stores data
          if (data.containsKey('stores') || data.containsKey('data')) {
            final stores = data['stores'] ?? data['data'];
            debugPrint('🎯 EXACT API TEST: Found nested stores data: $stores');
            if (stores is List && stores.isNotEmpty) {
              debugPrint('🎯 EXACT API TEST: ✅ Found stores in nested data: ${stores.length} items');
              return true;
            } else {
              debugPrint('🎯 EXACT API TEST: ⚠️ Nested stores data is empty or not a list');
              return false;
            }
          } else {
            debugPrint('🎯 EXACT API TEST: ⚠️ Map response but no stores/data key found');
            debugPrint('🎯 EXACT API TEST: Available keys: ${data.keys.toList()}');
            return false;
          }
        } else {
          debugPrint('🎯 EXACT API TEST: ❌ Unexpected response format: $data');
          debugPrint('🎯 EXACT API TEST: Response as string: ${data.toString()}');
          return false;
        }
      } else {
        debugPrint('🎯 EXACT API TEST: ❌ Bad response status: ${response.statusCode}');
        if (response.data != null) {
          debugPrint('🎯 EXACT API TEST: Error response data: ${response.data}');
          debugPrint('🎯 EXACT API TEST: Error response type: ${response.data.runtimeType}');
        } else {
          debugPrint('🎯 EXACT API TEST: No response data received');
        }
        return false;
      }
      
    } on DioException catch (e) {
      debugPrint('🎯 EXACT API TEST: ❌ DIO Exception: ${e.type}');
      debugPrint('🎯 EXACT API TEST: Error message: ${e.message}');
      if (e.response != null) {
        debugPrint('🎯 EXACT API TEST: Error response status: ${e.response?.statusCode}');
        debugPrint('🎯 EXACT API TEST: Error response data: ${e.response?.data}');
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint('🎯 EXACT API TEST: ❌ General Exception: $e');
      debugPrint('🎯 EXACT API TEST: Stack: $stackTrace');
      return false;
    }
  }
}
