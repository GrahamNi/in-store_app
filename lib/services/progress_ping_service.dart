import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_helper.dart';

/// Progress Ping Service - Sends lightweight telemetry to portal for real-time tracking
/// 
/// This service sends periodic "heartbeat" pings to the portal backend with:
/// - Current session information
/// - Queue statistics (pending/uploaded images)
/// - Device status (battery, storage, network)
/// - User activity tracking
/// 
/// Portal uses this data to:
/// - Track user progress in real-time
/// - Detect stuck/problematic devices
/// - Monitor upload queue health
/// - Generate activity reports
class ProgressPingService {
  // API endpoint for progress pings
  static const String pingUrl = 'https://progress-ping-951551492434.europe-west1.run.app';
  
  // Ping interval - every 5 minutes
  static const Duration pingInterval = Duration(minutes: 5);
  
  // Singleton pattern
  static final ProgressPingService _instance = ProgressPingService._internal();
  factory ProgressPingService() => _instance;
  ProgressPingService._internal();
  
  Timer? _periodicTimer;
  bool _isRunning = false;
  String? _currentSessionId;
  String? _currentStoreId;
  String? _currentStoreName;
  
  /// Start periodic progress pinging
  /// Call this after successful login
  void startPeriodicPing() {
    if (_isRunning) {
      debugPrint('⚠️ PING: Already running');
      return;
    }
    
    debugPrint('🔔 PING: Starting periodic progress pings (every ${pingInterval.inMinutes} minutes)');
    
    _isRunning = true;
    
    // Send immediate ping
    sendProgressPing();
    
    // Start periodic timer
    _periodicTimer = Timer.periodic(pingInterval, (_) {
      sendProgressPing();
    });
  }
  
  /// Stop periodic progress pinging
  /// Call this on logout
  void stopPeriodicPing() {
    if (!_isRunning) return;
    
    debugPrint('🔕 PING: Stopping periodic progress pings');
    
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _isRunning = false;
    
    // Send final ping before stopping
    sendProgressPing(isFinal: true);
  }
  
  /// Update current session information
  /// Call this when a new session starts
  void updateSession({
    required String sessionId,
    required String storeId,
    required String storeName,
  }) {
    _currentSessionId = sessionId;
    _currentStoreId = storeId;
    _currentStoreName = storeName;
    
    debugPrint('🔔 PING: Session updated - $storeName');
    
    // Send immediate ping with new session info
    sendProgressPing();
  }
  
  /// Clear current session
  /// Call this when session ends
  void clearSession() {
    debugPrint('🔔 PING: Session cleared');
    
    // Send final ping before clearing
    sendProgressPing(isFinal: true);
    
    _currentSessionId = null;
    _currentStoreId = null;
    _currentStoreName = null;
  }
  
  /// Send immediate progress ping (force update)
  /// Call this after important events (capture, upload complete, etc.)
  Future<void> sendProgressPing({bool isFinal = false}) async {
    try {
      debugPrint('📤 PING: Preparing progress ping...');
      
      // Gather all data
      final payload = await _buildPayload(isFinal: isFinal);
      
      debugPrint('📤 PING: Sending payload (${jsonEncode(payload).length} bytes)');
      
      // Send with timeout (don't block user if network is slow)
      final response = await http.post(
        Uri.parse(pingUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ PING: Timeout (network slow but non-critical)');
          throw TimeoutException('Progress ping timeout');
        },
      );
      
      if (response.statusCode == 200) {
        debugPrint('✅ PING: Successfully sent (${response.statusCode})');
      } else {
        debugPrint('⚠️ PING: Server returned ${response.statusCode}');
      }
      
    } catch (e) {
      // Fail silently - don't bother the user with ping failures
      debugPrint('⚠️ PING: Failed (non-critical): $e');
    }
  }
  
  /// Build the progress ping payload
  Future<Map<String, dynamic>> _buildPayload({bool isFinal = false}) async {
    final db = DatabaseHelper();
    final prefs = await SharedPreferences.getInstance();
    
    // Get user info
    final userId = prefs.getString('user_id') ?? 'unknown';
    final deviceId = await _getDeviceId();
    
    // Get session stats if session is active
    Map<String, dynamic>? sessionData;
    Map<String, dynamic>? progressData;
    
    if (_currentSessionId != null) {
      final stats = await db.getSessionStats(_currentSessionId!);
      final offLocationCount = await db.getOffLocationCount(_currentSessionId!);
      
      sessionData = {
        'session_id': _currentSessionId,
        'store_id': _currentStoreId,
        'store_name': _currentStoreName,
        'is_active': !isFinal,
      };
      
      progressData = {
        'locations_visited': stats['locations_visited'] ?? 0,
        'aisles_visited': stats['aisles_visited'] ?? 0,
        'off_location_captures': offLocationCount,
        'images_in_queue': stats['queue_count'] ?? 0,
        'images_uploaded': stats['uploaded_count'] ?? 0,
        'total_captures': stats['total_captures'] ?? 0,
      };
    } else {
      // No active session - just send queue stats
      final queueCount = await db.getQueueCount();
      
      progressData = {
        'images_in_queue': queueCount,
        'images_uploaded': 0,
        'total_captures': 0,
      };
    }
    
    // Get device status
    final deviceStatus = await _getDeviceStatus();
    
    // Build final payload
    return {
      'user_id': userId,
      'device_id': deviceId,
      'timestamp': DateTime.now().toIso8601String(),
      'is_final': isFinal,
      if (sessionData != null) 'session': sessionData,
      'progress': progressData,
      'device_status': deviceStatus,
    };
  }
  
  /// Get device ID (persistent across app restarts)
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if we already have a device ID
    String? deviceId = prefs.getString('device_id');
    
    if (deviceId == null) {
      // Generate new device ID from device info
      final deviceInfo = DeviceInfoPlugin();
      
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceId = 'android_${androidInfo.id}';
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = 'ios_${iosInfo.identifierForVendor}';
        } else {
          deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
        }
        
        // Save for future use
        await prefs.setString('device_id', deviceId);
      } catch (e) {
        debugPrint('⚠️ PING: Failed to get device ID: $e');
        deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      }
    }
    
    return deviceId;
  }
  
  /// Get current device status (battery, storage, network)
  Future<Map<String, dynamic>> _getDeviceStatus() async {
    final battery = Battery();
    final connectivity = Connectivity();
    
    int? batteryLevel;
    String networkType = 'unknown';
    
    try {
      batteryLevel = await battery.batteryLevel;
    } catch (e) {
      debugPrint('⚠️ PING: Failed to get battery level: $e');
    }
    
    try {
      final connectivityResult = await connectivity.checkConnectivity();
      networkType = connectivityResult.first.toString().split('.').last;
    } catch (e) {
      debugPrint('⚠️ PING: Failed to get network type: $e');
    }
    
    return {
      'battery_level': batteryLevel,
      'network_type': networkType,
      // TODO: Add storage_available_mb when needed
    };
  }
}
