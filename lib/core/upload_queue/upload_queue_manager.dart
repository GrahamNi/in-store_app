// Main Upload Queue Manager - Orchestrates the entire upload system
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'network_monitor.dart';
import 'upload_models.dart';
import 'upload_database.dart';
import 'upload_worker.dart';
import 'upload_queue_cleanup.dart';

// =============================================================================
// MAIN UPLOAD QUEUE MANAGER
// =============================================================================

class UploadQueueManager {
  static UploadQueueManager? _instance;
  static UploadQueueManager get instance => _instance ??= UploadQueueManager._();
  
  UploadQueueManager._();

  // Core systems
  final NetworkMonitor _networkMonitor = NetworkMonitor();
  final BatteryMonitor _batteryMonitor = BatteryMonitor();
  late final UploadWorker _uploadWorker;
  
  // Stream controllers
  final StreamController<List<UploadQueueItem>> _queueController = 
      StreamController<List<UploadQueueItem>>.broadcast();
  final StreamController<String> _statusController = 
      StreamController<String>.broadcast();
  
  // Public streams
  Stream<List<UploadQueueItem>> get queueStream => _queueController.stream;
  Stream<String> get statusStream => _statusController.stream;
  
  // State management
  bool _isProcessing = false;
  bool _isInitialized = false;
  List<UploadQueueItem> _activeUploads = [];
  Timer? _processingTimer;
  Timer? _stuckDetectionTimer;
  Timer? _cleanupTimer;

  // Configuration
  String? _uploadBaseUrl;

  // =============================================================================
  // INITIALIZATION
  // =============================================================================

  Future<void> initialize({required String uploadBaseUrl}) async {
    if (_isInitialized) {
      debugPrint('📤 UPLOAD QUEUE: Already initialized, skipping');
      return;
    }

    debugPrint('📤 UPLOAD QUEUE: Starting initialization...');
    _uploadBaseUrl = uploadBaseUrl;
    _uploadWorker = UploadWorker(baseUrl: uploadBaseUrl);
    
    try {
      debugPrint('📤 UPLOAD QUEUE: Initializing database...');
      // Test database initialization
      final db = await UploadQueueDatabase.database;
      final existingUploads = await UploadQueueDatabase.getAllUploads();
      debugPrint('📤 UPLOAD QUEUE: Database initialized - found ${existingUploads.length} existing uploads');
      
      debugPrint('📤 UPLOAD QUEUE: Starting monitoring systems...');
      // Initialize monitoring systems
      _networkMonitor.start();
      _batteryMonitor.start();
      
      // Monitor network changes to adjust upload behavior
      _networkMonitor.conditionsStream.listen(_onNetworkChanged);
      
      // Monitor battery changes for power management
      _batteryMonitor.batteryLevelStream.listen(_onBatteryChanged);
      
      debugPrint('📤 UPLOAD QUEUE: Setting up auto-processing...');
      // 🚀 IMPORTANT: Auto-start processing (no manual intervention required)
      _isProcessing = true;
      _startProcessing();
      
      debugPrint('📤 UPLOAD QUEUE: Starting background tasks...');
      // Start stuck upload detection (every hour)
      _startStuckDetection();
      
      // Start daily cleanup
      _startCleanup();
      
      // 🧹 Start auto-cleanup for completed uploads
      UploadQueueCleanup.startAutoCleanup();
      debugPrint('📤 UPLOAD QUEUE: Auto-cleanup enabled for completed uploads');
      
      debugPrint('📤 UPLOAD QUEUE: Refreshing queue...');
      // Load existing queue
      await _refreshQueue();
      
      _isInitialized = true;
      _statusController.add('Auto-upload enabled');
      
      debugPrint('📤 UPLOAD QUEUE: ✅ Successfully initialized with AUTO-UPLOAD enabled');
      debugPrint('📤 UPLOAD QUEUE: Upload URL: $uploadBaseUrl');
      debugPrint('📤 UPLOAD QUEUE: Processing: $_isProcessing');
      debugPrint('📤 UPLOAD QUEUE: Network: ${_networkMonitor.current.isConnected}');
      
    } catch (e, stackTrace) {
      debugPrint('📤 UPLOAD QUEUE: ❌ Failed to initialize: $e');
      debugPrint('📤 UPLOAD QUEUE: Stack trace: $stackTrace');
      _statusController.add('Failed to initialize: $e');
      rethrow;
    }
  }

