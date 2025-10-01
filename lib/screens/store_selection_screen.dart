import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/app_models.dart';
import '../services/database_helper.dart';
import 'location_selection_screen.dart';
import 'queue_screen.dart';

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
  bool locationPermissionGranted = false;
  Position? userPosition;

  @override
  void initState() {
    super.initState();
    _requestLocationAndLoadStores();
  }

  Future<void> _requestLocationAndLoadStores() async {
    // Request location permission
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('⚠️ Location services are disabled.');
      await _loadStores();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ Location permissions are denied');
        await _loadStores();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('⚠️ Location permissions are permanently denied');
      await _loadStores();
      return;
    }

    // Permission granted - get current position
    try {
      userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      setState(() {
        locationPermissionGranted = true;
      });
      debugPrint('✅ Location permission granted: ${userPosition!.latitude}, ${userPosition!.longitude}');
    } catch (e) {
      debugPrint('⚠️ Error getting location: $e');
    }

    await _loadStores();
  }

  Future<void> _loadStores() async {
    try {
      debugPrint('📍 Loading stores from SQLite cache...');
      
      // Load stores from SQLite cache
      final storesData = await _db.loadStoresCache();
      
      debugPrint('📍 Loaded ${storesData.length} stores from cache');

      // Convert to Store objects and calculate distances
      stores = storesData.map((storeMap) {
        final store = Store(
          id: storeMap['id'] as String,
          name: storeMap['name'] as String,
          chain: storeMap['chain'] as String? ?? '',
          address: storeMap['address'] as String? ?? '',
          latitude: (storeMap['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (storeMap['longitude'] as num?)?.toDouble() ?? 0.0,
        );

        // Calculate distance from user's location if available
        if (userPosition != null) {
          final distanceInMeters = Geolocator.distanceBetween(
            userPosition!.latitude,
            userPosition!.longitude,
            store.latitude,
            store.longitude,
          );
          store.distance = distanceInMeters / 1000; // Convert to km
        }

        return store;
      }).toList();

      // Sort by distance if we have location, otherwise alphabetically
      if (locationPermissionGranted && userPosition != null) {
        stores.sort((a, b) => (a.distance ?? 999999).compareTo(b.distance ?? 999999));
        debugPrint('✅ Sorted ${stores.length} stores by distance');
      } else {
        stores.sort((a, b) => a.name.compareTo(b.name));
        debugPrint('✅ Sorted ${stores.length} stores alphabetically');
      }

      filteredStores = List.from(stores);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading stores: $e');
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load stores: $e')),
        );
      }
    }
  }

  void _filterStores(String query) {
    setState(() {
      searchQuery = query;
      filteredStores = query.isEmpty
          ? List.from(stores)
          : stores
              .where((store) =>
                  store.name.toLowerCase().contains(query.toLowerCase()) ||
                  store.chain.toLowerCase().contains(query.toLowerCase()) ||
                  store.address.toLowerCase().contains(query.toLowerCase()))
              .toList();
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

    if (mounted) {
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

  String _formatDistance(double? distance) {
    if (distance == null) return '';
    return '${distance.toStringAsFixed(1)} km';
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
        title: const Text('Select Store',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (!locationPermissionGranted)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.location_off, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location permission denied. Stores sorted alphabetically.',
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterStores,
              decoration: InputDecoration(
                hintText: 'Search stores...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: filteredStores.isEmpty
                ? Center(
                    child: Text(
                      searchQuery.isEmpty
                          ? 'No stores available'
                          : 'No stores found matching "$searchQuery"',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredStores.length,
                    itemBuilder: (context, index) {
                      final store = filteredStores[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(Icons.store,
                              color: _getChainColor(store.chain)),
                          title: Text(store.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${store.address}${store.distance != null ? '\n${_formatDistance(store.distance)}' : ''}'),
                          isThreeLine: store.distance != null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.queue),
                                  onPressed: () => _openQueue(store)),
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
}f