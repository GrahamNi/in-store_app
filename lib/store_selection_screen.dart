import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'core/design_system.dart';
import 'components/app_components.dart';
import 'models/app_models.dart';
import 'enhanced_location_selection_screen.dart';
import 'camera_screen.dart';
import 'core/upload_queue_initializer.dart';
import 'services/store_service.dart';
import 'services/store_service_debug.dart';
import 'services/store_service_fixed.dart';

class Store {
  final String id;
  final String name;
  final String chain;
  final String address;
  final String suburb;
  final String city;
  final String postcode;
  final String state;
  final double latitude;
  final double longitude;
  double? distance;
  String? walkingTime;

  Store({
    required this.id,
    required this.name,
    required this.chain,
    required this.address,
    required this.suburb,
    required this.city,
    required this.postcode,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.distance,
    this.walkingTime,
  });

  factory Store.fromApiData(Map<String, dynamic> data) {
    return Store(
      id: data['id']?.toString() ?? 'unknown',
      name: data['name'] ?? 'Unknown Store',
      chain: data['chain'] ?? data['brand'] ?? 'Unknown',
      address: data['address'] ?? '',
      suburb: data['suburb'] ?? data['locality'] ?? '',
      city: data['city'] ?? '',
      postcode: data['postcode'] ?? data['postal_code'] ?? '',
      state: data['state'] ?? data['region'] ?? '',
      latitude: (data['latitude'] ?? data['lat'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? data['lon'] ?? 0.0).toDouble(),
      distance: (data['distance'] ?? 0.0).toDouble(),
    );
  }

  String get searchableText => '$name $chain $address $suburb $city $postcode $state'.toLowerCase();
}

class StoreSelectionScreen extends StatefulWidget {
  final UserProfile userProfile;
  final bool isFirstTime;
  
  const StoreSelectionScreen({
    super.key,
    required this.userProfile,
    this.isFirstTime = false,
  });