  void _startProcessing() {
    _processingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_networkMonitor.current.isConnected && !_batteryMonitor.isBatteryLow) {
        _processQueue();
      }
    });
  }

  void _startStuckDetection() {
    _stuckDetectionTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _detectStuckUploads();
    });
  }

  void _startCleanup() {
    // Run cleanup daily at startup, then every 24 hours
    _cleanupTimer = Timer.periodic(const Duration(hours: 24), (_) {
      UploadQueueDatabase.cleanup();
    });
    
    // Initial cleanup
    UploadQueueDatabase.cleanup();
  }

  // =============================================================================
  // EVENT HANDLERS
  // =============================================================================

  void _onNetworkChanged(NetworkConditions conditions) {
    _statusController.add('Network: ${conditions.type.name}');
    
    if (!conditions.isConnected) {
      _pauseAllUploads();
      _statusController.add('Uploads paused - no network');
    } else {
      _statusController.add('Network restored - resuming uploads');
      _processQueue();
    }
  }

  void _onBatteryChanged(int batteryLevel) {
    if (batteryLevel < 20) {
      _pauseAllUploads();
      _statusController.add('Uploads paused - low battery ($batteryLevel%)');
    } else if (batteryLevel > 25 && _networkMonitor.current.isConnected) {
      _statusController.add('Battery restored - resuming uploads');
      _processQueue();
    }
  }

  // =============================================================================
  // PUBLIC API
  // =============================================================================

  Future<String> addToQueue({
    required String filePath,
    required CaptureMetadata metadata,
  }) async {
    if (!_isInitialized) {
      debugPrint('📤 UPLOAD QUEUE: ❌ Attempted to add item to uninitialized queue');
      throw Exception('Upload queue not initialized');
    }

    try {
      debugPrint('📤 UPLOAD QUEUE: Adding new item to queue...');
      debugPrint('📤 UPLOAD QUEUE: File: $filePath');
      debugPrint('📤 UPLOAD QUEUE: Metadata: ${metadata.originalFilename}');
      
      final item = UploadQueueItem(
        id: _generateUploadId(),
        localFilePath: filePath,
        metadata: metadata,
        createdAt: DateTime.now(),
        lastAttemptAt: DateTime.now(),
      );

      await UploadQueueDatabase.insertUpload(item);
      await UploadQueueDatabase.logEvent(item.id, 'QUEUED', 'File added to upload queue');
      
      debugPrint('📤 UPLOAD QUEUE: ✅ Item added with ID: ${item.id}');
      _statusController.add('Added to queue: ${metadata.originalFilename}');
      await _refreshQueue();
      
      // Try to upload immediately if conditions allow
      debugPrint('📤 UPLOAD QUEUE: Triggering immediate processing...');
      _processQueue();
      
      return item.id;

    } catch (e, stackTrace) {
      debugPrint('📤 UPLOAD QUEUE: ❌ Failed to add to queue: $e');
      debugPrint('📤 UPLOAD QUEUE: Stack trace: $stackTrace');
      _statusController.add('Failed to queue: $e');
      rethrow;
    }
  }

  Future<void> retryUpload(String uploadId) async {
    try {
      final allUploads = await UploadQueueDatabase.getAllUploads();
      final upload = allUploads.where((u) => u.id == uploadId).firstOrNull;
      
      if (upload != null && upload.status == UploadStatus.failed) {
        final retryItem = upload.copyWith(
          status: UploadStatus.pending,
          lastAttemptAt: DateTime.now(),
          errorMessage: null,
        );
        
        await UploadQueueDatabase.updateUpload(retryItem);
        await UploadQueueDatabase.logEvent(uploadId, 'RETRY', 'Manual retry initiated');
        
        _statusController.add('Retrying upload: ${upload.metadata.originalFilename}');
        await _refreshQueue();
        _processQueue();
      }
    } catch (e) {
      debugPrint('Failed to retry upload: $e');
      _statusController.add('Retry failed: $e');
    }
  }

  Future<void> deleteUpload(String uploadId) async {
    try {
      await UploadQueueDatabase.deleteUpload(uploadId);
      _statusController.add('Upload deleted');
      await _refreshQueue();
    } catch (e) {
      debugPrint('Failed to delete upload: $e');
      _statusController.add('Delete failed: $e');
    }
  }

  Future<void> clearCompleted() async {
    try {
      await UploadQueueDatabase.deleteCompletedUploads();
      _statusController.add('Completed uploads cleared');
      await _refreshQueue();
    } catch (e) {
      debugPrint('Failed to clear completed: $e');
      _statusController.add('Clear failed: $e');
    }
  }

  Future<void> pauseUploads() async {
    _isProcessing = false;
    await _pauseAllUploads();
    _statusController.add('Uploads paused manually');
  }

  Future<void> resumeUploads() async {
    _isProcessing = true;
    _statusController.add('Uploads resumed manually');
    if (_networkMonitor.current.isConnected && !_batteryMonitor.isBatteryLow) {
      _processQueue();
    }
  }

  // =============================================================================
  // QUEUE PROCESSING LOGIC
  // =============================================================================

  Future<void> _processQueue() async {
    if (!_isProcessing || !_networkMonitor.current.isConnected || _batteryMonitor.isBatteryLow) {
      return;
    }

    try {
      final pendingUploads = await UploadQueueDatabase.getPendingUploads();
      if (pendingUploads.isEmpty) return;

      final conditions = _networkMonitor.current;
      final maxConcurrent = conditions.optimalConcurrency;
      
      final currentUploading = _activeUploads.where((u) => u.status == UploadStatus.uploading).length;
      final availableSlots = maxConcurrent - currentUploading;
      
      if (availableSlots <= 0) return;

      final toUpload = pendingUploads.take(availableSlots).toList();
      
      for (final upload in toUpload) {
        _startUpload(upload);
      }

    } catch (e) {
      debugPrint('Queue processing error: $e');
      _statusController.add('Processing error: $e');
    }
  }

  Future<void> _startUpload(UploadQueueItem item) async {
    final uploadingItem = item.copyWith(
      status: UploadStatus.uploading,
      lastAttemptAt: DateTime.now(),
    );
    
    try {
      await UploadQueueDatabase.updateUpload(uploadingItem);
      await UploadQueueDatabase.logEvent(item.id, 'UPLOAD_STARTED', 'Upload started');
      
      _activeUploads.add(uploadingItem);
      await _refreshQueue();

      _statusController.add('Uploading: ${item.metadata.originalFilename}');

      final serverUrl = await _uploadWorker.uploadFile(
        uploadingItem,
        onProgress: (progress) => _updateProgress(item.id, progress),
      );

      final completedItem = uploadingItem.copyWith(
        status: UploadStatus.completed,
        progress: 1.0,
        serverUrl: serverUrl,
      );

      await UploadQueueDatabase.updateUpload(completedItem);
      await UploadQueueDatabase.logEvent(item.id, 'UPLOAD_COMPLETED', 'Upload successful: $serverUrl');
      
      _statusController.add('Upload completed: ${item.metadata.originalFilename}');
      
    } catch (e) {
      final retryCount = item.retryCount + 1;
      final maxRetries = 3;
      
      final shouldRetry = RetryLogic.shouldRetry(e.toString(), retryCount);
      
      final failedItem = uploadingItem.copyWith(
        status: shouldRetry ? UploadStatus.pending : UploadStatus.failed,
        retryCount: retryCount,
        errorMessage: e.toString(),
      );

      await UploadQueueDatabase.updateUpload(failedItem);
      
      final eventType = shouldRetry ? 'UPLOAD_RETRY_SCHEDULED' : 'UPLOAD_FAILED';
      await UploadQueueDatabase.logEvent(
        item.id, 
        eventType,
        'Upload error (attempt $retryCount/$maxRetries): $e',
      );

      if (shouldRetry) {
        _statusController.add('Upload failed, will retry: ${item.metadata.originalFilename}');
        
        // Schedule retry with exponential backoff
        final delay = RetryLogic.calculateExponentialBackoff(retryCount, _networkMonitor.current.type);
        Timer(delay, () => _processQueue());
      } else {
        _statusController.add('Upload permanently failed: ${item.metadata.originalFilename}');
      }
      
    } finally {
      _activeUploads.removeWhere((u) => u.id == item.id);
      await _refreshQueue();
    }
  }

  Future<void> _pauseAllUploads() async {
    final uploading = _activeUploads.where((u) => u.status == UploadStatus.uploading).toList();
    
    for (final upload in uploading) {
      final pausedItem = upload.copyWith(status: UploadStatus.paused);
      await UploadQueueDatabase.updateUpload(pausedItem);
      await UploadQueueDatabase.logEvent(upload.id, 'PAUSED', 'Upload paused due to conditions');
    }
    
    _activeUploads.clear();
    await _refreshQueue();
  }

  Future<void> _updateProgress(String uploadId, double progress) async {
    final uploadIndex = _activeUploads.indexWhere((u) => u.id == uploadId);
    if (uploadIndex != -1) {
      _activeUploads[uploadIndex] = _activeUploads[uploadIndex].copyWith(progress: progress);
      await _refreshQueue();
    }
  }

  Future<void> _detectStuckUploads() async {
    try {
      final stuckUploads = await UploadQueueDatabase.getStuckUploads();
      
      for (final upload in stuckUploads) {
        final stuckItem = upload.copyWith(status: UploadStatus.stuck);
        await UploadQueueDatabase.updateUpload(stuckItem);
        await UploadQueueDatabase.logEvent(
          upload.id,
          'UPLOAD_STUCK',
          'Upload marked as stuck (older than 24 hours)',
        );
        
        debugPrint('ALERT: Stuck upload detected: ${upload.id}');
      }
      
      if (stuckUploads.isNotEmpty) {
        _statusController.add('${stuckUploads.length} stuck uploads detected');
        await _refreshQueue();
      }
    } catch (e) {
      debugPrint('Stuck detection error: $e');
    }
  }

  Future<void> _refreshQueue() async {
    try {
      final allUploads = await UploadQueueDatabase.getAllUploads();
      debugPrint('📤 UPLOAD QUEUE: Queue refreshed - ${allUploads.length} items total');
      _queueController.add(allUploads);
    } catch (e) {
      debugPrint('📤 UPLOAD QUEUE: ❌ Failed to refresh queue: $e');
    }
  }

  String _generateUploadId() {
    return 'upload_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  // =============================================================================
  // STATUS AND STATISTICS
  // =============================================================================

  Future<Map<String, dynamic>> getStats() async {
    try {
      final queueStats = await UploadQueueDatabase.getQueueStats();
      final totalSize = await UploadQueueDatabase.getTotalFileSize();
      
      return {
        'queue_stats': queueStats,
        'total_size_bytes': totalSize,
        'network_type': _networkMonitor.current.type.name,
        'network_connected': _networkMonitor.current.isConnected,
        'battery_level': _batteryMonitor.currentLevel,
        'is_processing': _isProcessing,
        'active_uploads': _activeUploads.length,
      };
    } catch (e) {
      debugPrint('Failed to get stats: $e');
      return {'error': e.toString()};
    }
  }

  bool get isInitialized => _isInitialized;
  NetworkConditions get networkConditions => _networkMonitor.current;
  int get batteryLevel => _batteryMonitor.currentLevel;
  bool get isProcessing => _isProcessing;

  // =============================================================================
  // CLEANUP
  // =============================================================================

  void dispose() {
    _processingTimer?.cancel();
    _stuckDetectionTimer?.cancel();
    _cleanupTimer?.cancel();
    UploadQueueCleanup.stopAutoCleanup(); // Stop auto-cleanup
    _networkMonitor.dispose();
    _batteryMonitor.dispose();
    _queueController.close();
    _statusController.close();
    _uploadWorker.dispose();
    _isInitialized = false;
  }
}
