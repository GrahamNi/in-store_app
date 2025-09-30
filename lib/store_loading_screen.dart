import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'core/design_system.dart';
import 'components/app_logo.dart';
import 'models/app_models.dart';
import 'main_navigation_wrapper.dart';
import 'services/store_service.dart';
import 'services/store_cache.dart';

/// Pre-loads all stores after login and before showing the main app
class StoreLoadingScreen extends StatefulWidget {
  final UserProfile userProfile;
  
  const StoreLoadingScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<StoreLoadingScreen> createState() => _StoreLoadingScreenState();
}

class _StoreLoadingScreenState extends State<StoreLoadingScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  String _statusMessage = 'Requesting location permission...';
  int _loadedStores = 0;
  int _totalStores = 0;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _initializeApp();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeApp() async {
    try {
      // Step 1: Request location permission
      setState(() {
        _statusMessage = 'Requesting location permission...';
      });
      
      await _requestLocationPermission();
      
      // Step 2: Get user location
      setState(() {
        _statusMessage = 'Getting your location...';
      });
      
      final position = await _getUserLocation();
      debugPrint('📍 User location: ${position.latitude}, ${position.longitude}');
      
      // Step 3: Download ALL stores with progress
      setState(() {
        _statusMessage = 'Loading all stores...';
        _totalStores = 642; // Expected count
        _loadedStores = 0;
      });
      
      final stores = await StoreService.getNearestStores(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      setState(() {
        _loadedStores = stores.length;
        _totalStores = stores.length;
      });
      
      debugPrint('✅ Loaded ${stores.length} stores from API');
      
      // CRITICAL: Cache the stores for later use (PERSISTENT storage)
      await StoreCache().updateCache(
        stores,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      
      debugPrint('✅ Cached ${stores.length} stores in memory + database (PERSISTENT)');
      final stats = await StoreCache().getStats();
      debugPrint('📊 Cache stats: $stats');
      
      // Success - navigate to main app
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500)); // Brief success pause
        
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                MainNavigationWrapper(
                  userProfile: widget.userProfile,
                  initialIndex: 0,
                ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
      
    } catch (e) {
      debugPrint('❌ Store loading error: $e');
      
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = 'Failed to load stores: $e';
        });
      }
    }
  }
  
  Future<void> _requestLocationPermission() async {
    debugPrint('📍 PERMISSION: Checking location permission...');
    
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('📍 PERMISSION: Current status: $permission');
    
    if (permission == LocationPermission.denied) {
      debugPrint('📍 PERMISSION: Requesting permission...');
      permission = await Geolocator.requestPermission();
      debugPrint('📍 PERMISSION: New status: $permission');
    }
    
    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ PERMISSION: Permanently denied');
      throw Exception('Location permission denied permanently. Please enable in settings.');
    }
    
    if (permission == LocationPermission.denied) {
      debugPrint('❌ PERMISSION: Denied');
      throw Exception('Location permission denied.');
    }
    
    debugPrint('✅ PERMISSION: Granted');
  }
  
  Future<Position> _getUserLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      // Fallback to Newcastle if location fails
      debugPrint('⚠️ Location failed, using fallback: $e');
      setState(() {
        _statusMessage = 'Using default location...';
      });
      
      // Return a fallback position
      return Position(
        latitude: -32.9273,
        longitude: 151.7817,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
  }
  
  void _retry() {
    setState(() {
      _hasError = false;
      _statusMessage = 'Retrying...';
    });
    _initializeApp();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.systemBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDesignSystem.spacing2xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Logo
                const AppLogo(
                  type: AppLogoType.inStore,
                  width: 240,
                  height: 96,
                ),
                
                const SizedBox(height: AppDesignSystem.spacing3xl),
                
                // Loading indicator or error icon
                if (!_hasError) ...[
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppDesignSystem.primaryOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppDesignSystem.primaryOrange,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppDesignSystem.systemRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppDesignSystem.systemRed,
                    ),
                  ),
                ],
                
                const SizedBox(height: AppDesignSystem.spacing2xl),
                
                // Status message
                Text(
                  _statusMessage,
                  style: AppDesignSystem.body.copyWith(
                    color: _hasError 
                        ? AppDesignSystem.systemRed 
                        : AppDesignSystem.labelSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Progress counter (when loading stores)
                if (!_hasError && _totalStores > 0) ...[
                  const SizedBox(height: AppDesignSystem.spacingMd),
                  Text(
                    'Loaded $_loadedStores of $_totalStores stores',
                    style: AppDesignSystem.callout.copyWith(
                      color: AppDesignSystem.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDesignSystem.spacingSm),
                  Container(
                    width: 200,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _totalStores > 0 ? _loadedStores / _totalStores : 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppDesignSystem.primaryOrange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: AppDesignSystem.spacingXl),
                
                // Retry button (if error)
                if (_hasError) ...[
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesignSystem.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDesignSystem.spacing2xl,
                        vertical: AppDesignSystem.spacingMd,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppDesignSystem.spacingMd),
                  
                  TextButton(
                    onPressed: () {
                      // Continue without stores - will use fallback
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainNavigationWrapper(
                            userProfile: widget.userProfile,
                            initialIndex: 0,
                          ),
                        ),
                      );
                    },
                    child: const Text('Continue Anyway'),
                  ),
                ],
                
                const Spacer(),
                
                // Dtex branding
                const AppLogo(
                  type: AppLogoType.dtex,
                  width: 100,
                  height: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
