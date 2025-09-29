import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'qa_system.dart';

/// Simplified QA Overlay Widget - Only shows helpful hints when needed
class CameraQAOverlay extends StatelessWidget {
  final QAAssessment assessment;
  final bool isLabelMode;
  final Size screenSize;

  const CameraQAOverlay({
    super.key,
    required this.assessment,
    required this.isLabelMode,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Only show subtle indicators when there are actual issues
        
        // Stability indicator (only show if poor)
        if (assessment.stability == StabilityLevel.poor)
          Positioned(
            top: 120,
            left: 20,
            child: _buildSimpleStabilityHint(),
          ),
        
        // Focus quality indicator (only show if blurred)
        if (assessment.focusQuality == FocusQuality.blurred)
          Positioned(
            top: 120,
            right: 20,
            child: _buildSimpleFocusHint(),
          ),
      ],
    );
  }

  Widget _buildSimpleStabilityHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.phone_android,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Hold Steady',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleFocusHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.center_focus_strong,
            color: Colors.blue,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Tap to Focus',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simplified Haptic feedback helper for QA events
class QAHapticManager {
  static DateTime? _lastExcellentFeedback;
  static DateTime? _lastPoorFeedback;
  
  static void onQualityChange(QAAssessment current, QAAssessment? previous) {
    final now = DateTime.now();
    
    // Excellent quality achieved (subtle positive feedback)
    if (current.isExcellentQuality && (previous == null || !previous.isExcellentQuality)) {
      if (_lastExcellentFeedback == null || 
          now.difference(_lastExcellentFeedback!) > const Duration(seconds: 3)) {
        HapticFeedback.lightImpact();
        _lastExcellentFeedback = now;
      }
    }
    
    // Quality dropped to poor (gentle warning)
    if (current.overallScore < 0.4 && (previous == null || previous.overallScore >= 0.4)) {
      if (_lastPoorFeedback == null || 
          now.difference(_lastPoorFeedback!) > const Duration(seconds: 2)) {
        HapticFeedback.selectionClick();
        _lastPoorFeedback = now;
      }
    }
  }
}

/// Simplified capture button quality indicator
class CaptureButtonQAIndicator extends StatelessWidget {
  final QAAssessment assessment;
  final double size;

  const CaptureButtonQAIndicator({
    super.key,
    required this.assessment,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final qualityColor = _getQualityColor();
    
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: qualityColor.withOpacity(0.6),
          width: 2,
        ),
      ),
    );
  }

  Color _getQualityColor() {
    if (assessment.isExcellentQuality) {
      return Colors.green;
    } else if (assessment.isGoodQuality) {
      return const Color(0xFF27AE60);
    } else if (assessment.overallScore >= 0.4) {
      return const Color(0xFFFF9500);
    } else {
      return const Color(0xFFE74C3C);
    }
  }
}
