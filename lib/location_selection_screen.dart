import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'core/design_system.dart';
import 'components/app_components.dart';
import 'models/app_models.dart';
import 'camera_screen.dart';

class StoreLocation {
  final String id;
  final String name;
  final List<dynamic> aisles; // Can be List<int> or List<String>
  final bool isActive;

  StoreLocation({
    required this.id,
    required this.name,
    required this.aisles,
    this.isActive = true,
  });

  factory StoreLocation.fromJson(Map<String, dynamic> json) {
    return StoreLocation(
      id: json['id'],
      name: json['name'],
      aisles: List<dynamic>.from(json['aisles']),
      isActive: json['isActive'] ?? true,
    );
  }
}

// 🆕 NEW: Visit tracking data structure
class LocationVisit {
  final String locationId;
  final String aisleId;
  final String? segment;
  final DateTime visitedAt;
  final bool completed;

  LocationVisit({
    required this.locationId,
    required this.aisleId,
    this.segment,
    required this.visitedAt,
    this.completed = true,
  });

  factory LocationVisit.fromJson(Map<String, dynamic> json) {
    return LocationVisit(
      locationId: json['locationId'],
      aisleId: json['aisleId'],
      segment: json['segment'],
      visitedAt: DateTime.parse(json['visitedAt']),
      completed: json['completed'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationId': locationId,
      'aisleId': aisleId,
      'segment': segment,
      'visitedAt': visitedAt.toIso8601String(),
      'completed': completed,
    };
  }
}

// 🆕 NEW: Persistence manager for location visits
class LocationPersistence {
  static const String _keyPrefix = 'location_visits_';
  static const Duration _retentionPeriod = Duration(days: 3);
  
  static String _getKey(String storeId) => '$_keyPrefix$storeId';
  
  static Future<List<LocationVisit>> getVisits(String storeId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(storeId);
    final jsonString = prefs.getString(key);
    
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      final visits = jsonList.map((json) => LocationVisit.fromJson(json)).toList();
      
      // 🧹 Filter out visits older than 3 days
      final cutoffDate = DateTime.now().subtract(_retentionPeriod);
      final validVisits = visits.where((visit) => visit.visitedAt.isAfter(cutoffDate)).toList();
      
      // 🧹 If we filtered out old visits, save the cleaned list
      if (validVisits.length != visits.length) {
        await _saveVisits(storeId, validVisits);
      }
      
      return validVisits;
    } catch (e) {
      debugPrint('❌ Error loading visits: $e');
      return [];
    }
  }
  
  static Future<void> saveVisit(String storeId, LocationVisit visit) async {
    final visits = await getVisits(storeId);
    
    // Remove existing visit for same location+aisle combination
    visits.removeWhere((v) => 
      v.locationId == visit.locationId && 
      v.aisleId == visit.aisleId
    );
    
    // Add new visit
    visits.add(visit);
    
    await _saveVisits(storeId, visits);
    debugPrint('💾 SAVED VISIT: ${visit.locationId} > ${visit.aisleId} ${visit.segment}');
  }
  
  static Future<void> _saveVisits(String storeId, List<LocationVisit> visits) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(storeId);
    final jsonString = json.encode(visits.map((v) => v.toJson()).toList());
    await prefs.setString(key, jsonString);
  }
  
  static Future<void> clearOldVisits() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix)).toList();
    
    for (final key in keys) {
      final storeId = key.substring(_keyPrefix.length);
      await getVisits(storeId); // This will auto-clean old visits
    }
  }
}

class LocationSelectionScreen extends StatefulWidget {
  final String storeId;
  final String storeName;

  const LocationSelectionScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  List<StoreLocation> locations = [];
  StoreLocation? selectedLocation;
  dynamic selectedAisle;
  List<String> segments = [];
  String? selectedSegment;
  bool isLoading = true;
  int currentStep = 0; // 0 = Area, 1 = Aisle, 2 = Segment
  
