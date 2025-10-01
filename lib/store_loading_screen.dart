import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/design_system.dart';
import 'components/app_logo.dart';
import 'models/app_models.dart';
import 'main_navigation_wrapper.dart';
import 'services/store_service.dart';
import 'services/database_helper.dart';

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
  
  String _statusMessage = 'Setting up stores...';
  bool _hasError = false;
  String _debugInfo = '';
  
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
      // Step 1: Get user_id from SharedPreferences (saved during login)
      setState(() {
        _statusMessage = 'Verifying credentials...';
      });
      
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🏪 STORE LOADING: Starting initialization');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userEmail = prefs.getString('user_email');
      
      debugPrint('🏪 STORE LOADING: User ID: $userId');
      debugPrint('🏪 STORE LOADING: User Email: $userEmail');
      
      if (userId == null || userId.isEmpty) {
        throw Exception('No user_id found in SharedPreferences. Please log in again.');
      }
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Step 2: Download ALL stores from API using user_id as token
      setState(() {
        _statusMessage = 'Downloading stores...';
      });
      
      debugPrint('🏪 STORE LOADING: Calling StoreService.fetchStores()...');
      
      final stores = await StoreService.fetchStores();
      
      debugPrint('🏪 STORE LOADING: Received ${stores.length} stores');
      
      // Step 3: Save ALL stores to SQLite database
      setState(() {
        _statusMessage = 'Saving stores...';
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      debugPrint('🏪 STORE LOADING: Saving to database...');
      
      final storesJson = stores.map((store) => store.toJson()).toList();
      final db = DatabaseHelper();
      await db.saveStoresCache(storesJson);
      
      debugPrint('✅ STORE LOADING: Successfully saved ${stores.length} stores');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      setState(() {
        _statusMessage = 'Complete!';
      });
      
      // Step 4: Navigate to MainNavigationWrapper
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        
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
      
    } catch (e, stackTrace) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ STORE LOADING ERROR: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = 'Error: $e';
          _debugInfo = 'Error details:\n$e\n\nPlease check console for full details.';
        });
      }
    }
  }
  
  void _retry() {
    setState(() {
      _hasError = false;
      _statusMessage = 'Setting up stores...';
      _debugInfo = '';
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
                
                const AppLogo(
                  type: AppLogoType.inStore,
                  width: 240,
                  height: 96,
                ),
                
                const SizedBox(height: AppDesignSystem.spacing3xl),
                
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
                
                Text(
                  _statusMessage,
                  style: AppDesignSystem.body.copyWith(
                    color: _hasError 
                        ? AppDesignSystem.systemRed 
                        : AppDesignSystem.labelSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Debug info
                if (_debugInfo.isNotEmpty) ...[
                  const SizedBox(height: AppDesignSystem.spacingMd),
                  Container(
                    padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _debugInfo,
                      style: AppDesignSystem.footnote.copyWith(
                        fontFamily: 'monospace',
                        color: const Color(0xFF1a1e5c),
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
                
                const SizedBox(height: AppDesignSystem.spacingXl),
                
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
