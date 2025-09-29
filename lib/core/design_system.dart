import 'package:flutter/material.dart';

/// Mobile-first design system for Label Scanner
/// Optimized for phone usage with tablet support as secondary
class AppDesignSystem {
  // Private constructor to prevent instantiation
  AppDesignSystem._();

  /// Brand Colors
  static const Color primaryNavy = Color(0xFF1E1E5C);
  static const Color primaryOrange = Color(0xFFEE6F1F);

  /// Extended Color Palette (Apple-inspired)
  static const Color systemBackground = Color(0xFFFFFFFF);
  static const Color secondarySystemBackground = Color(0xFFF2F2F7);
  static const Color tertiarySystemBackground = Color(0xFFFFFFFF);
  
  static const Color systemGroupedBackground = Color(0xFFF2F2F7);
  static const Color secondarySystemGroupedBackground = Color(0xFFFFFFFF);
  static const Color tertiarySystemGroupedBackground = Color(0xFFF2F2F7);

  /// Text Colors
  static const Color labelPrimary = Color(0xFF000000);
  static const Color labelSecondary = Color(0xFF3C3C43);
  static const Color labelTertiary = Color(0xFF3C3C43);
  static const Color labelQuaternary = Color(0xFF3C3C43);

  /// Semantic Colors
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemYellow = Color(0xFFFFCC00);
  static const Color systemPurple = Color(0xFFAF52DE);

