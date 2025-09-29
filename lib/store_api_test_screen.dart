import 'package:flutter/material.dart';
import 'services/store_service_fixed.dart';

class StoreApiTestScreen extends StatefulWidget {
  const StoreApiTestScreen({super.key});

  @override
  State<StoreApiTestScreen> createState() => _StoreApiTestScreenState();
}

class _StoreApiTestScreenState extends State<StoreApiTestScreen> {
  String _testResults = 'Tap a button to test...';
  bool _isTesting = false;

  Future<void> _testDownloadAllStores() async {
    setState(() {
      _isTesting = true;
      _testResults = 'Testing download all stores...';
    });

    try {
      final stores = await StoreServiceFixed.downloadAllStores();
      
      setState(() {
        _testResults = '''
✅ DOWNLOAD SUCCESS
==================
Stores downloaded: ${stores.length}

First 3 stores:
${stores.take(3).map((s) => '• ${s['name'] ?? s['store_name'] ?? 'Unknown'} (${s['suburb'] ?? s['city'] ?? 'Unknown location'})').join('\n')}

Keys in first store:
${stores.isNotEmpty ? stores.first.keys.join(', ') : 'N/A'}
        ''';
      });
    } catch (e) {
      setState(() {
        _testResults = '❌ ERROR: $e';
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _testGetNearestStores() async {
    setState(() {
      _isTesting = true;
      _testResults = 'Testing get nearest stores...';
    });

    try {
      final stores = await StoreServiceFixed.getNearestStores();
      
      setState(() {
        _testResults = '''
✅ NEAREST STORES SUCCESS
========================
Stores found: ${stores.length}

Nearest stores:
${stores.map((s) => '• ${s['name'] ?? 'Unknown'} - ${(s['distance'] ?? 0.0).toStringAsFixed(1)}km').join('\n')}
        ''';
      });
    } catch (e) {
      setState(() {
        _testResults = '❌ ERROR: $e';
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _runFullTest() async {
    setState(() {
      _isTesting = true;
      _testResults = 'Running full test suite...';
    });

    await StoreServiceFixed.testStoreService();
    
    setState(() {
      _testResults = 'Full test complete - check console for detailed logs';
      _isTesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store API Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isTesting ? null : _testDownloadAllStores,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Test Download All Stores'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isTesting ? null : _testGetNearestStores,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Test Get Nearest Stores'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isTesting ? null : _runFullTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Run Full Test (Check Console)'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
