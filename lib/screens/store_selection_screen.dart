import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'location_selection_screen.dart';
import 'queue_screen.dart';

class Store {
  final String id;
  final String name;
  final String chain;
  final String address;
  final double latitude;
  final double longitude;
  double? distance;
  String? walkingTime;

  Store({
    required this.id,
    required this.name,
    required this.chain,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.distance,
    this.walkingTime,
  });
}

class StoreSelectionScreen extends StatefulWidget {
  final bool isFirstTime;
  
  const StoreSelectionScreen({super.key, this.isFirstTime = false});

  @override
  State<StoreSelectionScreen> createState() => _StoreSelectionScreenState();
}

class _StoreSelectionScreenState extends State<StoreSelectionScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Store> stores = [];
  List<Store> filteredStores = [];
  bool isLoading = true;
  String searchQuery = '';

  final List<Store> mockStores = [
    Store(id: '001', name: 'Coles Charlestown', chain: 'Coles', address: '30 Pearson Street, Charlestown', latitude: -32.9647, longitude: 151.6928, distance: 2.1, walkingTime: '25 min'),
    Store(id: '002', name: 'Woolworths Kotara', chain: 'Woolworths', address: 'Northcott Drive, Kotara', latitude: -32.9404, longitude: 151.7071, distance: 3.8, walkingTime: '45 min'),
    Store(id: '003', name: 'IGA Newcastle West', chain: 'IGA', address: '166 Parry Street, Newcastle West', latitude: -32.9273, longitude: 151.7817, distance: 5.2, walkingTime: '1 hr 2 min'),
    Store(id: '004', name: 'ALDI Jesmond', chain: 'ALDI', address: 'Blue Gum Road, Jesmond', latitude: -32.9123, longitude: 151.7456, distance: 4.1, walkingTime: '48 min'),
  ];

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    await Future.delayed(const Duration(seconds: 1));
    stores = List.from(mockStores);
    stores.sort((a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999));
    filteredStores = List.from(stores);
    setState(() {
      isLoading = false;
    });
  }

  void _filterStores(String query) {
    setState(() {
      searchQuery = query;
      filteredStores = query.isEmpty
          ? List.from(stores)
          : stores.where((store) =>
              store.name.toLowerCase().contains(query.toLowerCase()) ||
              store.chain.toLowerCase().contains(query.toLowerCase()) ||
              store.address.toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  Future<void> _selectStore(Store store) async {
    // Check for active session or create new
    var session = await _db.getActiveSession(store.id);
    String sessionId;
    
    if (session == null) {
      sessionId = await _db.startSession(
        storeId: store.id,
        storeName: store.name,
        profile: 'EOA',
      );
    } else {
      sessionId = session['id'];
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSelectionScreen(
          storeId: store.id,
          storeName: store.name,
          sessionId: sessionId,
        ),
      ),
    );
  }

  void _openQueue(Store store) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QueueScreen(storeId: store.id),
      ),
    );
  }

  Color _getChainColor(String chain) {
    switch (chain.toLowerCase()) {
      case 'coles':
        return const Color(0xFFE31E24);
      case 'woolworths':
        return const Color(0xFF0F7B0F);
      case 'iga':
        return const Color(0xFFFF6B35);
      case 'aldi':
        return const Color(0xFF0066CC);
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Select Store', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterStores,
              decoration: InputDecoration(
                hintText: 'Search stores...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredStores.length,
              itemBuilder: (context, index) {
                final store = filteredStores[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(Icons.store, color: _getChainColor(store.chain)),
                    title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${store.address}\n${store.distance} km • ${store.walkingTime}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.queue), onPressed: () => _openQueue(store)),
                        const Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                    onTap: () => _selectStore(store),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
