// Image Compression and Capture Processing
// Handles compression, metadata generation, and queue integration
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import '../../models/app_models.dart';
import 'upload_models.dart';
import 'upload_queue_manager.dart';

// =============================================================================
// CAPTURE CONTEXT MANAGER
// =============================================================================

class CaptureContext {
  final String operatorId;
  final String operatorName;
  final String sessionId;
  final String visitId;
  final String storeId;
  final String storeName;
  final String? area;
  final String? aisle;
  final String? segment;
  final InstallationType? installationType;
  final int? aisleNumber;

  const CaptureContext({
    required this.operatorId,
    required this.operatorName,
    required this.sessionId,
    required this.visitId,
    required this.storeId,
    required this.storeName,
    this.area,
    this.aisle,
    this.segment,
    this.installationType,
    this.aisleNumber,
  });
}

// =============================================================================
// IMAGE COMPRESSION SYSTEM
// =============================================================================

class ImageCompressor {
  static const int _maxFileSize = 1024 * 1024; // 1MB max
  static const int _qualityHigh = 92;
  static const int _qualityMedium = 85;
  static const int _qualityLow = 78;

  static Future<Uint8List> compressForLabels(Uint8List imageData) async {
    try {
      debugPrint('Compressing label image: ${imageData.length} bytes');
      
      // Step 1: Try WebP format first (25-35% better compression)
      final webpResult = await FlutterImageCompress.compressWithList(
        imageData,
        quality: _qualityHigh,
        format: CompressFormat.webp,
      );

      if (webpResult.length <= _maxFileSize) {
        debugPrint('WebP compression successful: ${webpResult.length} bytes');
        return webpResult;
      }

      // Step 2: Fall back to JPEG with progressive quality reduction
      for (int quality in [_qualityHigh, _qualityMedium, _qualityLow]) {
        final jpegResult = await FlutterImageCompress.compressWithList(
          imageData,
          quality: quality,
          format: CompressFormat.jpeg,
        );

        if (jpegResult.length <= _maxFileSize) {
          debugPrint('JPEG compression successful at $quality%: ${jpegResult.length} bytes');
          return jpegResult;
        }
      }

      // Step 3: Resize if still too large
      final resizedResult = await FlutterImageCompress.compressWithList(
        imageData,
        quality: _qualityLow,
        minWidth: 1280,
        minHeight: 720,
        format: CompressFormat.jpeg,
      );
      
      debugPrint('Resized compression: ${resizedResult.length} bytes');
      return resizedResult;

    } catch (e) {
      debugPrint('Compression error: $e');
      // Return original if compression fails
      return imageData;
    }
  }

  static Future<Uint8List> compressForScenes(Uint8List imageData) async {
    try {
      debugPrint('Compressing scene image: ${imageData.length} bytes');
      
      // Scenes need higher quality for context
      final result = await FlutterImageCompress.compressWithList(
        imageData,
        quality: _qualityHigh,
        format: CompressFormat.jpeg,
      );

      debugPrint('Scene compression successful: ${result.length} bytes');
      return result;

    } catch (e) {
      debugPrint('Scene compression error: $e');
      return imageData;
    }
  }
}

// =============================================================================
// CAPTURE PROCESSOR
// =============================================================================

class CaptureProcessor {
  static const _uuid = Uuid();
  
  static Future<String> processCapture({
    required String originalImagePath,
    required CameraMode captureType,
    required CaptureContext context,
    required bool wasAutoCapture,
    Map<String, dynamic>? qualityDetails,
    Map<String, dynamic>? cameraSettings,
  }) async {
    try {
      debugPrint('Processing capture: $originalImagePath');
      
      // Step 1: Load and compress image
      final originalFile = File(originalImagePath);
      if (!originalFile.existsSync()) {
        throw Exception('Original image file not found: $originalImagePath');
      }
      
      final originalBytes = await originalFile.readAsBytes();
      
      final compressedBytes = captureType == CameraMode.sceneCapture
          ? await ImageCompressor.compressForScenes(originalBytes)
          : await ImageCompressor.compressForLabels(originalBytes);

      // Step 2: Generate filename with comprehensive metadata
      final timestamp = DateTime.now();
      final filename = _generateFilename(
        captureType: captureType,
        storeId: context.storeId,
        installationType: context.installationType,
        aisleNumber: context.aisleNumber,
        timestamp: timestamp,
      );

      // Step 3: Save compressed image to app storage
      final savedPath = await _saveToAppStorage(compressedBytes, filename);

      // Step 4: Generate comprehensive metadata
      final metadata = await _generateMetadata(
        context: context,
        captureType: captureType,
        timestamp: timestamp,
        wasAutoCapture: wasAutoCapture,
        qualityDetails: qualityDetails,
        cameraSettings: cameraSettings ?? {},
        filename: filename,
        fileSizeBytes: compressedBytes.length,
        originalBytes: originalBytes,
      );

      // Step 5: Add to upload queue
      final uploadId = await UploadQueueManager.instance.addToQueue(
        filePath: savedPath,
        metadata: metadata,
      );

      // Step 6: Clean up original image file
      try {
        await originalFile.delete();
        debugPrint('Original image deleted: $originalImagePath');
      } catch (e) {
        debugPrint('Failed to delete original image: $e');
      }

      debugPrint('Capture processed successfully: $uploadId, size: ${compressedBytes.length} bytes');
      return uploadId;

    } catch (e) {
      debugPrint('Capture processing error: $e');
      rethrow;
    }
  }

