import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Manages authentication tokens for API requests
class AuthTokenManager {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  
  static String? _cachedToken;
  static String? _cachedUserId;
  static String? _cachedUserName;
  
  /// Save authentication credentials after login
  static Future<void> saveAuthData({
    required String token,
    required String userId,
    required String userName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userNameKey, userName);
      
      _cachedToken = token;
      _cachedUserId = userId;
      _cachedUserName = userName;
      
      debugPrint('✅ Auth data saved: userId=$userId');
    } catch (e) {
      debugPrint('❌ Failed to save auth data: $e');
    }
  }
  
  /// Get the current auth token
  static Future<String?> getToken() async {
    if (_cachedToken != null) {
      return _cachedToken;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(_tokenKey);
      return _cachedToken;
    } catch (e) {
      debugPrint('❌ Failed to get token: $e');
      return null;
    }
  }
  
  /// Get the current user ID
  static Future<String?> getUserId() async {
    if (_cachedUserId != null) {
      return _cachedUserId;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedUserId = prefs.getString(_userIdKey);
      return _cachedUserId;
    } catch (e) {
      debugPrint('❌ Failed to get user ID: $e');
      return null;
    }
  }
  
  /// Get the current user name
  static Future<String?> getUserName() async {
    if (_cachedUserName != null) {
      return _cachedUserName;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedUserName = prefs.getString(_userNameKey);
      return _cachedUserName;
    } catch (e) {
      debugPrint('❌ Failed to get user name: $e');
      return null;
    }
  }
  
  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  /// Clear all authentication data (logout)
  static Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userNameKey);
      
      _cachedToken = null;
      _cachedUserId = null;
      _cachedUserName = null;
      
      debugPrint('✅ Auth data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear auth data: $e');
    }
  }
}
