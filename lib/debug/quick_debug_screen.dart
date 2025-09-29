// Quick Debug Test Screen
import 'package:flutter/material.dart';
import '../services/store_service_debug.dart';
import '../core/upload_queue/upload_queue_cleanup.dart';
import '../core/upload_queue/upload_queue_manager.dart';

class QuickDebugScreen extends StatefulWidget {
  const QuickDebugScreen({super.key});

  @override
  State<QuickDebugScreen> createState() => _QuickDebugScreenState();
}

class _QuickDebugScreenState extends State<QuickDebugScreen> {
  String _testResults = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Debug Tests')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _testStoreAPI,
              child: Text('Test Store API (Enhanced)'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cleanupQueue,
              child: Text('Cleanup Upload Queue'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _getQueueStats,
              child: Text('Get Queue Stats'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_testResults),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testStoreAPI() async {
    setState(() {
      _testResults = 'Testing Store API...\n\n';
    });

    final result = await StoreServiceDebug.testStoresApiEnhanced();
    
    setState(() {
      _testResults += 'Store API Test Result: $result\n';
      _testResults += '(Check console/logs for detailed output)\n\n';
    });
  }

  Future<void> _cleanupQueue() async {
    setState(() {
      _testResults += 'Cleaning upload queue...\n';
    });

    final deletedCount = await UploadQueueCleanup.cleanupNow();
    
    setState(() {
      _testResults += 'Cleaned up $deletedCount uploads\n\n';
    });
  }

  Future<void> _getQueueStats() async {
    setState(() {
      _testResults += 'Getting queue stats...\n';
    });

    final stats = await UploadQueueManager.instance.getStats();
    
    setState(() {
      _testResults += 'Queue Stats:\n';
      stats.forEach((key, value) {
        _testResults += '  $key: $value\n';
      });
      _testResults += '\n';
    });
  }
}