  static String _generateFilename({
    required CameraMode captureType,
    required String storeId,
    InstallationType? installationType,
    int? aisleNumber,
    required DateTime timestamp,
  }) {
    final typePrefix = captureType == CameraMode.sceneCapture ? 'scene' : 'label';
    final timestampStr = timestamp.toIso8601String()
        .replaceAll(RegExp(r'[:.T-]'), '')
        .substring(0, 15); // YYYYMMDDHHMMSS
    final uniqueId = _uuid.v4().substring(0, 8);
    
    String locationPart = storeId;
    if (installationType != null) {
      locationPart += '_${installationType.id}';
      if (aisleNumber != null) {
        locationPart += '_aisle$aisleNumber';
      }
    }

    return '${typePrefix}_${locationPart}_${timestampStr}_$uniqueId.jpg';
  }

  static Future<String> _saveToAppStorage(Uint8List imageData, String filename) async {
    final appDir = await getApplicationDocumentsDirectory();
    final capturesDir = Directory('${appDir.path}/captures');
    
    if (!await capturesDir.exists()) {
      await capturesDir.create(recursive: true);
    }

    final file = File('${capturesDir.path}/$filename');
    await file.writeAsBytes(imageData);
    
    debugPrint('Image saved to: ${file.path}');
    return file.path;
  }

  static Future<CaptureMetadata> _generateMetadata({
    required CaptureContext context,
    required CameraMode captureType,
    required DateTime timestamp,
    required bool wasAutoCapture,
    Map<String, dynamic>? qualityDetails,
    required Map<String, dynamic> cameraSettings,
    required String filename,
    required int fileSizeBytes,
    required Uint8List originalBytes,
  }) async {
    try {
      // Get device information
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      String deviceId;
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown_ios_device';
      }

      // Calculate file checksum for integrity
      final checksum = md5.convert(originalBytes).toString();

      return CaptureMetadata(
        operatorId: context.operatorId,
        operatorName: context.operatorName,
        sessionId: context.sessionId,
        visitId: context.visitId,
        storeId: context.storeId,
        storeName: context.storeName,
        area: context.area,
        aisle: context.aisle,
        segment: context.segment,
        installationType: context.installationType?.id,
        aisleNumber: context.aisleNumber,
        captureType: captureType == CameraMode.sceneCapture ? 'scene' : 'label',
        captureTimestamp: timestamp,
        wasAutoCapture: wasAutoCapture,
        qualityScore: qualityDetails?['overallScore']?.toDouble(),
        qualityDetails: qualityDetails,
        deviceId: deviceId,
        appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
        cameraSettings: cameraSettings,
        originalFilename: filename,
        fileSizeBytes: fileSizeBytes,
        checksumMD5: checksum,
      );
      
    } catch (e) {
      debugPrint('Metadata generation error: $e');
      rethrow;
    }
  }
}

// =============================================================================
// SESSION MANAGER
// =============================================================================

class VisitSessionManager {
  static VisitSessionManager? _instance;
  static VisitSessionManager get instance => _instance ??= VisitSessionManager._();
  
  VisitSessionManager._();

  CaptureContext? _currentContext;
  final String _sessionId = const Uuid().v4();
  final String _visitId = const Uuid().v4();

  void startVisit({
    required String operatorId,
    required String operatorName,
    required String storeId,
    required String storeName,
  }) {
    _currentContext = CaptureContext(
      operatorId: operatorId,
      operatorName: operatorName,
      sessionId: _sessionId,
      visitId: _visitId,
      storeId: storeId,
      storeName: storeName,
    );
    
    debugPrint('Visit started: $_visitId for store: $storeName');
  }

  void updateLocation({
    String? area,
    String? aisle,
    String? segment,
    InstallationType? installationType,
    int? aisleNumber,
  }) {
    if (_currentContext == null) {
      throw Exception('No active visit session');
    }

    _currentContext = CaptureContext(
      operatorId: _currentContext!.operatorId,
      operatorName: _currentContext!.operatorName,
      sessionId: _currentContext!.sessionId,
      visitId: _currentContext!.visitId,
      storeId: _currentContext!.storeId,
      storeName: _currentContext!.storeName,
      area: area,
      aisle: aisle,
      segment: segment,
      installationType: installationType,
      aisleNumber: aisleNumber,
    );
    
    debugPrint('Location updated: $area, $aisle, $segment, ${installationType?.displayName}, aisle: $aisleNumber');
  }

  CaptureContext? get currentContext => _currentContext;
  String get sessionId => _sessionId;
  String get visitId => _visitId;

  void endVisit() {
    debugPrint('Visit ended: $_visitId');
    _currentContext = null;
  }
}
