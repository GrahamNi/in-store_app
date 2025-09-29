// Upload Worker - Handles actual file uploads with retry logic
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'upload_models.dart';

// =============================================================================
// UPLOAD WORKER WITH RETRY LOGIC - UPDATED FOR YOUR API
// =============================================================================

class UploadWorker {
  final Dio _dio;
  final String baseUrl;
  
  UploadWorker({required this.baseUrl}) : _dio = Dio() {
    // Configure Dio with reasonable timeouts
    _dio.options.connectTimeout = const Duration(minutes: 2);
    _dio.options.sendTimeout = const Duration(minutes: 5);
    _dio.options.receiveTimeout = const Duration(minutes: 2);
    
    // Add logging in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false, // Don't log file data
        responseBody: false,
        logPrint: (obj) => debugPrint('Upload: $obj'),
      ));
    }
  }

  Future<String> uploadFile(UploadQueueItem item, {
    Function(double)? onProgress,
  }) async {
    final file = File(item.localFilePath);
    if (!file.existsSync()) {
      throw Exception('File not found: ${item.localFilePath}');
    }

    try {
      // Read file as bytes and convert to base64
      final fileBytes = await file.readAsBytes();
      final base64String = base64Encode(fileBytes);
      
      // Create metadata JSON string
      final metaData = jsonEncode({
        'captureTimestamp': item.metadata.captureTimestamp.toIso8601String(),
        'operatorId': item.metadata.operatorId,
        'operatorName': item.metadata.operatorName,
        'sessionId': item.metadata.sessionId,
        'visitId': item.metadata.visitId,
        'storeId': item.metadata.storeId,
        'storeName': item.metadata.storeName,
        'area': item.metadata.area,
        'aisle': item.metadata.aisle,
        'segment': item.metadata.segment,
        'captureType': item.metadata.captureType,
        'originalFilename': item.metadata.originalFilename,
        'fileSize': item.metadata.fileSizeBytes,
        'qualityScore': item.metadata.qualityScore,
        'deviceId': item.metadata.deviceId,
        'appVersion': item.metadata.appVersion,
      });

      // Create request body matching your API format
      final requestBody = {
        'meta': metaData,
        'b64': base64String,
      };

      debugPrint('Uploading file: ${item.metadata.originalFilename}');
      debugPrint('File size: ${(fileBytes.length / 1024).toStringAsFixed(1)} KB');
      debugPrint('Base64 size: ${(base64String.length / 1024).toStringAsFixed(1)} KB');

      final response = await _dio.post(
        baseUrl, // Your API expects POST directly to the base URL
        data: requestBody,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            final progress = sent / total;
            onProgress(progress);
            debugPrint('Upload progress: ${(progress * 100).toInt()}%');
          }
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Device-ID': item.metadata.deviceId,
            'X-Session-ID': item.metadata.sessionId,
            'X-Operator-ID': item.metadata.operatorId,
            'X-App-Version': item.metadata.appVersion,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Upload successful - Response: ${response.data}');
        
        // Your API might return different response format
        // Adjust this based on what your API actually returns
        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          final fileUrl = responseData['fileUrl'] as String? ?? 
                         responseData['url'] as String? ??
                         responseData['uploadId'] as String? ??
                         'uploaded_${DateTime.now().millisecondsSinceEpoch}';
          return fileUrl;
        } else {
          return 'uploaded_${DateTime.now().millisecondsSinceEpoch}';
        }
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }

    } on DioException catch (e) {
      String errorMessage;
      
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Connection timeout';
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = 'Upload timeout';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Server response timeout';
          break;
        case DioExceptionType.badResponse:
          errorMessage = 'Server error: ${e.response?.statusCode} - ${e.response?.data}';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Network connection error';
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Upload cancelled';
          break;
        default:
          errorMessage = 'Upload failed: ${e.message}';
      }
      
      debugPrint('Upload error: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('Unexpected upload error: $e');
      throw Exception('Upload failed: $e');
    }
  }

  // Test connection to upload endpoint
  Future<bool> testConnection() async {
    try {
      // Test with a minimal request to see if the endpoint is reachable
      final response = await _dio.post(
        baseUrl,
        data: {
          'meta': jsonEncode({'test': 'connection'}),
          'b64': 'dGVzdA==' // "test" in base64
        },
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      // Consider 200, 201, or even 400 (bad request) as "reachable"
      // since 400 might just mean our test data was invalid
      return response.statusCode != null && response.statusCode! < 500;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  void dispose() {
    _dio.close();
  }
}

// =============================================================================
// RETRY LOGIC UTILITIES
// =============================================================================

class RetryLogic {
  static Duration calculateExponentialBackoff(int retryCount, NetworkType networkType) {
    final baseDelaySeconds = switch (networkType) {
      NetworkType.wifi => 2,
      NetworkType.cellular => 5,
      _ => 10,
    };
    
    final exponentialDelay = baseDelaySeconds * pow(2, retryCount - 1).toInt();
    final jitter = Random().nextInt(1000); // 0-1000ms jitter
    final totalDelayMs = (exponentialDelay * 1000) + jitter;
    
    // Cap at 5 minutes
    final cappedDelay = min(totalDelayMs, 300000);
    
    return Duration(milliseconds: cappedDelay);
  }

  static bool shouldRetry(String errorMessage, int retryCount) {
    const maxRetries = 3;
    
    if (retryCount >= maxRetries) {
      return false;
    }
    
    // Don't retry certain permanent errors
    final permanentErrors = [
      'file not found',
      'invalid file format',
      'file too large',
      'unauthorized',
      'forbidden',
    ];
    
    final lowerError = errorMessage.toLowerCase();
    for (final permanentError in permanentErrors) {
      if (lowerError.contains(permanentError)) {
        return false;
      }
    }
    
    return true;
  }
}
