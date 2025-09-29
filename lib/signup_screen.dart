import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/design_system.dart';
import 'components/app_components.dart';
import 'components/app_logo.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _profileController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
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

  Future<void> _handleSignUp() async {
    // Clear previous server error
    setState(() {
      _serverErrorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    AppHaptics.light();
    
    try {
      // API call to create account
      final result = await _createAccount(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        profile: _profileController.text.trim(),
      );
      
      if (mounted) {
        if (result['success'] == true) {
          // Success - show success message and navigate back
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Account created successfully! Your account requires administrator activation before you can sign in.',
              ),
              backgroundColor: AppDesignSystem.systemGreen,
              duration: const Duration(seconds: 4),
            ),
          );
          Navigator.pop(context);
        } else {
          // Server error - show specific error message
          setState(() {
            _serverErrorMessage = result['message'] ?? 'Failed to create account. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverErrorMessage = 'Network error. Please check your connection and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _createAccount({
    required String name,
    required String email,
    required String password,
    required String profile,
  }) async {
    // Simulate API call - replace with actual API integration
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Mock validation logic - replace with actual API call
    if (profile.toLowerCase() == 'invalid') {
      return {
        'success': false,
        'message': 'Invalid profile code. Please contact your administrator for the correct profile code.',
      };
    }
    
    if (profile.toLowerCase() == 'inactive') {
      return {
        'success': false,
        'message': 'This profile is currently inactive. Please contact your administrator.',
      };
    }
    
    // Mock successful registration
    return {
      'success': true,
      'message': 'Account created successfully! Your account requires administrator activation before you can sign in.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.systemBackground,
      appBar: AppBar(
        backgroundColor: AppDesignSystem.systemBackground,
        foregroundColor: AppDesignSystem.labelPrimary,
        elevation: 0,
        leading: AppIconButton(
          icon: Icons.arrow_back_ios,
          onPressed: () {
            AppHaptics.light();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: AppLoadingOverlay(
          isLoading: _isLoading,
          message: 'Creating account...',
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
                    minHeight: constraints.maxHeight - 56,
                    maxWidth: AppDesignSystem.mobileMaxWidth,
                  ),
                  child: Form(
                    key: _formKey,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: AppDesignSystem.spacingLg),
                            
                            // Logo
                            const AppLogo(
                              type: AppLogoType.inStore,
                              width: 140,
                              height: 55,
                            ),
                            
                            const SizedBox(height: AppDesignSystem.spacingXl),
                            
                            // Title
                            Text(
                              'Create Account',
                              style: AppDesignSystem.title1.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppDesignSystem.labelPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: AppDesignSystem.spacingSm),
                            
                            // Subtitle
                            Text(
                              'Join the In-Store platform',
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
                            
                            // Sign Up Form
                            _buildSignUpForm(),
                            
                            const SizedBox(height: AppDesignSystem.spacingXl),
                            
                            // Create Account Button
                            AppPrimaryButton(
                              onPressed: _handleSignUp,
                              isLoading: _isLoading,
                              child: const Text('Create Account'),
                            ),
                            
                            const SizedBox(height: AppDesignSystem.spacingLg),
                            
                            // Sign In Link
                            Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: AppDesignSystem.subheadline.copyWith(
                                    color: AppDesignSystem.labelSecondary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    AppHaptics.light();
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Sign In',
                                    style: AppDesignSystem.subheadline.copyWith(
                                      color: AppDesignSystem.primaryOrange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
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

  Widget _buildSignUpForm() {
    return Column(
      children: [
        // Full Name Field
        TextFormField(
          controller: _nameController,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          style: AppDesignSystem.body,
          decoration: InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: const Icon(
              Icons.person_outline,
              size: AppDesignSystem.iconMd,
            ),
            labelStyle: AppDesignSystem.callout.copyWith(
              color: AppDesignSystem.labelSecondary,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your full name';
            }
            if (value.trim().length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppDesignSystem.spacingLg),
        
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
        
        // Profile Field (Mandatory)
        TextFormField(
          controller: _profileController,
          textInputAction: TextInputAction.next,
          style: AppDesignSystem.body,
          decoration: InputDecoration(
            labelText: 'Profile Code*',
            hintText: 'Enter your organization profile code',
            prefixIcon: const Icon(
              Icons.business_outlined,
              size: AppDesignSystem.iconMd,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.info_outline,
                size: AppDesignSystem.iconSm,
                color: AppDesignSystem.labelSecondary,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Profile Code'),
                    content: const Text('The profile code is provided by your organization administrator. Contact them if you don\'t have this code.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
            labelStyle: AppDesignSystem.callout.copyWith(
              color: AppDesignSystem.labelSecondary,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Profile code is required';
            }
            if (value.trim().length < 3) {
              return 'Profile code must be at least 3 characters';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppDesignSystem.spacingLg),
        
        // Password Field
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.next,
          style: AppDesignSystem.body,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Create a strong password',
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
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppDesignSystem.spacingLg),
        
        // Confirm Password Field
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          textInputAction: TextInputAction.done,
          style: AppDesignSystem.body,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            hintText: 'Confirm your password',
            prefixIcon: const Icon(
              Icons.lock_outline,
              size: AppDesignSystem.iconMd,
            ),
            suffixIcon: AppIconButton(
              icon: _isConfirmPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
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
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
          onFieldSubmitted: (_) => _handleSignUp(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _profileController.dispose();
    super.dispose();
  }
}
