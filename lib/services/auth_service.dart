import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;

class AuthService {
  static const String authUrl = 'https://auth-users-951551492434.europe-west1.run.app';

  static Future<AuthResponse> authenticate(String username, String password) async {
    // Basic validation
    if (username.trim().isEmpty || password.trim().isEmpty) {
      throw AuthException('Username and password are required');
    }
    
    try {
      debugPrint('🔐 AUTH: Calling authentication API...');
      debugPrint('🔐 AUTH: Username: $username');
      
      final response = await http.post(
        Uri.parse(authUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw AuthException('Authentication request timed out');
        },
      );

      debugPrint('🔐 AUTH: Response status: ${response.statusCode}');
      debugPrint('🔐 AUTH: Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          
          // Validate that we have meaningful data
          if (data is! Map<String, dynamic>) {
            throw AuthException('Invalid response format from server');
          }
          
          // Check for error messages in the response
          if (data.containsKey('error')) {
            throw AuthException(data['error'].toString());
          }
          
          if (data.containsKey('message') && data['message'].toString().toLowerCase().contains('error')) {
            throw AuthException(data['message'].toString());
          }
          
          final authResponse = AuthResponse.fromJson(data);
          
          // Validate we got essential data
          if (authResponse.userId == 'unknown' && authResponse.token == null) {
            throw AuthException('Invalid credentials - no user data returned');
          }
          
          debugPrint('🔐 AUTH: Successfully authenticated user ${authResponse.userId}');
          debugPrint('🔐 AUTH: Token received: ${authResponse.token ?? "null"}');
          debugPrint('🔐 AUTH: Service: ${authResponse.service ?? "null"}');
          debugPrint('🔐 AUTH: Profile: ${authResponse.profile ?? "null"}');
          debugPrint('🔐 AUTH: Is Profile A: ${authResponse.isProfileA}');
          return authResponse;
          
        } catch (e) {
          if (e is AuthException) rethrow;
          throw AuthException('Failed to parse authentication response: $e');
        }
      } else if (response.statusCode == 401) {
        throw AuthException('Invalid username or password');
      } else if (response.statusCode == 403) {
        throw AuthException('Access forbidden - account may be disabled');
      } else if (response.statusCode == 404) {
        throw AuthException('Authentication service not found');
      } else if (response.statusCode >= 500) {
        throw AuthException('Server error - please try again later');
      } else {
        throw AuthException('Authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔐 AUTH ERROR: $e');
      if (e is AuthException) rethrow;
      throw AuthException('Authentication error: $e');
    }
  }
}

class AuthResponse {
  final String userId;
  final String? token;
  final String? service; // "A" or "B" or "inStore" or "inStorePromo"
  final String? profile; // Alternative field name
  final String? name;
  final String? email;
  final Map<String, dynamic> rawData; // Store all data for debugging

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
    return AuthResponse(
      userId: json['user_id']?.toString() ?? 
              json['userId']?.toString() ?? 
              json['id']?.toString() ?? 
              'unknown',
      token: json['token']?.toString() ?? json['auth_token']?.toString(),
      service: json['service']?.toString(),
      profile: json['profile']?.toString(),
      name: json['name']?.toString() ?? json['username']?.toString(),
      email: json['email']?.toString(),
      rawData: json,
    );
  }

  // Determine if this is Profile A or Profile B
  bool get isProfileA {
    // Check various possible field names/values
    if (service != null) {
      final s = service!.toLowerCase();
      return s == 'a' || s == 'instore' || s == 'in-store' || s == 'profile_a';
    }
    if (profile != null) {
      final p = profile!.toLowerCase();
      return p == 'a' || p == 'instore' || p == 'in-store' || p == 'profile_a';
    }
    // Default to Profile A if not specified
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
