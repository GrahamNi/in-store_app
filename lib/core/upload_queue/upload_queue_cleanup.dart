// Upload Queue Auto-Cleanup Fix
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'upload_database.dart';
import 'upload_models.dart';

class UploadQueueCleanup {
  static Timer? _autoCleanupTimer;
  
  // Start automatic cleanup of completed uploads
  static void startAutoCleanup() {
    // Clean up completed uploads every 2 minutes
    _autoCleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      try {
        debugPrint('🧹 AUTO-CLEANUP: Starting automatic cleanup...');
        
        // Get all uploads
        final allUploads = await UploadQueueDatabase.getAllUploads();
        final completed = allUploads.where((u) => u.status == UploadStatus.completed).toList();
        
        debugPrint('🧹 AUTO-CLEANUP: Found ${completed.length} completed uploads to clean');
        
        if (completed.isNotEmpty) {
          // Only keep the most recent 5 completed uploads
          if (completed.length > 5) {
            // Sort by completion time (newest first)
            completed.sort((a, b) => b.lastAttemptAt.compareTo(a.lastAttemptAt));
            
            // Remove all but the 5 most recent
            final toDelete = completed.skip(5).toList();
            
            for (final upload in toDelete) {
              await UploadQueueDatabase.deleteUpload(upload.id);
              debugPrint('🧹 AUTO-CLEANUP: Deleted completed upload: ${upload.metadata.originalFilename}');
            }
            
            debugPrint('🧹 AUTO-CLEANUP: Cleaned up ${toDelete.length} old completed uploads');
          }
        }
        
        // Also clean up failed uploads older than 24 hours
        final oldFailed = allUploads.where((u) => 
          u.status == UploadStatus.failed && 
          DateTime.now().difference(u.lastAttemptAt).inHours > 24
        ).toList();
        
        for (final upload in oldFailed) {
          await UploadQueueDatabase.deleteUpload(upload.id);
          debugPrint('🧹 AUTO-CLEANUP: Deleted old failed upload: ${upload.metadata.originalFilename}');
        }
        
        if (oldFailed.isNotEmpty) {
          debugPrint('🧹 AUTO-CLEANUP: Cleaned up ${oldFailed.length} old failed uploads');
        }
        
        debugPrint('🧹 AUTO-CLEANUP: Cleanup complete');
        
      } catch (e) {
        debugPrint('🧹 AUTO-CLEANUP: Error during cleanup: $e');
      }
    });
    
    debugPrint('🧹 AUTO-CLEANUP: Auto-cleanup started (every 2 minutes)');
  }
  
  static void stopAutoCleanup() {
    _autoCleanupTimer?.cancel();
    _autoCleanupTimer = null;
    debugPrint('🧹 AUTO-CLEANUP: Auto-cleanup stopped');
  }
  
  // Manual cleanup method
  static Future<int> cleanupNow() async {
    try {
      debugPrint('🧹 MANUAL CLEANUP: Starting manual cleanup...');
      
      final allUploads = await UploadQueueDatabase.getAllUploads();
      final completed = allUploads.where((u) => u.status == UploadStatus.completed).toList();
      
      int deletedCount = 0;
      
      // Delete all but the 3 most recent completed uploads
      if (completed.length > 3) {
        completed.sort((a, b) => b.lastAttemptAt.compareTo(a.lastAttemptAt));
        final toDelete = completed.skip(3).toList();
        
        for (final upload in toDelete) {
          await UploadQueueDatabase.deleteUpload(upload.id);
          deletedCount++;
        }
      }
      
      debugPrint('🧹 MANUAL CLEANUP: Cleaned up $deletedCount uploads');
      return deletedCount;
      
    } catch (e) {
      debugPrint('🧹 MANUAL CLEANUP: Error: $e');
      return 0;
    }
  }
}
