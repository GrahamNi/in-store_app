import 'package:flutter/material.dart';
import 'dart:async';
import 'core/design_system.dart';
import 'components/app_components.dart';
import 'core/upload_queue/upload_queue.dart';

class UploadQueueScreen extends StatefulWidget {
  const UploadQueueScreen({super.key});

  @override
  State<UploadQueueScreen> createState() => _UploadQueueScreenState();
}

class _UploadQueueScreenState extends State<UploadQueueScreen>
    with TickerProviderStateMixin {
  List<UploadQueueItem> uploadQueue = [];
  bool isUploading = false;
  bool isWifiOnly = true;
  bool autoPause = true;
  String statusMessage = 'Initializing...';
  late AnimationController _refreshController;
  
  StreamSubscription<List<UploadQueueItem>>? _queueSubscription;
  StreamSubscription<String>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: AppDesignSystem.animationStandard,
      vsync: this,
    );
    _initializeUploadQueue();
  }

  void _initializeUploadQueue() async {
    try {
      // 🔧 FIX: Ensure uploadQueue is always initialized as a proper List
      setState(() {
        uploadQueue = <UploadQueueItem>[]; // Explicitly typed as List<UploadQueueItem>
        statusMessage = 'Loading queue...';
      });
      
      // Check if upload queue is initialized
      if (!UploadQueueManager.instance.isInitialized) {
        setState(() {
          statusMessage = 'Upload queue not initialized';
          uploadQueue = <UploadQueueItem>[]; // Ensure empty list, not null
        });
        return;
      }

      // FORCE REFRESH THE QUEUE DATA - Get directly from database
      final currentQueue = await UploadQueueDatabase.getAllUploads();
      debugPrint('🔥 FORCED QUEUE REFRESH: ${currentQueue.length} items loaded');
      
      // 🔧 FIX: Verify we have a proper List before setting state
      if (currentQueue is List<UploadQueueItem>) {
        setState(() {
          uploadQueue = currentQueue;
        });
        debugPrint('✅ Queue set successfully with ${uploadQueue.length} items');
      } else {
        debugPrint('❌ ERROR: currentQueue is not a List<UploadQueueItem>: ${currentQueue.runtimeType}');
        setState(() {
          uploadQueue = <UploadQueueItem>[];
          statusMessage = 'Error: Invalid queue data type';
        });
        return;
      }

      // Subscribe to queue updates
      _queueSubscription = UploadQueueManager.instance.queueStream.listen((queue) {
        if (mounted) {
          debugPrint('📊 QUEUE SCREEN: Received ${queue.length} items');
          
          // 🔧 FIX: Verify queue is a proper List before using it
          if (queue is List<UploadQueueItem>) {
            for (var item in queue) {
              debugPrint('📊 QUEUE SCREEN: ${item.id} - ${item.status} - ${item.metadata.originalFilename}');
            }
            
            setState(() {
              uploadQueue = queue;
              // Update button state based on actual queue activity
              isUploading = queue.any((item) => item.status == UploadStatus.uploading) || 
                          (UploadQueueManager.instance.isProcessing && pendingCount > 0);
            });
            
            debugPrint('📊 QUEUE SCREEN: Counters - Pending: $pendingCount, Done: $completedCount, Failed: $failedCount, Total: $totalCount');
            
            // Stop animation when all uploads are done
            if (!isUploading && _refreshController.isAnimating) {
              _refreshController.stop();
              _refreshController.reset();
            }
          } else {
            debugPrint('❌ ERROR: Queue stream data is not a List<UploadQueueItem>: ${queue.runtimeType}');
            setState(() {
              uploadQueue = <UploadQueueItem>[];
              statusMessage = 'Error: Invalid queue stream data';
            });
          }
        }
      });

      // Subscribe to status updates
      _statusSubscription = UploadQueueManager.instance.statusStream.listen((status) {
        if (mounted) {
          setState(() {
            statusMessage = status;
          });
        }
      });

      // Initial state
      setState(() {
        isUploading = UploadQueueManager.instance.isProcessing;
      });

    } catch (e) {
      debugPrint('❌ ERROR in _initializeUploadQueue: $e');
      setState(() {
        statusMessage = 'Error: $e';
        uploadQueue = <UploadQueueItem>[]; // Ensure we always have a valid list
      });
    }
  }

  void _startUploads() {
    AppHaptics.light();
    setState(() {
      isUploading = true;
    });
    _refreshController.repeat();
    
    UploadQueueManager.instance.resumeUploads();
  }

  void _pauseUploads() {
    AppHaptics.light();
    setState(() {
      isUploading = false;
    });
    _refreshController.stop();
    
    UploadQueueManager.instance.pauseUploads();
  }

  void _retryUpload(String uploadId) {
    AppHaptics.light();
    UploadQueueManager.instance.retryUpload(uploadId);
  }

  void _deleteItem(String uploadId) {
    AppHaptics.light();
    UploadQueueManager.instance.deleteUpload(uploadId);
  }

  void _clearCompleted() {
    AppHaptics.light();
    UploadQueueManager.instance.clearCompleted();
  }

  int get pendingCount {
    // 🔧 FIX: Add null safety check
    if (uploadQueue.isEmpty) return 0;
    
    debugPrint('COUNTER DEBUG: Total queue items: ${uploadQueue.length}');
    final pending = uploadQueue.where((item) => 
        item.status == UploadStatus.pending || 
        item.status == UploadStatus.uploading ||
        item.status == UploadStatus.paused).length;
    debugPrint('COUNTER DEBUG: Pending count: $pending');
    return pending;
  }

  int get completedCount {
    // 🔧 FIX: Add null safety check
    if (uploadQueue.isEmpty) return 0;
    
    final completed = uploadQueue.where((item) => 
        item.status == UploadStatus.completed).length;
    debugPrint('COUNTER DEBUG: Completed count: $completed');
    return completed;
  }

  int get failedCount {
    // 🔧 FIX: Add null safety check
    if (uploadQueue.isEmpty) return 0;
    
    final failed = uploadQueue.where((item) => 
        item.status == UploadStatus.failed ||
        item.status == UploadStatus.stuck).length;
    debugPrint('COUNTER DEBUG: Failed count: $failed');
    return failed;
  }

  int get totalCount {
    // 🔧 FIX: Add null safety check
    return uploadQueue.length;
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _queueSubscription?.cancel();
    _statusSubscription?.cancel();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    // 🔧 FIX: Add debug print to check what we're about to render
    debugPrint('🎨 RENDERING: uploadQueue.length = ${uploadQueue.length}');
    debugPrint('🎨 RENDERING: uploadQueue.runtimeType = ${uploadQueue.runtimeType}');

    return Scaffold(
      backgroundColor: AppDesignSystem.systemGroupedBackground,
      body: SafeArea(
        child: Column(
          children: [
            // App bar with status
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isSmallScreen ? 12 : AppDesignSystem.spacingMd),
              decoration: BoxDecoration(
                color: AppDesignSystem.systemBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload Queue',
                              style: AppDesignSystem.title2.copyWith(
                                color: AppDesignSystem.labelPrimary,
                                fontSize: isSmallScreen ? 18 : null,
                              ),
                            ),
                            // Total counter
                            Text(
                              '$totalCount images in queue',
                              style: AppDesignSystem.caption1.copyWith(
                                color: AppDesignSystem.systemBlue,
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (completedCount > 0)
                        AppTextButton(
                          onPressed: _clearCompleted,
                          child: Text(
                            isSmallScreen ? 'Clear' : 'Clear Completed',
                            style: AppDesignSystem.caption1.copyWith(
                              color: AppDesignSystem.primaryOrange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  // Status message
                  if (statusMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppDesignSystem.systemBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppDesignSystem.systemBlue.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppDesignSystem.systemBlue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              statusMessage,
                              style: AppDesignSystem.caption2.copyWith(
                                color: AppDesignSystem.systemBlue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Status summary and controls
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isSmallScreen ? 12 : AppDesignSystem.spacingMd),
              decoration: BoxDecoration(
                color: AppDesignSystem.systemBackground,
                border: Border(
                  top: BorderSide(
                    color: AppDesignSystem.systemGray5,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          'Pending',
                          pendingCount,
                          AppDesignSystem.systemOrange,
                          Icons.schedule,
                          isSmallScreen,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Expanded(
                        child: _buildStatusCard(
                          'Done',
                          completedCount,
                          AppDesignSystem.systemGreen,
                          Icons.check_circle,
                          isSmallScreen,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Expanded(
                        child: _buildStatusCard(
                          'Failed',
                          failedCount,
                          AppDesignSystem.systemRed,
                          Icons.error,
                          isSmallScreen,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  
                  // Control button
                  SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      onPressed: isUploading ? _pauseUploads : _startUploads,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _refreshController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _refreshController.value * 2 * 3.14159,
                                child: Icon(
                                  isUploading ? Icons.pause : Icons.cloud_upload,
                                  size: AppDesignSystem.iconMd,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(isUploading ? 'Pause Uploads' : 'Start Uploads'),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  
                  // Network and battery info
                  if (UploadQueueManager.instance.isInitialized)
                    _buildNetworkInfo(isSmallScreen),
                ],
              ),
            ),
            
            // Upload queue list
            Expanded(
              child: Container(
                width: double.infinity,
                child: uploadQueue.isEmpty
                    ? _buildEmptyState(isSmallScreen)
                    : ListView.builder(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : AppDesignSystem.spacingMd),
                        itemCount: uploadQueue.length, // 🔧 FIX: Use .length property
                        itemBuilder: (context, index) {
                          // 🔧 FIX: Add bounds check
                          if (index < 0 || index >= uploadQueue.length) {
                            debugPrint('❌ ERROR: Index out of bounds: $index >= ${uploadQueue.length}');
                            return Container();
                          }
                          
                          final item = uploadQueue[index];
                          debugPrint('🎨 RENDERING ITEM: ${item.id} at index $index');
                          
                          return _buildUploadItem(item, isSmallScreen);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkInfo(bool isSmallScreen) {
    final network = UploadQueueManager.instance.networkConditions;
    final batteryLevel = UploadQueueManager.instance.batteryLevel;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: AppDesignSystem.systemGray6,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            network.isConnected 
                ? (network.type == NetworkType.wifi ? Icons.wifi : Icons.signal_cellular_4_bar)
                : Icons.signal_cellular_off,
            size: 16,
            color: network.isConnected ? AppDesignSystem.systemGreen : AppDesignSystem.systemRed,
          ),
          const SizedBox(width: 8),
          Text(
            network.type.name.toUpperCase(),
            style: AppDesignSystem.caption2.copyWith(
              fontSize: isSmallScreen ? 10 : 12,
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.battery_std,
            size: 16,
            color: batteryLevel < 20 ? AppDesignSystem.systemRed : AppDesignSystem.systemGreen,
          ),
          const SizedBox(width: 4),
          Text(
            '$batteryLevel%',
            style: AppDesignSystem.caption2.copyWith(
              fontSize: isSmallScreen ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String label, int count, Color color, IconData icon, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon, 
            color: color, 
            size: isSmallScreen ? 20 : 24,
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            count.toString(),
            style: AppDesignSystem.title3.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: isSmallScreen ? 16 : 18,
            ),
          ),
          Text(
            label,
            style: AppDesignSystem.caption2.copyWith(
              color: AppDesignSystem.labelSecondary,
              fontSize: isSmallScreen ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadItem(UploadQueueItem item, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      child: AppCard(
        backgroundColor: AppDesignSystem.secondarySystemGroupedBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // File type icon
                Container(
                  width: isSmallScreen ? 36 : 40,
                  height: isSmallScreen ? 36 : 40,
                  decoration: BoxDecoration(
                    color: item.metadata.captureType == 'scene' 
                        ? AppDesignSystem.systemBlue.withOpacity(0.1)
                        : AppDesignSystem.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
                  ),
                  child: Icon(
                    item.metadata.captureType == 'scene' 
                        ? Icons.panorama_wide_angle
                        : Icons.label,
                    color: item.metadata.captureType == 'scene' 
                        ? AppDesignSystem.systemBlue
                        : AppDesignSystem.primaryOrange,
                    size: isSmallScreen ? 18 : 20,
                  ),
                ),
                
                SizedBox(width: isSmallScreen ? 8 : 12),
                
                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.metadata.originalFilename.length > (isSmallScreen ? 25 : 35)
                            ? '${item.metadata.originalFilename.substring(0, isSmallScreen ? 25 : 35)}...'
                            : item.metadata.originalFilename,
                        style: AppDesignSystem.footnote.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallScreen ? 1 : 2),
                      Text(
                        '${item.metadata.storeName} • ${item.metadata.area ?? 'No area'} • ${item.metadata.captureType}',
                        style: AppDesignSystem.caption2.copyWith(
                          color: AppDesignSystem.labelSecondary,
                          fontSize: isSmallScreen ? 10 : 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallScreen ? 1 : 2),
                      Text(
                        '${item.formattedFileSize} • ${_formatTime(item.metadata.captureTimestamp)}',
                        style: AppDesignSystem.caption2.copyWith(
                          color: AppDesignSystem.labelTertiary,
                          fontSize: isSmallScreen ? 9 : 11,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status icon and actions
                _buildStatusIcon(item, isSmallScreen),
              ],
            ),
            
            // Progress bar
            if (item.status == UploadStatus.uploading)
              Container(
                margin: EdgeInsets.only(top: isSmallScreen ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: item.progress,
                      backgroundColor: AppDesignSystem.systemGray5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        item.metadata.captureType == 'scene' 
                            ? AppDesignSystem.systemBlue
                            : AppDesignSystem.primaryOrange,
                      ),
                      minHeight: isSmallScreen ? 2 : 3,
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      '${(item.progress * 100).toInt()}% uploaded',
                      style: AppDesignSystem.caption2.copyWith(
                        color: AppDesignSystem.labelTertiary,
                        fontSize: isSmallScreen ? 9 : 11,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Error message
            if ((item.status == UploadStatus.failed || item.status == UploadStatus.stuck) && item.errorMessage != null)
              Container(
                margin: EdgeInsets.only(top: isSmallScreen ? 6 : 8),
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: AppDesignSystem.systemRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
                  border: Border.all(color: AppDesignSystem.systemRed.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.status == UploadStatus.stuck ? Icons.warning : Icons.error_outline,
                      size: isSmallScreen ? 14 : 16,
                      color: AppDesignSystem.systemRed,
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    Expanded(
                      child: Text(
                        item.status == UploadStatus.stuck 
                            ? 'Upload stuck (${item.retryCount} retries)'
                            : '${item.errorMessage} (${item.retryCount} retries)',
                        style: AppDesignSystem.caption2.copyWith(
                          fontSize: isSmallScreen ? 10 : 12,
                          color: AppDesignSystem.systemRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(UploadQueueItem item, bool isSmallScreen) {
    final iconSize = isSmallScreen ? 18.0 : 20.0;
    
    switch (item.status) {
      case UploadStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule,
              color: AppDesignSystem.systemOrange,
              size: iconSize,
            ),
            AppIconButton(
              icon: Icons.delete_outline,
              onPressed: () => _deleteItem(item.id),
              color: AppDesignSystem.systemGray,
              iconSize: iconSize,
            ),
          ],
        );
        
      case UploadStatus.uploading:
        return SizedBox(
          width: iconSize,
          height: iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              item.metadata.captureType == 'scene' 
                  ? AppDesignSystem.systemBlue
                  : AppDesignSystem.primaryOrange,
            ),
          ),
        );
        
      case UploadStatus.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: AppDesignSystem.systemGreen,
              size: iconSize,
            ),
            AppIconButton(
              icon: Icons.delete_outline,
              onPressed: () => _deleteItem(item.id),
              color: AppDesignSystem.systemGray,
              iconSize: iconSize,
            ),
          ],
        );
        
      case UploadStatus.failed:
      case UploadStatus.stuck:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconButton(
              icon: Icons.refresh,
              onPressed: () => _retryUpload(item.id),
              color: AppDesignSystem.systemBlue,
              iconSize: iconSize,
            ),
            AppIconButton(
              icon: Icons.delete_outline,
              onPressed: () => _deleteItem(item.id),
              color: AppDesignSystem.systemGray,
              iconSize: iconSize,
            ),
          ],
        );
        
      case UploadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pause_circle,
              color: AppDesignSystem.systemGray,
              size: iconSize,
            ),
            AppIconButton(
              icon: Icons.delete_outline,
              onPressed: () => _deleteItem(item.id),
              color: AppDesignSystem.systemGray,
              iconSize: iconSize,
            ),
          ],
        );
    }
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_done,
            size: isSmallScreen ? 64 : 80,
            color: AppDesignSystem.systemGray3,
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            'No uploads in queue',
            style: AppDesignSystem.title3.copyWith(
              color: AppDesignSystem.labelSecondary,
              fontSize: isSmallScreen ? 16 : 18,
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(
            'All your captures have been uploaded',
            style: AppDesignSystem.footnote.copyWith(
              color: AppDesignSystem.labelTertiary,
              fontSize: isSmallScreen ? 12 : 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
