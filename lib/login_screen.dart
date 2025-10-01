import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/design_system.dart';
import 'components/app_components.dart';
import 'components/app_logo.dart';
import 'models/app_models.dart';
import 'store_loading_screen.dart';
import 'signup_screen.dart';
import 'services/auth_service.dart';

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
  String? _serverErrorMessage;
  
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
    setState(() {
      _serverErrorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    AppHaptics.light();
    
    try {
      debugPrint('🔑 LOGIN: Starting authentication for ${_emailController.text}');
      
      // ✅ CALL REAL AUTH API
      final authResponse = await AuthService.authenticate(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      debugPrint('✅ LOGIN: Authentication successful!');
      debugPrint('   User ID: ${authResponse.userId}');
      debugPrint('   Profile: ${authResponse.profile}');
      debugPrint('   Service: ${authResponse.service}');
      
      // ✅ SAVE USER DATA TO SHARED PREFERENCES (INCLUDING user_id)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', authResponse.userId);
      await prefs.setString('user_email', _emailController.text.trim());
      await prefs.setString('user_name', authResponse.name ?? _emailController.text.split('@').first);
      
      if (authResponse.token != null) {
        await prefs.setString('auth_token', authResponse.token!);
      }
      if (authResponse.profile != null) {
        await prefs.setString('user_profile', authResponse.profile!);
      }
      if (authResponse.service != null) {
        await prefs.setString('user_service', authResponse.service!);
      }
      
      debugPrint('💾 LOGIN: User data saved to SharedPreferences');
      debugPrint('   user_id: ${authResponse.userId}');
      
      // ✅ CREATE USER PROFILE FROM AUTH RESPONSE
      final userProfile = UserProfile(
        name: authResponse.name ?? _emailController.text.split('@').first,
        email: _emailController.text.trim(),
        userType: authResponse.isProfileA ? UserType.inStore : UserType.inStorePromo,
        clientLogo: ClientLogo.inStore,
      );
      
      // ✅ NAVIGATE TO STORE LOADING SCREEN (which will download stores)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StoreLoadingScreen(
              userProfile: userProfile,
            ),
          ),
        );
      }
      
    } on AuthException catch (e) {
      debugPrint('❌ LOGIN: Auth error: $e');
      if (mounted) {
        setState(() {
          _serverErrorMessage = e.message;
        });
      }
    } catch (e) {
      debugPrint('❌ LOGIN: Unexpected error: $e');
      if (mounted) {
        setState(() {
          _serverErrorMessage = 'Login failed. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.systemBackground,
      body: SafeArea(
        child: AppLoadingOverlay(
          isLoading: _isLoading,
          message: _isLoading ? 'Authenticating...' : '',
          child: LayoutBuilder(
            builder: (context, constraints) {
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
                            const SizedBox(height: AppDesignSystem.spacingXl),
                            
                            // Logo
                            const AppLogo(
                              type: AppLogoType.inStore,
                              width: 140,
                              height: 55,
                            ),
                            
                            const SizedBox(height: AppDesignSystem.spacingXl),
                            
                            // Title
                            Text(
                              'Welcome Back',
                              style: AppDesignSystem.title1.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppDesignSystem.labelPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: AppDesignSystem.spacingSm),
                            
                            // Subtitle
                            Text(
                              'Sign in to continue',
                              style: AppDesignSystem.subheadline.copyWith(
                                color: AppDesignSystem.labelSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: AppDesignSystem.spacingXl),
                            
                            // Server Error Message
                            if (_serverErrorMessage != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: AppDesignSystem.spacingLg),
                                padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
                                decoration: BoxDecoration(
                                  color: AppDesignSystem.systemRed.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
                                  border: Border.all(
                                    color: AppDesignSystem.systemRed.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: AppDesignSystem.systemRed,
                                      size: AppDesignSystem.iconMd,
                                    ),
                                    const SizedBox(width: AppDesignSystem.spacingSm),
                                    Expanded(
                                      child: Text(
                                        _serverErrorMessage!,
                                        style: AppDesignSystem.callout.copyWith(
                                          color: AppDesignSystem.systemRed,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Login Form
                            _buildLoginForm(),
                            
                            const SizedBox(height: AppDesignSystem.spacingXl),
                            
                            // Sign In Button
                            AppPrimaryButton(
                              onPressed: _handleLogin,
                              isLoading: _isLoading,
                              child: const Text('Sign In'),
                            ),
                            
                            const SizedBox(height: AppDesignSystem.spacingLg),
                            
                            // Sign Up Link
                            Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                Text(
                                  'Don\'t have an account? ',
                                  style: AppDesignSystem.subheadline.copyWith(
                                    color: AppDesignSystem.labelSecondary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    AppHaptics.light();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SignUpScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Sign Up',
                                    style: AppDesignSystem.subheadline.copyWith(
                                      color: AppDesignSystem.primaryOrange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: AppDesignSystem.spacingXl),
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
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email';
            }
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value.trim())) {
              return 'Please enter a valid email address';
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

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
