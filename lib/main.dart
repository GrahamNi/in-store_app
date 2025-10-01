import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'core/design_system.dart';
import 'components/app_components.dart';
import 'components/app_logo.dart';
import 'models/app_models.dart';
import 'store_loading_screen.dart'; // NEW: Pre-load stores
import 'signup_screen.dart';
import 'core/upload_queue_initializer.dart';
import 'services/auth_service.dart';
import 'services/auth_token_manager.dart';
import 'debug_prefs_screen.dart';
import 'services/progress_ping_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the upload queue system with your actual API
  await UploadQueueInitializer.initialize(
    uploadBaseUrl: 'https://upload-image-951551492434.australia-southeast1.run.app',
    operatorId: 'default_operator',
    operatorName: 'Default Operator',
  );
  
  runApp(const LabelScannerApp());
}

class LabelScannerApp extends StatelessWidget {
  const LabelScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'In-Store',
      theme: AppDesignSystem.lightTheme,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    AppHaptics.light();
    
    try {
      // Call authentication API
      final authResponse = await AuthService.authenticate(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      debugPrint('✅ AUTH SUCCESS: $authResponse');
      debugPrint('🔑 AUTH DATA:');
      debugPrint('   - user_id: ${authResponse.userId}');
      debugPrint('   - token: ${authResponse.token ?? "null"}');
      debugPrint('   - service: ${authResponse.service ?? "null"}');
      debugPrint('   - profile: ${authResponse.profile ?? "null"}');
      debugPrint('   - name: ${authResponse.name ?? "null"}');
      debugPrint('   - isProfileA: ${authResponse.isProfileA}');
      
      // CRITICAL: Check if we got a valid user_id
      if (authResponse.userId == 'unknown') {
        debugPrint('❌ WARNING: Auth returned user_id="unknown"');
        debugPrint('❌ This means authentication failed but returned 200 OK');
        debugPrint('❌ Will use RDAS fallback for stores API');
      }
      
      // Save authentication token for API calls
      await AuthTokenManager.saveAuthData(
        token: authResponse.token ?? 'no_token',
        userId: authResponse.userId,
        userName: authResponse.name ?? _extractUserName(_emailController.text),
      );
      debugPrint('🔐 AUTH TOKEN: Saved for API requests');
      
      if (mounted) {
        // Create user profile from auth response
        UserProfile userProfile = _getUserProfileFromAuth(authResponse);
        
        debugPrint('👥 LOGIN: User ${userProfile.name} (${userProfile.email}) logged in as ${userProfile.userType}');
        
        // Start a new visit session with the logged-in user
        UploadQueueInitializer.startNewVisit(
          operatorId: authResponse.userId,
          operatorName: userProfile.name,
          storeId: 'pending_selection',
          storeName: 'Store Selection Pending',
        );
        
        debugPrint('🔄 LOGIN ROUTE: Navigating to StoreLoadingScreen');
        
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                StoreLoadingScreen(
                  userProfile: userProfile,
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
    } catch (e) {
      debugPrint('❌ AUTH FAILED: $e');
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: AppDesignSystem.systemRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  UserProfile _getUserProfileFromAuth(AuthResponse authResponse) {
    // Determine profile from auth response
    UserType userType;
    ClientLogo clientLogo;
    
    if (authResponse.isProfileA) {
      userType = UserType.inStore;
      clientLogo = ClientLogo.rdas;
      debugPrint('👥 PROFILE: Profile A (In-Store - RDAS)');
    } else {
      userType = UserType.inStorePromo;
      clientLogo = ClientLogo.fmcg;
      debugPrint('👥 PROFILE: Profile B (In-Store Promo - FMCG)');
    }
    
    return UserProfile(
      name: authResponse.name ?? _extractUserName(_emailController.text),
      email: _emailController.text.toLowerCase().trim(),
      userType: userType,
      clientLogo: clientLogo,
    );
  }
  
  String _extractUserName(String email) {
    // Extract a user-friendly name from email
    final emailPart = email.split('@').first;
    
    // Convert email part to a readable name
    if (emailPart.contains('.')) {
      final parts = emailPart.split('.');
      return parts.map((part) => 
        part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1)
      ).join(' ');
    }
    
    // Single word email - just capitalize first letter
    return emailPart.isEmpty ? 'User' : 
           emailPart[0].toUpperCase() + emailPart.substring(1);
  }

  void _handleSignUp() {
    AppHaptics.light();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SignUpScreen(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.systemBackground,
      body: SafeArea(
        child: AppLoadingOverlay(
          isLoading: _isLoading,
          message: 'Signing in...',
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Mobile-first responsive design
              final isLandscape = constraints.maxWidth > constraints.maxHeight;
              final padding = isLandscape 
                  ? const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing3xl)
                  : context.responsivePadding;
              
              return SingleChildScrollView(
                padding: padding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: AppDesignSystem.mobileMaxWidth,
                  ),
                  child: Form(
                    key: _formKey,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Responsive top spacing
                            SizedBox(height: isLandscape 
                                ? AppDesignSystem.spacingLg 
                                : AppDesignSystem.spacing2xl),
                            
                            // App Logo & Branding
                            _buildHeader(),
                            
                            // Responsive spacing between logo and form
                            SizedBox(height: isLandscape 
                                ? AppDesignSystem.spacingXl 
                                : AppDesignSystem.spacing3xl),
                            
                            // Login Form
                            _buildLoginForm(),
                            
                            const SizedBox(height: AppDesignSystem.spacingXl),
                            
                            // Login Button
                            AppPrimaryButton(
                              onPressed: _handleLogin,
                              isLoading: _isLoading,
                              child: const Text('Sign In'),
                            ),
                            
                            const SizedBox(height: AppDesignSystem.spacingLg),
                            
                            // Sign Up Link
                            _buildSignUpLink(),
                            
                            const SizedBox(height: AppDesignSystem.spacingMd),
                            
                            // Forgot Password
                            AppTextButton(
                              onPressed: () {
                                AppHaptics.light();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Forgot password feature coming soon'),
                                  ),
                                );
                              },
                              child: const Text('Forgot Password?'),
                            ),
                            
                            // Responsive bottom spacing
                            SizedBox(height: isLandscape 
                                ? AppDesignSystem.spacingLg 
                                : AppDesignSystem.spacing2xl),
                            
                            // Footer
                            _buildFooter(),
                            
                            // Test info
                            _buildTestInfo(),
                            
                            // Extra bottom spacing for mobile
                            const SizedBox(height: AppDesignSystem.spacingLg),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // In-Store Logo - made bigger per request
        const AppLogo(
          type: AppLogoType.inStore,
          width: 360, // Doubled size
          height: 140, // Doubled size
        ),
        
        const SizedBox(height: AppDesignSystem.spacingXl),
        
        // Subtitle only
        Text(
          'Sign in to continue',
          style: AppDesignSystem.subheadline.copyWith(
            color: AppDesignSystem.labelSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Email Field
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: AppDesignSystem.body,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email address',
            prefixIcon: const Icon(
              Icons.email_outlined,
              size: AppDesignSystem.iconMd,
            ),
            labelStyle: AppDesignSystem.callout.copyWith(
              color: AppDesignSystem.labelSecondary,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppDesignSystem.spacingLg),
        
        // Password Field
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          style: AppDesignSystem.body,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: const Icon(
              Icons.lock_outline,
              size: AppDesignSystem.iconMd,
            ),
            suffixIcon: AppIconButton(
              icon: _isPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
                AppHaptics.light();
              },
              size: AppDesignSystem.touchTargetMin,
              iconSize: AppDesignSystem.iconMd,
            ),
            labelStyle: AppDesignSystem.callout.copyWith(
              color: AppDesignSystem.labelSecondary,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
          onFieldSubmitted: (_) => _handleLogin(),
        ),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: AppDesignSystem.subheadline.copyWith(
            color: AppDesignSystem.labelSecondary,
          ),
        ),
        GestureDetector(
          onTap: _handleSignUp,
          child: Text(
            'Sign Up',
            style: AppDesignSystem.subheadline.copyWith(
              color: AppDesignSystem.primaryOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Dtex Logo - mobile optimized
        const AppLogo(
          type: AppLogoType.dtex,
          width: 120, // Smaller for mobile
          height: 36,  // Smaller for mobile
        ),
        
        const SizedBox(height: AppDesignSystem.spacingSm),
        
        Text(
          'Digital Data Collection',
          style: AppDesignSystem.footnote.copyWith(
            color: AppDesignSystem.labelTertiary,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTestInfo() {
    return Container(
      margin: const EdgeInsets.only(top: AppDesignSystem.spacingLg),
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      decoration: BoxDecoration(
        color: AppDesignSystem.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
        border: Border.all(
          color: AppDesignSystem.systemBlue.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Test Accounts',
            style: AppDesignSystem.footnote.copyWith(
              fontWeight: FontWeight.w600,
              color: AppDesignSystem.systemBlue,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingXs),
          Text(
            'Profile A (With Home): Email + Password with "A"\nProfile B (No Home): Email + Password with "B"',
            style: AppDesignSystem.caption2.copyWith(
              color: AppDesignSystem.labelSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
