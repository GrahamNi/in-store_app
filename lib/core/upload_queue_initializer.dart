// Upload Queue Initialization
// Call this from your main.dart to set up the upload queue system
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import 'upload_queue/upload_queue.dart';

class UploadQueueInitializer {
  static bool _isInitialized = false;
  
  static Future<void> initialize({
    String uploadBaseUrl = 'https://your-api-server.com/api', // Replace with your actual API
    String operatorId = 'default_operator',
    String operatorName = 'Default Operator',
  }) async {
    if (_isInitialized) {
      debugPrint('Upload queue already initialized');
      return;
    }

    try {
      debugPrint('Initializing upload queue system...');
      
      // Initialize the upload queue manager
      await UploadQueueManager.instance.initialize(
        uploadBaseUrl: uploadBaseUrl,
      );
      
      // Start a visit session (you'll call this when user selects a store)
      VisitSessionManager.instance.startVisit(
        operatorId: operatorId,
        operatorName: operatorName,
        storeId: 'temp_store', // Will be updated when user selects store
        storeName: 'Temporary Store', // Will be updated when user selects store
      );
      
      _isInitialized = true;
      debugPrint('Upload queue system initialized successfully');
      debugPrint('Operator: $operatorName ($operatorId)');
      debugPrint('Upload URL: $uploadBaseUrl');
      
    } catch (e) {
      debugPrint('Failed to initialize upload queue: $e');
      rethrow;
    }
  }
  
  static bool get isInitialized => _isInitialized;
  
  static void startNewVisit({
    required String operatorId,
    required String operatorName, 
    required String storeId,
    required String storeName,
  }) {
    VisitSessionManager.instance.startVisit(
      operatorId: operatorId,
      operatorName: operatorName,
      storeId: storeId,
      storeName: storeName,
    );
    
    debugPrint('New visit started: $storeName');
  }
  
  static void updateLocation({
    String? area,
    String? aisle,
    String? segment,
    InstallationType? installationType,
    int? aisleNumber,
  }) {
    VisitSessionManager.instance.updateLocation(
      area: area,
      aisle: aisle,
      segment: segment,
      installationType: installationType,
      aisleNumber: aisleNumber,
    );
  }
  
  static void endVisit() {
    VisitSessionManager.instance.endVisit();
    debugPrint('Visit ended');
  }
}
