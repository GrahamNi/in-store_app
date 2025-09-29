import 'package:flutter/material.dart';
import '../services/database_helper.dart';

class QueueScreen extends StatefulWidget {
  final String storeId;

  const QueueScreen({super.key, required this.storeId});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  
  int _queueCount = 0;
  int _todaySyncedCount = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _queueItems = [];

  @override
  void initState() {
    super.initState();
    _loadQueueData();
  }

  Future<void> _loadQueueData() async {
    setState(() {
      _isLoading = true;
    });

    final queueCount = await _db.getQueueCount();
    final syncedCount = await _db.getTodaysSyncedCount(widget.storeId);
    final pendingItems = await _db.getPendingUploads();

    setState(() {
      _queueCount = queueCount;
      _todaySyncedCount = syncedCount;
      _queueItems = pendingItems;
      _isLoading = false;
    });
  }

  Future<void> _simulateUpload() async {
    if (_queueItems.isEmpty) return;
    
    // Simulate uploading first item
    final firstItem = _queueItems.first;
    await Future.delayed(const Duration(seconds: 1));
    await _db.markAsSynced(firstItem['id']);
    
    await _loadQueueData(); // Refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Queue'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('In Queue', _queueCount, Colors.orange),
                      _buildStatCard('Sent Today', _todaySyncedCount, Colors.green),
                    ],
                  ),
                ),
                
                // Queue Items
                Expanded(
                  child: _queueItems.isEmpty
                      ? const Center(child: Text('Queue is empty'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _queueItems.length,
                          itemBuilder: (context, index) {
                            final item = _queueItems[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(Icons.image, color: Colors.blue),
                                title: Text('${item['area'] ?? 'Unknown'} - ${item['aisle'] ?? 'Unknown'}'),
                                subtitle: Text('${item['segment'] ?? 'Unknown'} • ${item['store_name'] ?? 'Unknown Store'}'),
                                trailing: Text(
                                  item['upload_status'] ?? 'pending',
                                  style: TextStyle(
                                    color: item['upload_status'] == 'synced' ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _queueItems.isEmpty ? null : _simulateUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Simulate Upload', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }
}