  @override
  State<StoreSelectionScreen> createState() => _StoreSelectionScreenState();
}

class _StoreSelectionScreenState extends State<StoreSelectionScreen>
    with TickerProviderStateMixin {
  List<Store> stores = [];
  List<Store> filteredStores = [];
  List<Store> closestStores = [];
  bool isLoading = true;
  bool isLocationLoading = false;
  bool isUsingApi = false; // Track if we're using real API or fallback
  final TextEditingController _searchController = TextEditingController();
  
  // User location for distance calculation
  double? userLatitude;
  double? userLongitude;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _staggerController;

  // Fallback mock data if API fails
  final List<Store> mockStores = [
    Store(
      id: '001',
      name: 'Coles Charlestown',
      chain: 'Coles',
      address: '30 Pearson Street',
      suburb: 'Charlestown',
      city: 'Newcastle',
      postcode: '2290',
      state: 'NSW',
      latitude: -32.9647,
      longitude: 151.6928,
    ),
    Store(
      id: '002',
      name: 'Woolworths Kotara',
      chain: 'Woolworths',
      address: 'Northcott Drive',
      suburb: 'Kotara',
      city: 'Newcastle',
      postcode: '2289',
      state: 'NSW',
      latitude: -32.9404,
      longitude: 151.7071,
    ),
    Store(
      id: '003',
      name: 'Coles Newcastle West',
      chain: 'Coles',
      address: '166 Parry Street',
      suburb: 'Newcastle West',
      city: 'Newcastle',
      postcode: '2302',
      state: 'NSW',
      latitude: -32.9273,
      longitude: 151.7817,
    ),
    Store(
      id: '004',
      name: 'ALDI Jesmond',
      chain: 'ALDI',
      address: 'Blue Gum Road',
      suburb: 'Jesmond',
      city: 'Newcastle',
      postcode: '2299',
      state: 'NSW',
      latitude: -32.9123,
      longitude: 151.7456,
    ),
    Store(
      id: '005',
      name: 'Woolworths Newcastle West',
      chain: 'Woolworths',
      address: '166 Parry Street',
      suburb: 'Newcastle West',
      city: 'Newcastle',
      postcode: '2302',
      state: 'NSW',
      latitude: -32.9273,
      longitude: 151.7817,
    ),
    Store(
      id: '006',
      name: 'IGA Mayfield',
      chain: 'IGA',
      address: '45 Maitland Road',
      suburb: 'Mayfield',
      city: 'Newcastle',
      postcode: '2304',
      state: 'NSW',
      latitude: -32.8967,
      longitude: 151.7345,
    ),
    Store(
      id: '007',
      name: 'Coles Kotara',
      chain: 'Coles',
      address: 'Northcott Drive',
      suburb: 'Kotara',
      city: 'Newcastle',
      postcode: '2289',
      state: 'NSW',
      latitude: -32.9404,
      longitude: 151.7071,
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    // First, try to download/update stores from server if needed
    _initializeStores();
  }
  
  Future<void> _initializeStores() async {
    // Download all stores on first launch or update if needed
    debugPrint('🎬 STORE INIT: Initializing store data...');
    
    // This will check if we need to update from server
    await StoreServiceFixed.updateStoresIfNeeded();
    
    // Then load and display stores
    _loadStores();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    debugPrint('🚀 STORE LOAD: Starting _loadStores() method');
    setState(() {
      isLoading = true;
      isLocationLoading = true;
    });
    
    // NEW WORKFLOW: 
    // 1. Check cache or download all stores from API
    // 2. Calculate distances locally
    // 3. Show nearest 5
    
    debugPrint('🚀 STORE LOAD: Checking for cached stores or downloading from API...');
    
    // Try the fixed service that handles the correct workflow
    final nearestStores = await StoreServiceFixed.getNearestStores();
    
    debugPrint('🔍 STORE LOAD: nearestStores.isEmpty = ${nearestStores.isEmpty}');
    debugPrint('🔍 STORE LOAD: nearestStores.length = ${nearestStores.length}');
    if (nearestStores.isNotEmpty) {
      debugPrint('🔍 STORE LOAD: First store: ${nearestStores.first}');
      // Convert API format to app Store objects
      stores = nearestStores.map((storeData) {
        final convertedData = StoreServiceFixed.convertApiStoreToAppStore(storeData);
        final store = Store.fromApiData(convertedData);
        
        // Calculate walking time if distance is provided
        if (store.distance != null && store.distance! > 0) {
          store.walkingTime = _calculateWalkingTime(store.distance!);
        }
        
        return store;
      }).toList();
      
      setState(() {
        isUsingApi = true;
      });
      debugPrint('✅ Loaded ${stores.length} stores from API/cache');
    } else {
      debugPrint('🚀 STORE LOAD: No API stores available, using fallback mock data');
      // Fallback to mock data and calculate distances
      stores = List.from(mockStores);
      await _getCurrentLocationAndCalculateDistances();
      setState(() {
        isUsingApi = false;
      });
      debugPrint('⚠️ Using fallback mock data (${stores.length} stores)');
    }
    
    _updateClosestStores();
    filteredStores = List.from(closestStores);

    if (mounted) {
      setState(() {
        isLoading = false;
        isLocationLoading = false;
      });
      _fadeController.forward();
    }
    debugPrint('🚀 STORE LOAD: _loadStores() completed');
  }

  Future<List<Store>> _loadStoresFromApi() async {
    try {
      debugPrint('🔍 STORE API DEBUG: Starting store load from API');
      debugPrint('🔍 STORE API DEBUG: About to call StoreService.testStoresApi()');
      
      // Test API connection first
      debugPrint('🔍 STORE API DEBUG: Testing API with enhanced debugging...');
      final apiWorks = await StoreServiceDebug.testStoresApiEnhanced();
      debugPrint('🔍 STORE API DEBUG: API connection test result: $apiWorks');
      
      if (!apiWorks) {
        debugPrint('🔍 STORE API DEBUG: API test failed, using fallback data');
        return [];
      }

      // Get user location
      double? lat, lon;
      try {
        final position = await _getCurrentLocationOnly();
        lat = position.latitude;
        lon = position.longitude;
        userLatitude = lat;
        userLongitude = lon;
        debugPrint('🔍 STORE API DEBUG: Got user location: $lat, $lon');
      } catch (e) {
        // Use fallback location
        lat = -32.9273;
        lon = 151.7817;
        userLatitude = lat;
        userLongitude = lon;
        debugPrint('🔍 STORE API DEBUG: Using fallback location: $lat, $lon (Error: $e)');
      }

      // Call your stores API
      debugPrint('🔍 STORE API DEBUG: Calling StoreService.getNearestStores with lat: $lat, lon: $lon');
      final apiStoresData = await StoreService.getNearestStores(
        latitude: lat,
        longitude: lon,
      );

      debugPrint('🔍 STORE API DEBUG: API returned ${apiStoresData.length} stores');
      if (apiStoresData.isNotEmpty) {
        debugPrint('🔍 STORE API DEBUG: First store example: ${apiStoresData.first}');
      }

      if (apiStoresData.isEmpty) {
        debugPrint('🔍 STORE API DEBUG: No stores returned from API');
        return [];
      }

      // Convert API data to Store objects
      final apiStores = apiStoresData.map((storeData) {
        final convertedData = StoreService.convertApiStoreToAppStore(storeData);
        final store = Store.fromApiData(convertedData);
        
        // Calculate walking time if distance is provided
        if (store.distance != null && store.distance! > 0) {
          store.walkingTime = _calculateWalkingTime(store.distance!);
        }
        
        return store;
      }).toList();

      debugPrint('🔍 STORE API DEBUG: Successfully converted ${apiStores.length} stores to app format');
      return apiStores;

    } catch (e) {
      debugPrint('🔍 STORE API DEBUG: Failed to load stores from API: $e');
      return [];
    }
  }

  Future<Position> _getCurrentLocationOnly() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever || 
        permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }
    
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 10),
    );
  }
  
  Future<void> _getCurrentLocationAndCalculateDistances() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever || 
          permission == LocationPermission.denied) {
        userLatitude = -32.9273;
        userLongitude = 151.7817;
      } else {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
        userLatitude = position.latitude;
        userLongitude = position.longitude;
      }
      
      for (var store in stores) {
        store.distance = _calculateDistance(
          userLatitude!,
          userLongitude!,
          store.latitude,
          store.longitude,
        );
        store.walkingTime = _calculateWalkingTime(store.distance!);
      }
      
    } catch (e) {
      userLatitude = -32.9273;
      userLongitude = 151.7817;
      
      for (var store in stores) {
        store.distance = _calculateDistance(
          userLatitude!,
          userLongitude!,
          store.latitude,
          store.longitude,
        );
        store.walkingTime = _calculateWalkingTime(store.distance!);
      }
    }
  }
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
  
  String _calculateWalkingTime(double distanceKm) {
    final timeInMinutes = (distanceKm / 5.0 * 60).round();
    
    if (timeInMinutes < 60) {
      return '$timeInMinutes min';
    } else {
      final hours = timeInMinutes ~/ 60;
      final minutes = timeInMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    }
  }
  
  void _updateClosestStores() {
    stores.sort((a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999));
    closestStores = stores.take(5).toList();
  }

  void _filterStores(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredStores = List.from(closestStores);
      } else {
        filteredStores = stores.where((store) =>
          store.searchableText.contains(query.toLowerCase())
        ).toList();
        filteredStores.sort((a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999));
      }
    });
  }

  void _selectStore(Store store) {
    AppHaptics.light();
    
    // **CRITICAL: Start a new visit session for the selected store**
    UploadQueueInitializer.startNewVisit(
      operatorId: 'operator_${widget.userProfile.email.hashCode}',
      operatorName: widget.userProfile.name,
      storeId: store.id,
      storeName: store.name,
    );
    
    // Different navigation based on user profile
    if (widget.userProfile.userType == UserType.inStore) {
      // Profile A (instore): Go directly to camera in label capture mode
      _navigateToCameraScreen(store, null, null, null, CameraMode.labelCapture);
    } else {
      // Profile B (instore promo): Go to location selection first
      _navigateToLocationSelection(store);
    }
  }
  
  void _navigateToLocationSelection(Store store) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => EnhancedLocationSelectionScreen(
          storeId: store.id,
          storeName: store.name,
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
  
  void _navigateToCameraScreen(Store store, String? area, String? aisle, String? segment, CameraMode mode) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CameraScreen(
          storeId: store.id,
          storeName: store.name,
          area: area,
          aisle: aisle,
          segment: segment,
          cameraMode: mode,
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
        return AppDesignSystem.systemGray;
    }
  }

  String _getStoreLogo(String chain) {
    switch (chain.toLowerCase()) {
      case 'coles':
        return 'assets/images/store_logos/coles_logo.png';
      case 'woolworths':
        return 'assets/images/store_logos/Woolworths_logo.png';
      case 'iga':
        return 'assets/images/store_logos/iga_logo.png';
      case 'aldi':
        return 'assets/images/store_logos/aldi_logo.png';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    return Scaffold(
      backgroundColor: AppDesignSystem.systemGroupedBackground,
      body: SafeArea(
        child: AppLoadingOverlay(
          isLoading: isLoading,
          message: isUsingApi ? 'Loading stores from API...' : 'Loading stores...',
          child: Column(
            children: [
              _buildAppBar(isSmallScreen),
              _buildMapHeader(isSmallScreen),
              _buildSearchBar(isSmallScreen),
              _buildStoreList(isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isSmallScreen) {
    return Container(
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
              if (!widget.isFirstTime) ...[
                AppIconButton(
                  icon: Icons.arrow_back_ios,
                  onPressed: () {
                    AppHaptics.light();
                    Navigator.pop(context);
                  },
                  size: AppDesignSystem.iconMd,
                ),
                SizedBox(width: isSmallScreen ? 8 : AppDesignSystem.spacingSm),
              ],
              Expanded(
                child: Text(
                  'Find Stores Near You',
                  style: AppDesignSystem.title2.copyWith(
                    color: AppDesignSystem.labelPrimary,
                    fontSize: isSmallScreen ? 18 : null,
                  ),
                ),
              ),
            ],
          ),
          
          // API Status Indicator
          if (!isLoading)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isUsingApi ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUsingApi ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUsingApi ? Icons.cloud_done : Icons.cloud_off,
                    size: 16,
                    color: isUsingApi ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isUsingApi ? 'Live API Data' : 'Demo Data',
                    style: AppDesignSystem.caption2.copyWith(
                      color: isUsingApi ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapHeader(bool isSmallScreen) {
    return Container(
      height: 120,
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : AppDesignSystem.spacingMd,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[100]!,
            Colors.blue[50]!,
            Colors.green[50]!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            _buildMapBackground(),
            _buildStorePins(isSmallScreen),
            _buildMapControls(isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[100]!,
            Colors.blue[50]!,
            Colors.green[50]!,
          ],
        ),
      ),
      child: CustomPaint(
        painter: MapPatternPainter(),
      ),
    );
  }

  Widget _buildStorePins(bool isSmallScreen) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            left: 30,
            top: 35,
            child: _buildStorePin('Coles', _getChainColor('Coles'), true),
          ),
          Positioned(
            right: 40,
            top: 25,
            child: _buildStorePin('Woolworths', _getChainColor('Woolworths'), false),
          ),
          Positioned(
            left: 60,
            bottom: 25,
            child: _buildStorePin('IGA', _getChainColor('IGA'), false),
          ),
        ],
      ),
    );
  }

  Widget _buildStorePin(String chain, Color color, bool isClosest) {
    return Container(
      width: isClosest ? 28 : 20,
      height: isClosest ? 28 : 20,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Icon(
        Icons.store,
        color: Colors.white,
        size: isClosest ? 14 : 10,
      ),
    );
  }

  Widget _buildMapControls(bool isSmallScreen) {
    return Positioned(
      top: isSmallScreen ? 8 : 12,
      right: isSmallScreen ? 8 : 12,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location),
              color: AppDesignSystem.systemBlue,
              iconSize: isSmallScreen ? 20 : 24,
              onPressed: () {
                AppHaptics.light();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : AppDesignSystem.spacingMd,
        vertical: AppDesignSystem.spacingSm,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AppSearchBar(
          controller: _searchController,
          hintText: isSmallScreen ? 'Search stores...' : 'Search by store, suburb, postcode, or chain...',
          onChanged: _filterStores,
        ),
      ),
    );
  }

  Widget _buildStoreList(bool isSmallScreen) {
    return Expanded(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? double.infinity : 600,
        ),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : AppDesignSystem.spacingMd,
            vertical: AppDesignSystem.spacingSm,
          ),
          itemCount: filteredStores.length,
          itemBuilder: (context, index) {
            final store = filteredStores[index];
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildStoreCard(store, isSmallScreen),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStoreCard(Store store, bool isSmallScreen) {
    final logoPath = _getStoreLogo(store.chain);
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : AppDesignSystem.spacingSm),
      child: AppCard(
        onTap: () => _selectStore(store),
        backgroundColor: AppDesignSystem.secondarySystemGroupedBackground,
        child: Row(
          children: [
            Container(
              width: isSmallScreen ? 48 : 56,
              height: isSmallScreen ? 48 : 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
                border: Border.all(
                  color: _getChainColor(store.chain).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
                child: logoPath.isNotEmpty
                    ? Image.asset(
                        logoPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFallbackIcon(store, isSmallScreen);
                        },
                      )
                    : _buildFallbackIcon(store, isSmallScreen),
              ),
            ),
            
            SizedBox(width: isSmallScreen ? 12 : AppDesignSystem.spacingMd),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: AppDesignSystem.subheadline.copyWith(
                      color: AppDesignSystem.labelPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 15 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: isSmallScreen ? 2 : AppDesignSystem.spacing2xs),
                  
                  Text(
                    '${store.address}, ${store.suburb} ${store.postcode}',
                    style: AppDesignSystem.footnote.copyWith(
                      color: AppDesignSystem.labelSecondary,
                      fontSize: isSmallScreen ? 12 : null,
                    ),
                    maxLines: isSmallScreen ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: isSmallScreen ? 4 : AppDesignSystem.spacingSm),
                  
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getChainColor(store.chain).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: _getChainColor(store.chain),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${store.distance?.toStringAsFixed(1)} km',
                              style: AppDesignSystem.caption2.copyWith(
                                color: _getChainColor(store.chain),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      Icon(
                        Icons.directions_walk,
                        size: 14,
                        color: AppDesignSystem.labelTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store.walkingTime ?? '',
                        style: AppDesignSystem.caption1.copyWith(
                          color: AppDesignSystem.labelTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              color: AppDesignSystem.systemGray2,
              size: isSmallScreen ? 14 : AppDesignSystem.iconSm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(Store store, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _getChainColor(store.chain).withOpacity(0.1),
      child: Icon(
        Icons.storefront,
        color: _getChainColor(store.chain),
        size: isSmallScreen ? AppDesignSystem.iconMd : AppDesignSystem.iconLg,
      ),
    );
  }
}

// Custom painter for map background pattern
class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    const spacing = 20.0;
    
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
