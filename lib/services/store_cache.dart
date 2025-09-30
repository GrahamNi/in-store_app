import 'package:flutter/foundation.dart';
import 'database_helper.dart';

/// Singleton cache for store data with PERSISTENT storage via SQLite
class StoreCache {
  static final StoreCache _instance = StoreCache._internal();
  factory StoreCache() => _instance;
  StoreCache._internal();
  
  final _dbHelper = DatabaseHelper();
  
  // In-memory cache (fast access)
  List<Map<String, dynamic>>? _memoryCache;
  DateTime? _lastUpdateTime;
  double? _userLatitude;
  double? _userLongitude;
  
  /// Check if cache is valid
  bool get isCacheValid {
    if (_memoryCache == null || _lastUpdateTime == null) {
      return false;
    }
    
    final age = DateTime.now().difference(_lastUpdateTime!);
    return age.inHours < 24; // Cache expires after 24 hours
  }
  
  /// Get cached stores (loads from DB if memory cache is empty)
  Future<List<Map<String, dynamic>>?> get cachedStores async {
    // Try memory cache first
    if (_memoryCache != null && isCacheValid) {
      debugPrint('✅ CACHE: Using memory cache (${_memoryCache!.length} stores)');
      return _memoryCache;
    }
    
    // Load from database
    debugPrint('📂 CACHE: Loading from database...');
    final dbStores = await _dbHelper.loadStoresCache();
    
    if (dbStores != null && dbStores.isNotEmpty) {
      // Load user location from DB
      final (lat, lon) = await _dbHelper.getCachedUserLocation();
      
      // Update memory cache
      _memoryCache = dbStores;
      _userLatitude = lat;
      _userLongitude = lon;
      _lastUpdateTime = DateTime.now();
      
      debugPrint('✅ CACHE: Loaded ${dbStores.length} stores from database');
      debugPrint('📍 CACHE: User location from DB: $lat, $lon');
      return dbStores;
    }
    
    debugPrint('⚠️ CACHE: No stores in database');
    return null;
  }
  
  /// Get user location
  (double?, double?) get userLocation => (_userLatitude, _userLongitude);
  
  /// Update cache with new store data (saves to BOTH memory AND database)
  Future<void> updateCache(
    List<Map<String, dynamic>> stores, {
    double? latitude,
    double? longitude,
  }) async {
    // Update memory cache
    _memoryCache = stores;
    _lastUpdateTime = DateTime.now();
    _userLatitude = latitude;
    _userLongitude = longitude;
    
    debugPrint('✅ CACHE: Stored ${stores.length} stores in MEMORY');
    debugPrint('📍 CACHE: User location: $latitude, $longitude');
    
    // Save to database (persistent storage)
    try {
      await _dbHelper.saveStoresCache(
        stores,
        userLatitude: latitude,
        userLongitude: longitude,
      );
      debugPrint('💾 CACHE: Saved ${stores.length} stores to DATABASE (persistent)');
    } catch (e) {
      debugPrint('❌ CACHE: Failed to save to database: $e');
    }
  }
  
  /// Clear the cache (memory AND database)
  Future<void> clear() async {
    _memoryCache = null;
    _lastUpdateTime = null;
    _userLatitude = null;
    _userLongitude = null;
    
    try {
      await _dbHelper.clearStoresCache();
      debugPrint('🗑️ CACHE: Cleared store cache (memory + database)');
    } catch (e) {
      debugPrint('❌ CACHE: Failed to clear database: $e');
    }
  }
  
  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    final dbStores = await _dbHelper.loadStoresCache();
    final (dbLat, dbLon) = await _dbHelper.getCachedUserLocation();
    
    return {
      'memory_stores': _memoryCache?.length ?? 0,
      'database_stores': dbStores?.length ?? 0,
      'last_update': _lastUpdateTime?.toIso8601String(),
      'cache_valid': isCacheValid,
      'memory_location': _userLatitude != null ? '($_userLatitude, $_userLongitude)' : 'unknown',
      'database_location': dbLat != null ? '($dbLat, $dbLon)' : 'unknown',
    };
  }
}
