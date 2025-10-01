// Store Cache Manager - Handles offline-first store data
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'store_service.dart';

class StoreCacheManager {
  static const String _cacheKey = 'cached_stores';
  static const String _lastUpdateKey = 'stores_last_update';
  static const Duration _cacheValidDuration = Duration(hours: 1);

  // Download ALL stores on first sign-in
  static Future<bool> downloadAndCacheStores({
    double? latitude,
    double? longitude,
  }) async {
    try {
      debugPrint('📥 STORE CACHE: Downloading stores from API...');
      
      // Call API to get stores (already returns List<Store>)
      final stores = await StoreService.getNearestStores(
        latitude: latitude ?? -32.9273,
        longitude: longitude ?? 151.7817,
      );
      
      if (stores.isEmpty) {
        debugPrint('❌ STORE CACHE: API returned no stores');
        return false;
      }
      
      debugPrint('✅ STORE CACHE: Downloaded ${stores.length} stores');
      
      // ✅ Convert List<Store> to List<Map<String, dynamic>>
      final storesJson = stores.map((store) => store.toJson()).toList();
      
      // Save to cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(storesJson));
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      
      debugPrint('💾 STORE CACHE: Cached ${stores.length} stores locally');
      return true;
      
    } catch (e) {
      debugPrint('❌ STORE CACHE: Download failed: $e');
      return false;
    }
  }
  
  // Get cached stores (for offline use)
  static Future<List<Map<String, dynamic>>> getCachedStores() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      
      if (cachedData == null) {
        debugPrint('⚠️ STORE CACHE: No cached stores found');
        return [];
      }
      
      final List<dynamic> decoded = jsonDecode(cachedData);
      final stores = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      
      debugPrint('📦 STORE CACHE: Loaded ${stores.length} stores from cache');
      return stores;
      
    } catch (e) {
      debugPrint('❌ STORE CACHE: Failed to load cache: $e');
      return [];
    }
  }
  
  // Check if cache needs update (> 1 hour old)
  static Future<bool> needsUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdateStr = prefs.getString(_lastUpdateKey);
      
      if (lastUpdateStr == null) {
        debugPrint('⏰ STORE CACHE: No last update time - needs update');
        return true;
      }
      
      final lastUpdate = DateTime.parse(lastUpdateStr);
      final timeSinceUpdate = DateTime.now().difference(lastUpdate);
      final needsUpdate = timeSinceUpdate > _cacheValidDuration;
      
      debugPrint('⏰ STORE CACHE: Last update: ${timeSinceUpdate.inMinutes}m ago, needs update: $needsUpdate');
      return needsUpdate;
      
    } catch (e) {
      debugPrint('❌ STORE CACHE: Error checking update time: $e');
      return true;
    }
  }
  
  // Check for updates and download if needed (called when opening store screen)
  static Future<void> checkAndUpdateIfNeeded({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final needsUpdate = await StoreCacheManager.needsUpdate();
      if (!needsUpdate) {
        debugPrint('✅ STORE CACHE: Cache is fresh, no update needed');
        return;
      }
      
      debugPrint('🔄 STORE CACHE: Cache expired, attempting update...');
      
      final success = await downloadAndCacheStores(
        latitude: latitude,
        longitude: longitude,
      );
      
      if (success) {
        debugPrint('✅ STORE CACHE: Successfully updated stores');
      } else {
        debugPrint('⚠️ STORE CACHE: Update failed, using existing cache');
      }
      
    } catch (e) {
      debugPrint('❌ STORE CACHE: Update check failed: $e');
    }
  }
  
  // Clear cache (for testing/logout)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_lastUpdateKey);
    debugPrint('🗑️ STORE CACHE: Cache cleared');
  }
}