  // 🆕 NEW: Visit tracking
  List<LocationVisit> visits = [];
  
  @override
  void initState() {
    super.initState();
    _loadStoreLocations();
  }

  Future<void> _loadStoreLocations() async {
    // 🆕 Load persistent visit data
    await _loadVisitHistory();
    
    // Simulate API call to get store-specific location data
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data showing mixed aisle types
    final mockLocations = _getMockLocationsForStore(widget.storeId);
    
    setState(() {
      locations = mockLocations;
      isLoading = false;
    });
    
    debugPrint('📍 LOADED ${visits.length} visits for store ${widget.storeId}');
  }
  
  // 🆕 NEW: Load visit history from persistence
  Future<void> _loadVisitHistory() async {
    visits = await LocationPersistence.getVisits(widget.storeId);
  }

  List<StoreLocation> _getMockLocationsForStore(String storeId) {
    // This would come from your server/cache
    // Different stores might have different configurations
    return [
      StoreLocation(
        id: 'front',
        name: 'Front',
        aisles: [1, 2, 3, 4, 5, 6, 7, 8], // Numeric aisles
      ),
      StoreLocation(
        id: 'back',
        name: 'Back',
        aisles: [1, 2, 3, 4, 5, 6, 7, 8], // Numeric aisles
      ),
      StoreLocation(
        id: 'deli',
        name: 'Deli',
        aisles: ['Hot Food', 'Cold Cuts', 'Cheese Counter', 'Bakery'], // Descriptive aisles
      ),
      StoreLocation(
        id: 'pos',
        name: 'POS',
        aisles: ['Checkout 1', 'Checkout 2', 'Checkout 3', 'Self Service'], // Descriptive aisles
      ),
      StoreLocation(
        id: 'promo_bins',
        name: 'Promo Bins',
        aisles: ['Entry Display', 'Center Bins', 'End Cap Left', 'End Cap Right'], // Descriptive aisles
      ),
      StoreLocation(
        id: 'freezer',
        name: 'Freezer',
        aisles: ['Frozen Food', 'Ice Cream', 'Frozen Vegetables', 'Ready Meals'], // Descriptive aisles
      ),
      StoreLocation(
        id: 'chiller',
        name: 'Chiller',
        aisles: ['Dairy', 'Fresh Meat', 'Beverages', 'Ready Salads'], // Descriptive aisles
      ),
    ];
  }

