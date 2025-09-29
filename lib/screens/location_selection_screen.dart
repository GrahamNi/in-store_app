import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'camera_screen.dart';

class StoreLocation {
  final String id;
  final String name;
  final List<dynamic> aisles;
  final bool isActive;

  StoreLocation({
    required this.id,
    required this.name,
    required this.aisles,
    this.isActive = true,
  });
}

class LocationSelectionScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final String sessionId;

  const LocationSelectionScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.sessionId,
  });

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  
  List<StoreLocation> locations = [];
  StoreLocation? selectedLocation;
  dynamic selectedAisle;
  List<String> segments = [];
  String? selectedSegment;
  bool isLoading = true;
  int currentStep = 0;

  Map<String, dynamic>? _cachedLocation;

  @override
  void initState() {
    super.initState();
    _loadStoreLocations();
  }

  Future<void> _loadStoreLocations() async {
    _cachedLocation = await _db.getLocationCache(widget.storeId);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final mockLocations = [
      StoreLocation(id: 'front', name: 'Front', aisles: [1, 2, 3, 4, 5, 6, 7, 8]),
      StoreLocation(id: 'back', name: 'Back', aisles: [1, 2, 3, 4, 5, 6, 7, 8]),
      StoreLocation(id: 'deli', name: 'Deli', aisles: ['Hot Food', 'Cold Cuts', 'Cheese Counter', 'Bakery']),
      StoreLocation(id: 'pos', name: 'POS', aisles: ['Checkout 1', 'Checkout 2', 'Checkout 3', 'Self Service']),
      StoreLocation(id: 'promo_bins', name: 'Promo Bins', aisles: ['Entry Display', 'Center Bins', 'End Cap Left', 'End Cap Right']),
      StoreLocation(id: 'freezer', name: 'Freezer', aisles: ['Frozen Food', 'Ice Cream', 'Frozen Vegetables', 'Ready Meals']),
      StoreLocation(id: 'chiller', name: 'Chiller', aisles: ['Dairy', 'Fresh Meat', 'Beverages', 'Ready Salads']),
    ];
    
    setState(() {
      locations = mockLocations;
      isLoading = false;
      
      if (_cachedLocation != null) {
        final cachedArea = _cachedLocation!['last_area'] as String?;
        if (cachedArea != null) {
          selectedLocation = locations.firstWhere((loc) => loc.id == cachedArea, orElse: () => locations.first);
        }
      }
    });
  }

  List<String> _getSegmentsForLocation(String locationId, dynamic aisle) {
    switch (locationId) {
      case 'front':
      case 'back':
        return ['Front', 'Back', 'Left Wing', 'Right Wing'];
      case 'deli':
        return ['Counter Front', 'Display Case', 'Self Service'];
      case 'pos':
        return ['Queue Area', 'Counter', 'Impulse Display'];
      case 'promo_bins':
        return ['Top Shelf', 'Eye Level', 'Bottom Tier'];
      case 'freezer':
      case 'chiller':
        return ['Front', 'Back', 'Left Side', 'Right Side'];
      default:
        return ['Front', 'Back', 'Left', 'Right'];
    }
  }

  void _selectLocation(StoreLocation location) {
    setState(() {
      selectedLocation = location;
      selectedAisle = null;
      selectedSegment = null;
      currentStep = 1;
    });
    _db.saveLocationCache(storeId: widget.storeId, area: location.id);
  }

  void _selectAisle(dynamic aisle) {
    setState(() {
      selectedAisle = aisle;
      selectedSegment = null;
      segments = _getSegmentsForLocation(selectedLocation!.id, aisle);
      currentStep = 2;
    });
    _db.saveLocationCache(storeId: widget.storeId, area: selectedLocation!.id, aisle: aisle.toString());
  }

  void _selectSegment(String segment) {
    setState(() {
      selectedSegment = segment;
    });
    _db.saveLocationCache(storeId: widget.storeId, area: selectedLocation!.id, aisle: selectedAisle.toString(), segment: segment);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          sessionId: widget.sessionId,
          storeId: widget.storeId,
          storeName: widget.storeName,
          area: selectedLocation!.id,
          aisle: selectedAisle.toString(),
          segment: segment,
        ),
      ),
    );
  }

  void _goBack() {
    setState(() {
      if (currentStep == 2) {
        selectedAisle = null;
        selectedSegment = null;
        segments = [];
        currentStep = 1;
      } else if (currentStep == 1) {
        selectedLocation = null;
        currentStep = 0;
      }
    });
  }

  String _formatAisle(dynamic aisle) {
    return aisle is int ? 'Aisle $aisle' : aisle.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(currentStep == 0 ? 'Select Area' : currentStep == 1 ? 'Select Aisle' : 'Select Segment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: currentStep > 0 ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack) : null,
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (currentStep) {
      case 0:
        return _buildListView(
          items: locations,
          onTap: _selectLocation,
          isSelected: (loc) => selectedLocation?.id == loc.id,
          getTitle: (loc) => loc.name,
          getSubtitle: (loc) => '${loc.aisles.length} aisles',
        );
      case 1:
        return _buildListView(
          items: selectedLocation!.aisles,
          onTap: _selectAisle,
          isSelected: (aisle) => selectedAisle?.toString() == aisle.toString(),
          getTitle: (aisle) => _formatAisle(aisle),
          getSubtitle: (_) => null,
        );
      case 2:
        return _buildListView(
          items: segments,
          onTap: _selectSegment,
          isSelected: (seg) => selectedSegment == seg,
          getTitle: (seg) => seg,
          getSubtitle: (_) => null,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildListView<T>({
    required List<T> items,
    required Function(T) onTap,
    required bool Function(T) isSelected,
    required String Function(T) getTitle,
    required String? Function(T) getSubtitle,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final selected = isSelected(item);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: selected ? Colors.green[50] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: selected ? Colors.green[300]! : Colors.transparent, width: 2),
          ),
          child: ListTile(
            title: Text(getTitle(item), style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Colors.green[900] : Colors.black)),
            subtitle: getSubtitle(item) != null ? Text(getSubtitle(item)!) : null,
            trailing: Icon(selected ? Icons.check_circle : Icons.arrow_forward_ios, color: selected ? Colors.green[600] : Colors.grey[400]),
            onTap: () => onTap(item),
          ),
        );
      },
    );
  }
}