  /// Gray Scale
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFFAEAEB2);
  static const Color systemGray3 = Color(0xFFC7C7CC);
  static const Color systemGray4 = Color(0xFFD1D1D6);
  static const Color systemGray5 = Color(0xFFE5E5EA);
  static const Color systemGray6 = Color(0xFFF2F2F7);

  /// Separator Colors
  static const Color separator = Color(0x543C3C43);
  static const Color opaqueSeparator = Color(0xFFC6C6C8);

  /// Mobile-First Typography Scale (optimized for phones)
  static const TextStyle largeTitle = TextStyle(
    fontSize: 32, // Reduced for mobile
    fontWeight: FontWeight.w400,
    letterSpacing: 0.35,
    height: 1.12,
    color: labelPrimary,
  );

  static const TextStyle title1 = TextStyle(
    fontSize: 26, // Reduced for mobile
    fontWeight: FontWeight.w400,
    letterSpacing: 0.34,
    height: 1.14,
    color: labelPrimary,
  );

  static const TextStyle title2 = TextStyle(
    fontSize: 20, // Reduced for mobile
    fontWeight: FontWeight.w400,
    letterSpacing: 0.33,
    height: 1.27,
    color: labelPrimary,
  );

  static const TextStyle title3 = TextStyle(
    fontSize: 18, // Reduced for mobile
    fontWeight: FontWeight.w400,
    letterSpacing: 0.36,
    height: 1.20,
    color: labelPrimary,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.41,
    height: 1.29,
    color: labelPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.41,
    height: 1.29,
    color: labelPrimary,
  );

  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
    height: 1.31,
    color: labelPrimary,
  );

  static const TextStyle subheadline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.24,
    height: 1.33,
    color: labelPrimary,
  );

  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
    height: 1.38,
    color: labelPrimary,
  );

  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
    color: labelPrimary,
  );

  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.07,
    height: 1.45,
    color: labelPrimary,
  );

  /// Mobile-First Spacing Scale (optimized for thumb usage)
  static const double spacing2xs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0; // Base unit
  static const double spacingLg = 20.0; // Reduced for mobile
  static const double spacingXl = 28.0; // Reduced for mobile
  static const double spacing2xl = 32.0; // Reduced for mobile
  static const double spacing3xl = 40.0; // Reduced for mobile

  /// Mobile-Optimized Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radius2xl = 24.0;

  /// Shadows (Subtle, optimized for mobile)
  static const BoxShadow shadowSm = BoxShadow(
    color: Color(0x0F000000), // Slightly stronger for mobile
    offset: Offset(0, 1),
    blurRadius: 3,
    spreadRadius: 0,
  );

  static const BoxShadow shadowMd = BoxShadow(
    color: Color(0x18000000), // Slightly stronger for mobile
    offset: Offset(0, 2),
    blurRadius: 8,
    spreadRadius: 0,
  );

  static const BoxShadow shadowLg = BoxShadow(
    color: Color(0x1F000000), // Slightly stronger for mobile
    offset: Offset(0, 4),
    blurRadius: 12,
    spreadRadius: 0,
  );

  /// Mobile-Optimized Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150); // Faster for mobile
  static const Duration animationStandard = Duration(milliseconds: 250); // Faster for mobile
  static const Duration animationSlow = Duration(milliseconds: 400); // Faster for mobile

  /// Animation Curves (Mobile-optimized)
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;

  /// Mobile Touch Target Sizes (thumb-friendly)
  static const double touchTargetMin = 48.0; // Increased from 44 for easier tapping
  static const double touchTargetComfortable = 52.0; // Comfortable thumb reach
  static const double touchTargetLarge = 60.0; // For primary actions

  /// Mobile-Optimized Icon Sizes
  static const double iconXs = 14.0; // Slightly larger for mobile
  static const double iconSm = 18.0; // Slightly larger for mobile
  static const double iconMd = 22.0; // Slightly larger for mobile
  static const double iconLg = 26.0; // Slightly larger for mobile
  static const double iconXl = 32.0;
  static const double icon2xl = 40.0;

  /// Mobile-Specific Measurements
  static const double mobileMaxWidth = 428.0; // iPhone 14 Pro Max width
  static const double tabletBreakpoint = 768.0; // When to switch to tablet layout
  
  // Safe area padding for mobile devices
  static const EdgeInsets mobileSafeAreaPadding = EdgeInsets.only(
    left: spacingMd,
    right: spacingMd,
    bottom: spacingMd,
  );

  /// Responsive helper methods
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  static EdgeInsets responsivePadding(BuildContext context) {
    return isMobile(context) 
        ? const EdgeInsets.all(spacingMd)
        : const EdgeInsets.all(spacingLg);
  }

  static double responsiveSpacing(BuildContext context, {
    double mobile = spacingMd,
    double tablet = spacingLg,
  }) {
    return isMobile(context) ? mobile : tablet;
  }

  /// Theme Data (Mobile-First)
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    primarySwatch: Colors.blue,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryNavy,
      brightness: Brightness.light,
      primary: primaryNavy,
      secondary: primaryOrange,
      surface: systemBackground,
    ),
    scaffoldBackgroundColor: systemBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: systemBackground,
      foregroundColor: labelPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Color(0x1A000000),
      titleTextStyle: headline,
      centerTitle: false,
      toolbarHeight: 56, // Standard mobile app bar height
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        minimumSize: const Size(double.infinity, touchTargetMin),
        textStyle: headline.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryOrange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        minimumSize: const Size(double.infinity, touchTargetMin),
        textStyle: headline,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingLg,
          vertical: spacingMd,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tertiarySystemGroupedBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primaryOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: systemRed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingLg, // More padding for mobile
        vertical: spacingMd,
      ),
      hintStyle: body.copyWith(color: labelTertiary),
    ),
    dividerTheme: const DividerThemeData(
      color: separator,
      thickness: 0.5,
      space: 1,
    ),
    textTheme: const TextTheme(
      displayLarge: largeTitle,
      displayMedium: title1,
      displaySmall: title2,
      headlineLarge: title3,
      headlineMedium: headline,
      headlineSmall: headline,
      titleLarge: headline,
      titleMedium: callout,
      titleSmall: subheadline,
      bodyLarge: body,
      bodyMedium: callout,
      bodySmall: subheadline,
      labelLarge: headline,
      labelMedium: footnote,
      labelSmall: caption1,
    ),
    iconTheme: const IconThemeData(
      color: labelSecondary,
      size: iconMd,
    ),
  );
}

/// Extension methods for convenient design system access
extension AppDesignSystemExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  // Mobile-specific helpers
  bool get isMobile => AppDesignSystem.isMobile(this);
  bool get isTablet => AppDesignSystem.isTablet(this);
  EdgeInsets get responsivePadding => AppDesignSystem.responsivePadding(this);
}