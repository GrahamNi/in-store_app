import 'package:flutter/material.dart';
import 'core/design_system.dart';
import 'components/app_components.dart';
import 'components/app_logo.dart';
import 'models/app_models.dart';
import 'store_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile userProfile;
  
  const HomeScreen({
    super.key,
    required this.userProfile,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppDesignSystem.animationStandard,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppDesignSystem.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppDesignSystem.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.systemBackground,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: context.responsivePadding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 100,
                      maxWidth: AppDesignSystem.mobileMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppDesignSystem.spacingLg),
                        
                        // Client Logo
                        _buildHeaderLogo(),
                        
                        const SizedBox(height: AppDesignSystem.spacing2xl),
                        
                        // Welcome message
                        _buildWelcomeMessage(),
                        
                        const SizedBox(height: AppDesignSystem.spacing3xl),
                        
                        // Main action based on user type
                        if (widget.userProfile.userType == UserType.inStore)
                          _buildInStoreUserActions()
                        else
                          _buildInStorePromoUserActions(),
                        
                        const SizedBox(height: AppDesignSystem.spacing2xl),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppDesignSystem.systemBackground,
      foregroundColor: AppDesignSystem.labelPrimary,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'In-Store',
        style: AppDesignSystem.headline.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHeaderLogo() {
    // Show client logo based on user profile
    switch (widget.userProfile.clientLogo) {
      case ClientLogo.rdas:
        return _buildRdasLogo();
      case ClientLogo.fmcg:
        return _buildClientLogo('FMCG', Icons.shopping_cart);
      case ClientLogo.inStore:
        return _buildInStoreLogo();
    }
  }

  Widget _buildRdasLogo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 30),
        child: Image.asset(
          'assets/images/rdas_logo.png',
          height: 80,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback if logo not found
            return _buildClientLogo('RDAS', Icons.business);
          },
        ),
      ),
    );
  }

  Widget _buildInStoreLogo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 30),
        child: Image.asset(
          'assets/images/instore_logo.png',
          height: 80,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to AppLogo component
            return const AppLogo(
              type: AppLogoType.inStore,
              width: 200,
              height: 80,
            );
          },
        ),
      ),
    );
  }

  Widget _buildClientLogo(String clientName, IconData icon) {
    return Center(
      child: Container(
        width: 200,
        height: 80,
        decoration: BoxDecoration(
          color: AppDesignSystem.primaryNavy.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusLg),
          border: Border.all(
            color: AppDesignSystem.primaryNavy.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: AppDesignSystem.primaryNavy,
            ),
            const SizedBox(height: 4),
            Text(
              clientName,
              style: AppDesignSystem.callout.copyWith(
                color: AppDesignSystem.primaryNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    final timeOfDay = DateTime.now().hour;
    String greeting;
    if (timeOfDay < 12) {
      greeting = 'Good Morning';
    } else if (timeOfDay < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      children: [
        Text(
          '$greeting, ${widget.userProfile.name.split(' ').first}',
          style: AppDesignSystem.title2.copyWith(
            fontWeight: FontWeight.w700,
            color: AppDesignSystem.labelPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDesignSystem.spacingSm),
      ],
    );
  }

  Widget _buildInStoreUserActions() {
    return Column(
      children: [
        // New Visit Button
        AppPrimaryButton(
          onPressed: () => _startNewVisit(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white),
              SizedBox(width: AppDesignSystem.spacingSm),
              Text('Start New Visit'),
            ],
          ),
        ),
        
        const SizedBox(height: AppDesignSystem.spacingLg),
        
        // Continue Previous Visit Button
        AppCard(
          child: InkWell(
            onTap: () => _showPreviousVisits(),
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppDesignSystem.spacingLg),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppDesignSystem.systemBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
                    ),
                    child: Icon(
                      Icons.history,
                      color: AppDesignSystem.systemBlue,
                      size: AppDesignSystem.iconLg,
                    ),
                  ),
                  const SizedBox(width: AppDesignSystem.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Continue Previous Visit',
                          style: AppDesignSystem.headline.copyWith(
                            color: AppDesignSystem.labelPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Resume incomplete visits',
                          style: AppDesignSystem.footnote.copyWith(
                            color: AppDesignSystem.labelSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppDesignSystem.labelTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInStorePromoUserActions() {
    return AppPrimaryButton(
      onPressed: () => _startStoreSelection(),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store, color: Colors.white),
          SizedBox(width: AppDesignSystem.spacingSm),
          Text('Begin Store Visit'),
        ],
      ),
    );
  }

  void _startNewVisit() {
    AppHaptics.light();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => StoreSelectionScreen(
          userProfile: widget.userProfile,
          isFirstTime: false,
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

  void _startStoreSelection() {
    _startNewVisit();
  }

  void _showPreviousVisits() {
    AppHaptics.light();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Previous visits feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
