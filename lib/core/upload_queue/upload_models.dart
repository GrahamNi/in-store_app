// Upload Queue Models - Comprehensive metadata and state management
import 'dart:convert';
import 'package:flutter/foundation.dart';

// =============================================================================
// COMPREHENSIVE METADATA MODEL
// =============================================================================

@immutable
class CaptureMetadata {
  // Operator & Session Context
  final String operatorId;
  final String operatorName;
  final String sessionId;
  final String visitId;
  
  // Store & Location Hierarchy
  final String storeId;
  final String storeName;
  final String? area;
  final String? aisle;
  final String? segment;
  final String? installationType;
  final int? aisleNumber;
  
  // Capture Details
  final String captureType; // 'scene' or 'label'
  final DateTime captureTimestamp;
  final bool wasAutoCapture;
  final double? qualityScore;
  final Map<String, dynamic>? qualityDetails;
  
  // Technical Metadata
  final String deviceId;
  final String appVersion;
  final Map<String, dynamic> cameraSettings;
  final String originalFilename;
  final int fileSizeBytes;
  final String checksumMD5;

  const CaptureMetadata({
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
    required this.captureType,
    required this.captureTimestamp,
    required this.wasAutoCapture,
    this.qualityScore,
    this.qualityDetails,
    required this.deviceId,
    required this.appVersion,
    required this.cameraSettings,
    required this.originalFilename,
    required this.fileSizeBytes,
    required this.checksumMD5,
  });

  Map<String, dynamic> toJson() => {
    'operatorId': operatorId,
    'operatorName': operatorName,
    'sessionId': sessionId,
    'visitId': visitId,
    'storeId': storeId,
    'storeName': storeName,
    'area': area,
    'aisle': aisle,
    'segment': segment,
    'installationType': installationType,
    'aisleNumber': aisleNumber,
    'captureType': captureType,
    'captureTimestamp': captureTimestamp.toIso8601String(),
    'wasAutoCapture': wasAutoCapture,
    'qualityScore': qualityScore,
    'qualityDetails': qualityDetails,
    'deviceId': deviceId,
    'appVersion': appVersion,
    'cameraSettings': cameraSettings,
    'originalFilename': originalFilename,
    'fileSizeBytes': fileSizeBytes,
    'checksumMD5': checksumMD5,
  };

  factory CaptureMetadata.fromJson(Map<String, dynamic> json) => CaptureMetadata(
    operatorId: json['operatorId'],
    operatorName: json['operatorName'],
    sessionId: json['sessionId'],
    visitId: json['visitId'],
    storeId: json['storeId'],
    storeName: json['storeName'],
    area: json['area'],
    aisle: json['aisle'],
    segment: json['segment'],
    installationType: json['installationType'],
    aisleNumber: json['aisleNumber'],
    captureType: json['captureType'],
    captureTimestamp: DateTime.parse(json['captureTimestamp']),
    wasAutoCapture: json['wasAutoCapture'],
    qualityScore: json['qualityScore']?.toDouble(),
    qualityDetails: json['qualityDetails'] != null 
        ? Map<String, dynamic>.from(json['qualityDetails'])
        : null,
    deviceId: json['deviceId'],
    appVersion: json['appVersion'],
    cameraSettings: Map<String, dynamic>.from(json['cameraSettings']),
    originalFilename: json['originalFilename'],
    fileSizeBytes: json['fileSizeBytes'],
    checksumMD5: json['checksumMD5'],
  );
}

// =============================================================================
// UPLOAD QUEUE ITEM WITH COMPREHENSIVE STATE
// =============================================================================

enum UploadStatus {
  pending,
  uploading,
  completed,
  failed,
  paused,
  stuck, // For items older than 24 hours
}

@immutable
class UploadQueueItem {
  final String id;
  final String localFilePath;
  final CaptureMetadata metadata;
  final UploadStatus status;
  final double progress;
  final int retryCount;
  final DateTime createdAt;
  final DateTime lastAttemptAt;
  final String? errorMessage;
  final String? serverUrl; // Once uploaded

  const UploadQueueItem({
    required this.id,
    required this.localFilePath,
    required this.metadata,
    this.status = UploadStatus.pending,
    this.progress = 0.0,
    this.retryCount = 0,
    required this.createdAt,
    required this.lastAttemptAt,
    this.errorMessage,
    this.serverUrl,
  });

  UploadQueueItem copyWith({
    UploadStatus? status,
    double? progress,
    int? retryCount,
    DateTime? lastAttemptAt,
    String? errorMessage,
    String? serverUrl,
  }) => UploadQueueItem(
    id: id,
    localFilePath: localFilePath,
    metadata: metadata,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    retryCount: retryCount ?? this.retryCount,
    createdAt: createdAt,
    lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    errorMessage: errorMessage ?? this.errorMessage,
    serverUrl: serverUrl ?? this.serverUrl,
  );

  bool get isStuck {
    final hoursSinceCreated = DateTime.now().difference(createdAt).inHours;
    return hoursSinceCreated > 24 && status != UploadStatus.completed;
  }

  String get formattedFileSize {
    if (metadata.fileSizeBytes < 1024) return '${metadata.fileSizeBytes}B';
    if (metadata.fileSizeBytes < 1024 * 1024) {
      return '${(metadata.fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(metadata.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'localFilePath': localFilePath,
    'metadata': metadata.toJson(),
    'status': status.name,
    'progress': progress,
    'retryCount': retryCount,
    'createdAt': createdAt.toIso8601String(),
    'lastAttemptAt': lastAttemptAt.toIso8601String(),
    'errorMessage': errorMessage,
    'serverUrl': serverUrl,
  };

  factory UploadQueueItem.fromJson(Map<String, dynamic> json) => UploadQueueItem(
    id: json['id'],
    localFilePath: json['localFilePath'],
    metadata: CaptureMetadata.fromJson(json['metadata']),
    status: UploadStatus.values.byName(json['status']),
    progress: json['progress']?.toDouble() ?? 0.0,
    retryCount: json['retryCount'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    lastAttemptAt: DateTime.parse(json['lastAttemptAt']),
    errorMessage: json['errorMessage'],
    serverUrl: json['serverUrl'],
  );
}

// =============================================================================
// NETWORK CONDITIONS
// =============================================================================

enum NetworkType { none, cellular, wifi, other }

class NetworkConditions {
  final NetworkType type;
  final bool isConnected;
  final bool isMetered;
  final double? speedMbps; // If measurable

  const NetworkConditions({
    required this.type,
    required this.isConnected,
    this.isMetered = false,
    this.speedMbps,
  });

  int get optimalConcurrency {
    if (!isConnected) return 0;
    if (type == NetworkType.cellular) return 2;
    if (type == NetworkType.wifi) return 3;
    return 2; // Safe default
  }

  Duration get retryDelay => Duration(
    seconds: switch (type) {
      NetworkType.wifi => 2,
      NetworkType.cellular => 5,
      _ => 10,
    },
  );
}
