import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'database_helper.dart';
import 'progress_ping_service.dart';

class AuthService {
  static const String authUrl = 'https://auth-users-951551492434.europe-west1.run.app';

  static Future<AuthResponse> authenticate(String username, String password) async {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      throw AuthException('Username and password are required');
    }

    try {
      final response = await http.post(
        Uri.parse(authUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw AuthException('Authentication request timed out'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        debugPrint('🔐 AUTH RESPONSE: $jsonResponse');
        
        // CRITICAL: Check if authentication actually succeeded
        final authSuccess = jsonResponse['auth'] == true;
        
        if (!authSuccess) {
          debugPrint('❌ AUTH FAILED: API returned auth=false');
          debugPrint('❌ Response: $jsonResponse');
          throw AuthException('Invalid username or password');
        }
        
        debugPrint('✅ AUTH: auth=true, authentication succeeded');
        
        final authResponse = AuthResponse.fromJson(jsonResponse);
        
        // Check if this is a different user
        final prefs = await SharedPreferences.getInstance();
        final previousUserId = prefs.getString('user_id');
        final isDifferentUser = previousUserId != null && previousUserId != authResponse.userId;
        
        if (isDifferentUser) {
          debugPrint('🔄 USER CHANGE: Previous user: $previousUserId, New user: ${authResponse.userId}');
          debugPrint('🗑️ Clearing store cache for different user...');
          
          // Import DatabaseHelper at top of file if not already imported
          try {
            final db = DatabaseHelper();
            await db.clearStoresCache();
            debugPrint('✅ Store cache cleared for user change');
          } catch (e) {
            debugPrint('⚠️ Failed to clear store cache: $e');
            // Don't fail authentication if cache clear fails
          }
        }
        
        // Store authentication data
        await prefs.setString('user_id', authResponse.userId);
        await prefs.setString('auth_token', authResponse.token ?? '');
        
        debugPrint('✅ AUTH: Successfully authenticated user ${authResponse.userId}');
        debugPrint('✅ AUTH SUCCESS: AuthResponse(userId: ${authResponse.userId}, service: ${authResponse.service}, profile: ${authResponse.profile}, isProfileA: ${authResponse.isProfileA})');
        debugPrint('🔑 AUTH DATA:');
        debugPrint('   - user_id: ${authResponse.userId}');
        debugPrint('   - token: ${authResponse.token}');
        debugPrint('   - service: ${authResponse.service}');
        debugPrint('   - profile: ${authResponse.profile}');
        debugPrint('   - name: ${authResponse.name}');
        debugPrint('   - isProfileA: ${authResponse.isProfileA}');
        
        if (authResponse.userId == 'unknown') {
          debugPrint('❌ WARNING: Auth returned user_id="unknown"');
          throw AuthException('Authentication succeeded but no user ID returned');
        }
        
        debugPrint('✅ Auth data saved: userId=${authResponse.userId}');
        debugPrint('🔐 AUTH TOKEN: Saved for API requests');
        
        // START: Progress ping service for portal tracking
        ProgressPingService().startPeriodicPing();
        debugPrint('📊 PROGRESS PING: Service started');
        
        return authResponse;
      } else {
        throw AuthException('Authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Authentication error: $e');
    }
  }

  static Future<void> logout() async {
    // STOP: Progress ping service before logout
    ProgressPingService().stopPeriodicPing();
    debugPrint('📊 PROGRESS PING: Service stopped');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('auth_token');
    debugPrint('✅ AUTH: User logged out');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_id');
  }
}

class AuthResponse {
  final String userId;
  final String? token;
  final String? service;
  final String? profile;
  final String? name;
  final String? email;
  final Map<String, dynamic> rawData;

  AuthResponse({
    required this.userId,
    this.token,
    this.service,
    this.profile,
    this.name,
    this.email,
    required this.rawData,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('🔐 AUTH PARSE: Raw JSON: $json');
    debugPrint('❌ AUTH PARSE: Available keys: ${json.keys.toList()}');
    
    // CRITICAL FIX: Check 'token' field FIRST - that's where your API puts the user_id
    String userId = 'unknown';
    
    if (json.containsKey('token') && json['token'] != null) {
      userId = json['token'].toString();
      debugPrint('🔐 AUTH PARSE: Found userId in "token": $userId');
    } else if (json.containsKey('username') && json['username'] != null) {
      userId = json['username'].toString();
      debugPrint('🔐 AUTH PARSE: Found userId in "username": $userId');
    } else if (json.containsKey('user_id') && json['user_id'] != null) {
      userId = json['user_id'].toString();
      debugPrint('🔐 AUTH PARSE: Found userId in "user_id": $userId');
    } else if (json.containsKey('userId') && json['userId'] != null) {
      userId = json['userId'].toString();
      debugPrint('🔐 AUTH PARSE: Found userId in "userId": $userId');
    } else if (json.containsKey('id') && json['id'] != null) {
      userId = json['id'].toString();
      debugPrint('🔐 AUTH PARSE: Found userId in "id": $userId');
    } else if (json.containsKey('email') && json['email'] != null) {
      userId = json['email'].toString();
      debugPrint('🔐 AUTH PARSE: Using email as userId: $userId');
    } else {
      debugPrint('❌ AUTH PARSE: NO USER ID FOUND IN RESPONSE!');
    }

    return AuthResponse(
      userId: userId,
      token: json['token']?.toString() ?? json['auth_token']?.toString(),
      service: json['service']?.toString(),
      profile: json['profile']?.toString(),
      name: json['name']?.toString() ?? json['username']?.toString(),
      email: json['email']?.toString(),
      rawData: json,
    );
  }

  bool get isProfileA {
    if (service != null) {
      final s = service!.toLowerCase();
      return s == 'a' || s == 'instore' || s == 'in-store' || s == 'profile_a';
    }
    if (profile != null) {
      final p = profile!.toLowerCase();
      return p == 'a' || p == 'instore' || p == 'in-store' || p == 'profile_a';
    }
    return true;
  }

  @override
  String toString() {
    return 'AuthResponse(userId: $userId, service: $service, profile: $profile, isProfileA: $isProfileA)';
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}