import 'package:flutter/material.dart';
import 'core/design_system.dart';
import 'components/app_components.dart';
import 'models/app_models.dart';
import 'home_screen.dart';
import 'store_selection_screen.dart';
import 'upload_queue_screen.dart';
import 'settings_screen.dart';
import 'main.dart';

/// Main navigation wrapper with persistent bottom navigation
/// Profile A: Home → Store → Queue → Settings (4 tabs)
/// Profile B: Store → Queue → Settings (3 tabs, no home)
class MainNavigationWrapper extends StatefulWidget {
  final UserProfile userProfile;
  final int initialIndex;

  const MainNavigationWrapper({
    super.key,
    required this.userProfile,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int _currentIndex;
  late PageController _pageController;
  late List<Widget> _screens;
  late List<BottomNavigationBarItem> _navItems;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Build screens based on user profile
    if (widget.userProfile.userType == UserType.inStore) {
      // Profile A: Include Home screen
      _screens = [
        HomeScreen(userProfile: widget.userProfile),
        StoreSelectionScreen(userProfile: widget.userProfile),
        const UploadQueueScreen(),
        SettingsScreen(userProfile: widget.userProfile),
      ];
      
      _navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store_outlined),
          activeIcon: Icon(Icons.store),
          label: 'Store',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.cloud_upload_outlined),
          activeIcon: Icon(Icons.cloud_upload),
          label: 'Queue',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'More',
        ),
      ];
    } else {
      // Profile B: No Home screen
      _screens = [
        StoreSelectionScreen(userProfile: widget.userProfile),
        const UploadQueueScreen(),
        SettingsScreen(userProfile: widget.userProfile),
      ];
      
      _navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.store_outlined),
          activeIcon: Icon(Icons.store),
          label: 'Store',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.cloud_upload_outlined),
          activeIcon: Icon(Icons.cloud_upload),
          label: 'Queue',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'More',
        ),
      ];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    
    AppHaptics.light();
    setState(() {
      _currentIndex = index;
    });
    
    _pageController.animateToPage(
      index,
      duration: AppDesignSystem.animationStandard,
      curve: AppDesignSystem.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppDesignSystem.systemBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: const Offset(0, -1),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 70,
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppDesignSystem.primaryOrange,
              unselectedItemColor: AppDesignSystem.systemGray,
              selectedLabelStyle: AppDesignSystem.caption1.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 9,
              ),
              unselectedLabelStyle: AppDesignSystem.caption1.copyWith(
                fontSize: 9,
              ),
              iconSize: 20,
              items: _navItems,
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function to navigate to main navigation from any screen
void navigateToMainNavigation(
  BuildContext context, 
  UserProfile userProfile, {
  int initialIndex = 0,
}) {
  Navigator.pushAndRemoveUntil(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => 
          MainNavigationWrapper(
            userProfile: userProfile,
            initialIndex: initialIndex,
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
    (route) => false,
  );
}