  List<String> _getSegmentsForLocation(String locationId, dynamic aisle) {
    // This would also come from server/cache
    // Different location+aisle combinations have different segments
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
  
  // 🆕 NEW: Check if location has been visited
  bool _isLocationVisited(String locationId) {
    final result = visits.any((v) => v.locationId == locationId);
    debugPrint('🧪 TEST: _isLocationVisited($locationId) = $result (${visits.length} total visits)');
    return result;
  }
  
  // 🆕 NEW: Check if aisle has been visited
  bool _isAisleVisited(String locationId, dynamic aisle) {
    final result = visits.any((v) => 
      v.locationId == locationId && 
      v.aisleId == aisle.toString()
    );
    debugPrint('🧪 TEST: _isAisleVisited($locationId, $aisle) = $result');
    return result;
  }
  
  // 🆕 NEW: Get completion count for location
  int _getLocationCompletionCount(String locationId) {
    return visits.where((v) => v.locationId == locationId).length;
  }

  void _selectLocation(StoreLocation location) {
    AppHaptics.light();
    setState(() {
      selectedLocation = location;
      selectedAisle = null;
      selectedSegment = null;
      currentStep = 1;
    });
  }

  void _selectAisle(dynamic aisle) {
    AppHaptics.light();
    setState(() {
      selectedAisle = aisle;
      selectedSegment = null;
      segments = _getSegmentsForLocation(selectedLocation!.id, aisle);
      currentStep = 2;
    });
  }

  void _selectSegment(String segment) async {
    AppHaptics.light();
    setState(() {
      selectedSegment = segment;
    });
    
    // 🧪 TEST: Add immediate debug logging
    debugPrint('🧪 TEST: About to save visit for ${selectedLocation!.id} > ${selectedAisle.toString()} > $segment');
    
    // 🧪 TEST: Create and save visit
    final visit = LocationVisit(
      locationId: selectedLocation!.id,
      aisleId: selectedAisle.toString(),
      segment: segment,
      visitedAt: DateTime.now(),
    );
    
    // Save to persistence
    await LocationPersistence.saveVisit(widget.storeId, visit);
    debugPrint('🧪 TEST: Visit saved successfully');
    
    // 🧪 TEST: Update local visits list immediately
    setState(() {
      visits.removeWhere((v) => 
        v.locationId == visit.locationId && 
        v.aisleId == visit.aisleId
      );
      visits.add(visit);
      debugPrint('🧪 TEST: Local visits updated. Total visits: ${visits.length}');
      
      // Print all visits for debugging
      for (var v in visits) {
        debugPrint('🧪 TEST: Visit stored: ${v.locationId} > ${v.aisleId} > ${v.segment}');
      }
    });
    
    // 🧪 TEST: Instead of navigating to camera, show a dialog and go back to test persistence
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Visit Recorded'),
        content: Text('Visit saved: ${selectedLocation!.name} > Aisle ${selectedAisle} > $segment\n\nTotal visits: ${visits.length}\n\nGo back to Area selection to see green highlighting.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Go back to area selection to test persistence
              setState(() {
                selectedLocation = null;
                selectedAisle = null;
                selectedSegment = null;
                currentStep = 0;
              });
            },
            child: Text('Go Back to Test'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _startCameraSession(); // Continue to camera
            },
            child: Text('Continue to Camera'),
          ),
        ],
      ),
    );
  }

  void _startCameraSession() {
    // Navigate to camera screen with location context
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CameraScreen(
          storeId: widget.storeId,
          storeName: widget.storeName,
          area: selectedLocation!.name,
          aisle: selectedAisle.toString(),
          segment: selectedSegment!,
          mode: CameraMode.sceneCapture, // In-Store Promo mode starts with scene
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: AppDesignSystem.animationStandard,
      ),
    );
  }

  void _goBack() {
    AppHaptics.light();
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
    // Handle both numeric and string aisles
    if (aisle is int) {
      return 'Aisle $aisle';
    } else {
      return aisle.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // MOBILE OPTIMIZED: Use MediaQuery for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    return Scaffold(
      backgroundColor: AppDesignSystem.systemGroupedBackground,
      body: SafeArea( // MOBILE: Ensure content respects device safe areas
        child: AppLoadingOverlay(
          isLoading: isLoading,
          message: 'Loading locations...',
          child: Column(
            children: [
              // MOBILE OPTIMIZED: Compact app bar with progress
              Container(
                width: double.infinity, // MOBILE: Ensure full width
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
                    // App bar
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : AppDesignSystem.spacingMd),
                      child: Row(
                        children: [
                          if (currentStep > 0)
                            AppIconButton(
                              icon: Icons.arrow_back_ios,
                              onPressed: _goBack,
                              iconSize: AppDesignSystem.iconMd,
                            )
                          else
                            AppIconButton(
                              icon: Icons.arrow_back_ios,
                              onPressed: () {
                                AppHaptics.light();
                                Navigator.pop(context);
                              },
                              iconSize: AppDesignSystem.iconMd,
                            ),
                          SizedBox(width: isSmallScreen ? 8 : AppDesignSystem.spacingSm),
                          Expanded(
                            child: Text(
                              currentStep == 0 ? 'Select Area' : 
                              currentStep == 1 ? 'Select Aisle' : 'Select Segment',
                              style: AppDesignSystem.title2.copyWith(
                                color: AppDesignSystem.labelPrimary,
                                fontSize: isSmallScreen ? 18 : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // MOBILE OPTIMIZED: Store info and progress
                    Container(
                      width: double.infinity, // MOBILE: Ensure full width
                      padding: EdgeInsets.all(isSmallScreen ? 12 : AppDesignSystem.spacingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Store info
                          Row(
                            children: [
                              Container(
                                width: isSmallScreen ? 32 : 40,
                                height: isSmallScreen ? 32 : 40,
                                decoration: BoxDecoration(
                                  color: AppDesignSystem.systemBlue,
                                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
                                ),
                                child: Icon(
                                  Icons.store,
                                  color: AppDesignSystem.systemBackground,
                                  size: isSmallScreen ? 16 : 20,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 8 : 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.storeName,
                                      style: AppDesignSystem.subheadline.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: isSmallScreen ? 14 : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (!isSmallScreen) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Store ID: ${widget.storeId}',
                                        style: AppDesignSystem.caption1.copyWith(
                                          color: AppDesignSystem.labelSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // 🆕 NEW: Visit counter
                              if (visits.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppDesignSystem.systemGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
                                    border: Border.all(
                                      color: AppDesignSystem.systemGreen.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    '${visits.length} visited',
                                    style: AppDesignSystem.caption2.copyWith(
                                      color: AppDesignSystem.systemGreen,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          
                          // MOBILE OPTIMIZED: Progress breadcrumb - responsive sizing
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildBreadcrumb('Area', 0, isSmallScreen),
                                Icon(
                                  Icons.chevron_right, 
                                  color: AppDesignSystem.systemGray,
                                  size: isSmallScreen ? 16 : 20,
                                ),
                                _buildBreadcrumb('Aisle', 1, isSmallScreen),
                                Icon(
                                  Icons.chevron_right, 
                                  color: AppDesignSystem.systemGray,
                                  size: isSmallScreen ? 16 : 20,
                                ),
                                _buildBreadcrumb('Segment', 2, isSmallScreen),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // MOBILE OPTIMIZED: Content area
              Expanded(
                child: Container(
                  width: double.infinity, // MOBILE: Ensure full width
                  child: _buildCurrentStepContent(isSmallScreen),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumb(String label, int step, bool isSmallScreen) {
    final isActive = currentStep >= step;
    final isCompleted = currentStep > step;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12, 
        vertical: isSmallScreen ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: isCompleted 
            ? AppDesignSystem.systemGreen.withOpacity(0.1)
            : isActive 
                ? AppDesignSystem.systemBlue.withOpacity(0.1)
                : AppDesignSystem.systemGray6,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
        border: Border.all(
          color: isCompleted 
              ? AppDesignSystem.systemGreen
              : isActive 
                  ? AppDesignSystem.systemBlue
                  : AppDesignSystem.systemGray4,
        ),
      ),
      child: Text(
        label,
        style: AppDesignSystem.caption1.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: isSmallScreen ? 10 : 12,
          color: isCompleted 
              ? AppDesignSystem.systemGreen
              : isActive 
                  ? AppDesignSystem.systemBlue
                  : AppDesignSystem.labelTertiary,
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent(bool isSmallScreen) {
    switch (currentStep) {
      case 0:
        return _buildAreaSelection(isSmallScreen);
      case 1:
        return _buildAisleSelection(isSmallScreen);
      case 2:
        return _buildSegmentSelection(isSmallScreen);
      default:
        return const SizedBox();
    }
  }

  Widget _buildAreaSelection(bool isSmallScreen) {
    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 12 : AppDesignSystem.spacingMd),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        // 🆕 NEW: Check if location has been visited
        final isVisited = _isLocationVisited(location.id);
        final completionCount = _getLocationCompletionCount(location.id);
        
        return Container(
          width: double.infinity, // MOBILE: Ensure full width
          margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
          child: AppCard(
            onTap: location.isActive ? () => _selectLocation(location) : null,
            // 🔧 FIX: Use light green background for visited locations
            backgroundColor: isVisited 
                ? AppDesignSystem.systemGreen.withOpacity(0.1)
                : AppDesignSystem.secondarySystemGroupedBackground,
            // 🔧 FIX: Add green border for visited locations
            border: isVisited 
                ? Border.all(color: AppDesignSystem.systemGreen.withOpacity(0.3), width: 1)
                : null,
            child: Row(
              children: [
                // MOBILE OPTIMIZED: Area icon
                Container(
                  width: isSmallScreen ? 44 : 50,
                  height: isSmallScreen ? 44 : 50,
                  decoration: BoxDecoration(
                    color: isVisited 
                        ? AppDesignSystem.systemGreen  // 🔧 FIX: Green icon for visited
                        : _getAreaColor(location.id),
                    borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          _getAreaIcon(location.id),
                          color: AppDesignSystem.systemBackground,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      // 🆕 NEW: Visited checkmark overlay
                      if (isVisited)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppDesignSystem.systemBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: AppDesignSystem.systemGreen,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                
                // MOBILE OPTIMIZED: Area details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            location.name,
                            style: AppDesignSystem.subheadline.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 15 : null,
                              // 🔧 FIX: Slightly different color for visited locations
                              color: isVisited 
                                  ? AppDesignSystem.systemGreen
                                  : AppDesignSystem.labelPrimary,
                            ),
                          ),
                          // 🆕 NEW: Completion count badge
                          if (completionCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppDesignSystem.systemGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$completionCount',
                                style: AppDesignSystem.caption2.copyWith(
                                  color: AppDesignSystem.systemBackground,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Text(
                        '${location.aisles.length} aisle${location.aisles.length == 1 ? '' : 's'} available',
                        style: AppDesignSystem.footnote.copyWith(
                          color: AppDesignSystem.labelSecondary,
                          fontSize: isSmallScreen ? 12 : null,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // MOBILE OPTIMIZED: Status and arrow
                Column(
                  children: [
                    if (!location.isActive) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.systemRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
                        ),
                        child: Text(
                          'Closed',
                          style: AppDesignSystem.caption2.copyWith(
                            color: AppDesignSystem.systemRed,
                            fontWeight: FontWeight.w500,
                            fontSize: isSmallScreen ? 10 : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Icon(
                      Icons.arrow_forward_ios,
                      size: isSmallScreen ? 14 : 16,
                      color: location.isActive 
                          ? (isVisited ? AppDesignSystem.systemGreen : AppDesignSystem.systemGray2)
                          : AppDesignSystem.systemGray4,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAisleSelection(bool isSmallScreen) {
    final aisles = selectedLocation!.aisles;
    
    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 12 : AppDesignSystem.spacingMd),
      itemCount: aisles.length,
      itemBuilder: (context, index) {
        final aisle = aisles[index];
        // 🆕 NEW: Check if aisle has been visited
        final isVisited = _isAisleVisited(selectedLocation!.id, aisle);
        
        return Container(
          width: double.infinity, // MOBILE: Ensure full width
          margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
          child: AppCard(
            onTap: () => _selectAisle(aisle),
            // 🔧 FIX: Use light green background for visited aisles
            backgroundColor: isVisited 
                ? AppDesignSystem.systemGreen.withOpacity(0.1)
                : AppDesignSystem.secondarySystemGroupedBackground,
            // 🔧 FIX: Add green border for visited aisles
            border: isVisited 
                ? Border.all(color: AppDesignSystem.systemGreen.withOpacity(0.3), width: 1)
                : null,
            child: Row(
              children: [
                // MOBILE OPTIMIZED: Aisle number/name
                Container(
                  width: isSmallScreen ? 44 : 50,
                  height: isSmallScreen ? 44 : 50,
                  decoration: BoxDecoration(
                    // 🔧 FIX: Green color for visited aisles instead of grey
                    color: isVisited 
                        ? AppDesignSystem.systemGreen 
                        : AppDesignSystem.systemBlue,
                    borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          aisle is int ? aisle.toString() : aisle.toString().substring(0, 1),
                          style: AppDesignSystem.title3.copyWith(
                            color: AppDesignSystem.systemBackground,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 16 : 18,
                          ),
                        ),
                      ),
                      // 🆕 NEW: Visited checkmark overlay
                      if (isVisited)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppDesignSystem.systemBackground,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: AppDesignSystem.systemGreen,
                              size: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                
                // MOBILE OPTIMIZED: Aisle details
                Expanded(
                  child: Text(
                    _formatAisle(aisle),
                    style: AppDesignSystem.subheadline.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 15 : null,
                      // 🔧 FIX: Green color for visited aisles
                      color: isVisited 
                          ? AppDesignSystem.systemGreen
                          : AppDesignSystem.labelPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: isSmallScreen ? 14 : 16,
                  color: isVisited 
                      ? AppDesignSystem.systemGreen
                      : AppDesignSystem.systemGray2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegmentSelection(bool isSmallScreen) {
    return ListView.builder(
      padding: EdgeInsets.all(isSmallScreen ? 12 : AppDesignSystem.spacingMd),
      itemCount: segments.length,
      itemBuilder: (context, index) {
        final segment = segments[index];
        return Container(
          width: double.infinity, // MOBILE: Ensure full width
          margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
          child: AppCard(
            onTap: () => _selectSegment(segment),
            backgroundColor: AppDesignSystem.secondarySystemGroupedBackground,
            child: Row(
              children: [
                // MOBILE OPTIMIZED: Segment icon
                Container(
                  width: isSmallScreen ? 44 : 50,
                  height: isSmallScreen ? 44 : 50,
                  decoration: BoxDecoration(
                    color: AppDesignSystem.primaryOrange,
                    borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
                  ),
                  child: Icon(
                    _getSegmentIcon(segment),
                    color: AppDesignSystem.systemBackground,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 16),
                
                // MOBILE OPTIMIZED: Segment details
                Expanded(
                  child: Text(
                    segment,
                    style: AppDesignSystem.subheadline.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 15 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: isSmallScreen ? 14 : 16,
                  color: AppDesignSystem.systemGray2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getAreaColor(String areaId) {
    switch (areaId) {
      case 'front':
        return AppDesignSystem.systemBlue;
      case 'back':
        return AppDesignSystem.systemGreen;
      case 'deli':
        return AppDesignSystem.primaryOrange;
      case 'pos':
        return AppDesignSystem.systemPurple;
      case 'promo_bins':
        return AppDesignSystem.systemRed;
      case 'freezer':
        return AppDesignSystem.primaryNavy;
      case 'chiller':
        return AppDesignSystem.systemBlue;
      default:
        return AppDesignSystem.systemGray;
    }
  }

  IconData _getAreaIcon(String areaId) {
    switch (areaId) {
      case 'front':
        return Icons.storefront;
      case 'back':
        return Icons.inventory_2;
      case 'deli':
        return Icons.restaurant;
      case 'pos':
        return Icons.point_of_sale;
      case 'promo_bins':
        return Icons.local_offer;
      case 'freezer':
        return Icons.ac_unit;
      case 'chiller':
        return Icons.kitchen;
      default:
        return Icons.location_on;
    }
  }

  IconData _getSegmentIcon(String segment) {
    if (segment.toLowerCase().contains('front')) {
      return Icons.arrow_upward;
    } else if (segment.toLowerCase().contains('back')) {
      return Icons.arrow_downward;
    } else if (segment.toLowerCase().contains('left')) {
      return Icons.arrow_back;
    } else if (segment.toLowerCase().contains('right')) {
      return Icons.arrow_forward;
    } else if (segment.toLowerCase().contains('counter')) {
      return Icons.countertops;
    } else if (segment.toLowerCase().contains('display')) {
      return Icons.visibility;
    } else {
      return Icons.place;
    }
  }
}
