// IMMEDIATE DEBUG FIX - Force cleanup and API test
import 'package:flutter/material.dart';
import '../services/store_service_debug.dart';
import '../core/upload_queue/upload_queue_cleanup.dart';
import '../core/upload_queue/upload_queue_manager.dart';
import '../core/upload_queue/upload_database.dart';

class ImmediateDebugFix extends StatefulWidget {
  const ImmediateDebugFix({super.key});

  @override
  State<ImmediateDebugFix> createState() => _ImmediateDebugFixState();
}

class _ImmediateDebugFixState extends State<ImmediateDebugFix> {
  String _results = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IMMEDIATE DEBUG FIX')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'CRITICAL FIXES',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _forceCleanupNow,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('FORCE CLEANUP QUEUE NOW'),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _directApiTest,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('DIRECT API TEST'),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _testExactStoreApiCall,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text('TEST EXACT STORE API CALL'),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _showRawQueueData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('SHOW RAW QUEUE DATA'),
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _results,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _forceCleanupNow() async {
    setState(() {
      _results = 'FORCING IMMEDIATE CLEANUP...\n\n';
    });

    try {
      // Get all uploads before cleanup
      final beforeUploads = await UploadQueueDatabase.getAllUploads();
      setState(() {
        _results += 'BEFORE CLEANUP: ${beforeUploads.length} items total\n';
        for (final upload in beforeUploads) {
          _results += '  - ${upload.id}: ${upload.status.name} (${upload.metadata.originalFilename})\n';
        }
        _results += '\n';
      });

      // Force manual cleanup
      final deletedCount = await UploadQueueCleanup.cleanupNow();
      
      // Get uploads after cleanup
      final afterUploads = await UploadQueueDatabase.getAllUploads();
      setState(() {
        _results += 'CLEANUP COMPLETE: Deleted $deletedCount items\n';
        _results += 'AFTER CLEANUP: ${afterUploads.length} items remaining\n';
        for (final upload in afterUploads) {
          _results += '  - ${upload.id}: ${upload.status.name} (${upload.metadata.originalFilename})\n';
        }
        _results += '\n';
      });

      // Force queue refresh
      await UploadQueueManager.instance.getStats();
      
      setState(() {
        _results += 'QUEUE REFRESHED - Check your main app now!\n\n';
      });

    } catch (e) {
      setState(() {
        _results += 'ERROR DURING CLEANUP: $e\n\n';
      });
    }
  }

  Future<void> _directApiTest() async {
    setState(() {
      _results += 'TESTING STORE API DIRECTLY...\n\n';
    });

    try {
      final result = await StoreServiceDebug.testStoresApiEnhanced();
      setState(() {
        _results += 'DIRECT API TEST RESULT: $result\n';
        _results += 'Check the console for detailed API logs!\n\n';
      });
    } catch (e) {
      setState(() {
        _results += 'DIRECT API TEST ERROR: $e\n\n';
      });
    }
  }

  Future<void> _testExactStoreApiCall() async {
    setState(() {
      _results += 'TESTING EXACT STORE API CALL (same as StoreService.getNearestStores)...\n\n';
    });

    try {
      final result = await StoreServiceDebug.testExactStoreApiCall();
      setState(() {
        _results += 'EXACT STORE API CALL RESULT: $result\n';
        _results += 'This tests the EXACT same call as your store loading!\n';
        _results += 'Check console for detailed 🎯 EXACT API TEST logs!\n\n';
      });
    } catch (e) {
      setState(() {
        _results += 'EXACT STORE API CALL ERROR: $e\n\n';
      });
    }
  }

  Future<void> _showRawQueueData() async {
    setState(() {
      _results += 'GETTING RAW QUEUE DATA...\n\n';
    });

    try {
      // Get all uploads from database
      final allUploads = await UploadQueueDatabase.getAllUploads();
      final stats = await UploadQueueManager.instance.getStats();

      setState(() {
        _results += 'RAW DATABASE DATA:\n';
        _results += 'Total items in DB: ${allUploads.length}\n\n';
        
        final byStatus = <String, int>{};
        for (final upload in allUploads) {
          final status = upload.status.name;
          byStatus[status] = (byStatus[status] ?? 0) + 1;
        }
        
        _results += 'STATUS BREAKDOWN:\n';
        byStatus.forEach((status, count) {
          _results += '  $status: $count\n';
        });
        
        _results += '\nMANAGER STATS:\n';
        stats.forEach((key, value) {
          _results += '  $key: $value\n';
        });
        
        _results += '\nDETAILED ITEMS:\n';
        for (final upload in allUploads) {
          _results += '${upload.id}: ${upload.status.name} - ${upload.metadata.originalFilename}\n';
          _results += '  Created: ${upload.createdAt}\n';
          _results += '  Last Attempt: ${upload.lastAttemptAt}\n';
          _results += '  Server URL: ${upload.serverUrl ?? "none"}\n\n';
        }
      });

    } catch (e) {
      setState(() {
        _results += 'ERROR GETTING QUEUE DATA: $e\n\n';
      });
    }
  }
}
