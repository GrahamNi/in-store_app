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
import 'services/store_cache.dart';

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
    // Helper to safely convert to double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    return Store(
      id: data['store_id']?.toString() ?? data['id']?.toString() ?? 'unknown',
      name: data['store_name']?.toString() ?? data['name']?.toString() ?? 'Unknown Store',
      chain: data['chain']?.toString() ?? data['brand']?.toString() ?? 'Unknown',
      address: data['address_1']?.toString() ?? data['address']?.toString() ?? '',
      suburb: data['suburb']?.toString() ?? data['locality']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      postcode: data['postcode']?.toString() ?? data['postal_code']?.toString() ?? '',
      state: data['state']?.toString() ?? data['region']?.toString() ?? '',
      latitude: parseDouble(data['latitude'] ?? data['lat']),
      longitude: parseDouble(data['longitude'] ?? data['lon']),
      distance: parseDouble(data['distance_km'] ?? data['distance']),
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

  // No mock data - API is mandatory on first load

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

    // Load stores directly
    _loadStores();
  }
  
  Future<void> _initializeStores() async {
    // Download all stores on first launch or update if needed
    debugPrint('🎬 STORE INIT: Initializing store data...');
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
    });
    
    try {
      // FIRST: Try to load from cache (PERSISTENT)
      final cachedStores = await StoreCache().cachedStores;
      
      if (cachedStores != null && cachedStores.isNotEmpty) {
        debugPrint('✅ CACHE HIT: Using ${cachedStores.length} cached stores');
        
        // Get cached user location
        final (lat, lon) = StoreCache().userLocation;
        userLatitude = lat;
        userLongitude = lon;
        
        debugPrint('📍 Using cached location: $lat, $lon');
        
        // Convert cached data to Store objects
        stores = cachedStores.map((storeData) {
          final store = Store.fromApiData(storeData);
          
          if (store.distance != null && store.distance! > 0) {
            store.walkingTime = _calculateWalkingTime(store.distance!);
          }
          
          return store;
        }).toList();
        
        setState(() {
          isUsingApi = true;
        });
        
        debugPrint('✅ Loaded ${stores.length} stores from CACHE');
      } else {
        // FALLBACK: Load from API if cache is empty
        debugPrint('⚠️ CACHE MISS: Loading from API...');
        
        final apiStoresData = await StoreService.getNearestStores(
          latitude: -32.9273,
          longitude: 151.7817,
        );
        
        if (apiStoresData.isEmpty) {
          throw Exception('API returned no stores');
        }
        
        stores = apiStoresData.map((storeData) {
          final store = Store.fromApiData(storeData);
          
          if (store.distance != null && store.distance! > 0) {
            store.walkingTime = _calculateWalkingTime(store.distance!);
          }
          
          return store;
        }).toList();
        
        setState(() {
          isUsingApi = true;
        });
        
        debugPrint('✅ Loaded ${stores.length} stores from API');
      }
      
      _updateClosestStores();
      filteredStores = List.from(closestStores);

      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      debugPrint('❌ CRITICAL: Store load failed: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load stores: $e'),
            backgroundColor: AppDesignSystem.systemRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
    
    debugPrint('🚀 STORE LOAD: _loadStores() completed');
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
    
    // 🔍 DEBUG LOGGING FOR ROUTING
    debugPrint('\n🔄 STORE SELECTION ROUTING DEBUG:');
    debugPrint('   Store: ${store.name} (${store.id})');
    debugPrint('   User Profile Type: ${widget.userProfile.userType}');
    debugPrint('   User Type Raw Value: ${widget.userProfile.userType.toString()}');
    debugPrint('   Is InStore? ${widget.userProfile.userType == UserType.inStore}');
    debugPrint('   Is InStorePromo? ${widget.userProfile.userType == UserType.inStorePromo}');
    
    // Different navigation based on user profile
    if (widget.userProfile.userType == UserType.inStore) {
      debugPrint('   ✅ ROUTE: Profile A -> Direct to camera (label capture)');
      // Profile A (instore): Go directly to camera in label capture mode
      // NO LOCATION DATA - area, aisle, segment all remain null
      _navigateToCameraScreen(store, null, null, null, CameraMode.labelCapture);
    } else {
      debugPrint('   ✅ ROUTE: Profile B -> Location selection first');
      // Profile B (instore promo): Go to location selection first
      // WILL COLLECT LOCATION DATA through enhanced location selection
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
    final chainLower = chain.toLowerCase().trim();
    
    // Handle common variations
    if (chainLower.contains('coles')) {
      return 'assets/images/store_logos/coles_logo.png';
    } else if (chainLower.contains('woolworth') || chainLower.contains('woolies')) {
      return 'assets/images/store_logos/Woolworths_logo.png';
    } else if (chainLower.contains('iga')) {
      return 'assets/images/store_logos/iga_logo.png';
    } else if (chainLower.contains('aldi')) {
      return 'assets/images/store_logos/aldi_logo.png';
    } else if (chainLower.contains('new world') || chainLower.contains('newworld')) {
      return 'assets/images/store_logos/newworld_logo.png';
    }
    
    debugPrint('⚠️ No logo found for chain: "$chain" (normalized: "$chainLower")');
    return '';
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
