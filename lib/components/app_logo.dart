import 'package:flutter/material.dart';

/// Logo component for displaying app and client logos
enum AppLogoType {
  inStore,
  dtex,
}

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    required this.type,
    this.width = 120,
    this.height = 40,
  });

  final AppLogoType type;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case AppLogoType.inStore:
        return _buildInStoreLogo();
      case AppLogoType.dtex:
        return _buildDtexLogo();
    }
  }

  Widget _buildInStoreLogo() {
    return Image.asset(
      'assets/images/instore_logo.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to text logo if image fails to load
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E5C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF1E1E5C).withOpacity(0.3),
            ),
          ),
          child: const Center(
            child: Text(
              'in-store',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E5C),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDtexLogo() {
    return Image.asset(
      'assets/images/dtex_logo.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to text logo if image fails to load
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFEE6F1F).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFEE6F1F).withOpacity(0.3),
            ),
          ),
          child: const Center(
            child: Text(
              'dtex',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEE6F1F),
              ),
            ),
          ),
        );
      },
    );
  }
}
