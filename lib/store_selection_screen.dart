import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'core/design_system.dart';
import 'components/app_components.dart';
import 'models/app_models.dart'; // ✅ Use Store from here
import 'enhanced_location_selection_screen.dart';
import 'camera_screen.dart';
import 'core/upload_queue_initializer.dart';
import 'services/store_service.dart';
import 'services/store_cache.dart';

// ❌ REMOVED DUPLICATE Store CLASS - Using the one from models/app_models.dart

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
  bool isUsingApi = false;
  final TextEditingController _searchController = TextEditingController();
  
  double? userLatitude;
  double? userLongitude;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _staggerController;

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

    _loadStores();
  }
  
  Future<void> _initializeStores() async {
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
      // STEP 1: Request location permission and get current GPS position
      await _requestLocationPermission();
      
      // STEP 2: Load stores from cache
      final cachedStores = await StoreCache().cachedStores;
      
      if (cachedStores != null && cachedStores.isNotEmpty) {
        debugPrint('✅ CACHE HIT: Using ${cachedStores.length} cached stores');
        
        // ✅ Convert Map to Store objects
        stores = cachedStores.map((storeData) {
          return Store.fromJson(storeData);
        }).toList();
        
        setState(() {
          isUsingApi = true;
        });
        
        debugPrint('✅ Loaded ${stores.length} stores from CACHE');
      } else {
        debugPrint('⚠️ CACHE MISS: Loading from API...');
        
        // ✅ API returns List<Store> already
        stores = await StoreService.getNearestStores(
          latitude: userLatitude ?? -32.9273,
          longitude: userLongitude ?? 151.7817,
        );
        
        if (stores.isEmpty) {
          throw Exception('API returned no stores');
        }
        
        setState(() {
          isUsingApi = true;
        });
        
        debugPrint('✅ Loaded ${stores.length} stores from API');
      }
      
      // STEP 3: Recalculate distances based on CURRENT location
      if (userLatitude != null && userLongitude != null) {
        debugPrint('📍 Recalculating distances from current location: $userLatitude, $userLongitude');
        for (var store in stores) {
          store.distance = _calculateDistance(
            userLatitude!,
            userLongitude!,
            store.latitude,
            store.longitude,
          );
        }
        debugPrint('✅ Recalculated distances for ${stores.length} stores');
      } else {
        debugPrint('⚠️ No current location - using cached distances');
      }
      
      // STEP 4: Update closest 5 stores
      _updateClosestStores();
      filteredStores = List.from(closestStores);
      
      debugPrint('📍 Showing ${closestStores.length} closest stores');
      if (closestStores.isNotEmpty) {
        debugPrint('   1. ${closestStores[0].name} - ${closestStores[0].distance?.toStringAsFixed(1)} km');
        if (closestStores.length > 1) {
          debugPrint('   2. ${closestStores[1].name} - ${closestStores[1].distance?.toStringAsFixed(1)} km');
        }
        if (closestStores.length > 2) {
          debugPrint('   3. ${closestStores[2].name} - ${closestStores[2].distance?.toStringAsFixed(1)} km');
        }
      }

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

  Future<void> _requestLocationPermission() async {
    debugPrint('📍 LOCATION: Requesting location permission...');
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ LOCATION: Location services are disabled');
        return;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('📍 LOCATION: Current permission status: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('📍 LOCATION: Requesting permission...');
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ LOCATION: Permission denied by user');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ LOCATION: Permission permanently denied');
        return;
      }

      // Permission granted - get current position
      debugPrint('📍 LOCATION: Permission granted, getting current position...');
      
      setState(() {
        isLocationLoading = true;
      });
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      
      userLatitude = position.latitude;
      userLongitude = position.longitude;
      
      debugPrint('✅ LOCATION: Got current position: $userLatitude, $userLongitude');
      
      setState(() {
        isLocationLoading = false;
      });
      
    } catch (e) {
      debugPrint('❌ LOCATION ERROR: $e');
      setState(() {
        isLocationLoading = false;
      });
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
        filteredStores = stores.where((store) {
          final searchText = '${store.name} ${store.chain} ${store.address}'.toLowerCase();
          return searchText.contains(query.toLowerCase());
        }).toList();
        filteredStores.sort((a, b) => (a.distance ?? 999).compareTo(b.distance ?? 999));
      }
    });
  }

  void _selectStore(Store store) {
    AppHaptics.light();
    
    UploadQueueInitializer.startNewVisit(
      operatorId: 'operator_${widget.userProfile.email.hashCode}',
      operatorName: widget.userProfile.name,
      storeId: store.id,
      storeName: store.name,
    );
    
    debugPrint('\n🔄 STORE SELECTION ROUTING DEBUG:');
    debugPrint('   Store: ${store.name} (${store.id})');
    debugPrint('   User Profile Type: ${widget.userProfile.userType}');
    
    if (widget.userProfile.userType == UserType.inStore) {
      debugPrint('   ✅ ROUTE: Profile A -> Direct to camera (label capture)');
      _navigateToCameraScreen(store, null, null, null, CameraMode.labelCapture);
    } else {
      debugPrint('   ✅ ROUTE: Profile B -> Location selection first');
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
    
    String logoPath = '';
    
    if (chainLower.contains('coles')) {
      logoPath = 'assets/images/store_logos/coles_logo.png';
    } else if (chainLower.contains('woolworth') || chainLower.contains('woolies')) {
      logoPath = 'assets/images/store_logos/Woolworths_logo.png';
    } else if (chainLower.contains('iga')) {
      logoPath = 'assets/images/store_logos/iga_logo.png';
    } else if (chainLower.contains('aldi')) {
      logoPath = 'assets/images/store_logos/aldi_logo.png';
    } else if (chainLower.contains('new world') || chainLower.contains('newworld')) {
      logoPath = 'assets/images/store_logos/newworld_logo.png';
    }
    
    if (logoPath.isNotEmpty) {
      debugPrint('🎨 LOGO PATH: "$chain" -> "$logoPath"');
    }
    
    return logoPath;
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
    debugPrint('🏁 LOGO: Store "${store.name}" chain="${store.chain}" -> path="$logoPath"');
    
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
                          debugPrint('❌ LOGO ERROR: Failed to load "$logoPath" - Error: $error');
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
                    store.address,
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
                              '${store.distance?.toStringAsFixed(1) ?? '?'} km',
                              style: AppDesignSystem.caption2.copyWith(
                                color: _getChainColor(store.chain),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
