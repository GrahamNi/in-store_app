import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:camera/camera.dart';

/// QA Profile - Determines capture speed and quality thresholds
enum QAProfile {
  fast,    // Profile A - Up to 2000 images, minimal delay, essential checks only
  quality  // Profile B - Smaller fonts, more time, full quality checks
}

/// QA Assessment Results
class QAAssessment {
  final StabilityLevel stability;
  final FocusQuality focusQuality;
  final bool hasDetectedLabels;
  final List<LabelCorner> detectedCorners;
  final double overallScore;

  QAAssessment({
    required this.stability,
    required this.focusQuality,
    this.hasDetectedLabels = false,
    this.detectedCorners = const [],
    required this.overallScore,
  });

  bool get isGoodQuality => overallScore >= 0.7;
  bool get isExcellentQuality => overallScore >= 0.9;
}

enum StabilityLevel {
  excellent(0.95, Colors.green, 'Excellent'),
  good(0.8, Color(0xFF27AE60), 'Good'),
  fair(0.6, Color(0xFFFF9500), 'Fair'),
  poor(0.3, Color(0xFFE74C3C), 'Poor');

  const StabilityLevel(this.score, this.color, this.label);
  final double score;
  final Color color;
  final String label;
}

enum FocusQuality {
  sharp(0.9, Colors.green, 'Sharp'),
  good(0.75, Color(0xFF27AE60), 'Good'),
  soft(0.5, Color(0xFFFF9500), 'Soft'),
  blurred(0.2, Color(0xFFE74C3C), 'Blurred'),
  unknown(0.5, Colors.grey, 'Focusing');

  const FocusQuality(this.score, this.color, this.label);
  final double score;
  final Color color;
  final String label;
}

class LabelCorner {
  final Offset position;
  final double confidence;

  LabelCorner({required this.position, required this.confidence});
}

/// Main QA System Controller
class CameraQASystem {
  final StreamController<QAAssessment> _assessmentController = StreamController<QAAssessment>.broadcast();
  final DeviceStabilizer _stabilizer = DeviceStabilizer();
  final FocusAnalyzer _focusAnalyzer = FocusAnalyzer();
  final LabelDetector _labelDetector = LabelDetector();
  
  Stream<QAAssessment> get assessmentStream => _assessmentController.stream;
  
  QAProfile _profile = QAProfile.quality; // Default to quality mode
  bool _isActive = false;
  bool _labelDetectionEnabled = false;
  Timer? _assessmentTimer;
  
  /// Set the QA profile (fast for Profile A, quality for Profile B)
  void setProfile(QAProfile profile) {
    _profile = profile;
  }

  void start({bool enableLabelDetection = false}) {
    if (_isActive) return;
    
    _isActive = true;
    _labelDetectionEnabled = false; // Disable label detection - too jittery
    
    _stabilizer.start();
    _focusAnalyzer.start();
    
    // Label detection disabled for now
    // if (_labelDetectionEnabled) {
    //   _labelDetector.start();
    // }
    
    // Profile-specific assessment timing
    // Fast profile (A): Check every 800ms for minimal delay
    // Quality profile (B): Check every 500ms for better feedback
    final assessmentInterval = _profile == QAProfile.fast 
        ? const Duration(milliseconds: 800) 
        : const Duration(milliseconds: 500);
    
    _assessmentTimer = Timer.periodic(assessmentInterval, (_) {
      if (_isActive) {
        _performAssessment();
      }
    });
  }

  void stop() {
    _isActive = false;
    _assessmentTimer?.cancel();
    _stabilizer.stop();
    _focusAnalyzer.stop();
    _labelDetector.stop();
  }

  void updateCameraController(CameraController? controller) {
    _focusAnalyzer.updateController(controller);
  }

  void _performAssessment() {
    final stability = _stabilizer.currentStability;
    final focus = _focusAnalyzer.currentFocusQuality;
    
    // Profile-specific scoring weights
    // Fast profile (A): Focus on focus only (60%), less on stability (40%)
    // Quality profile (B): Balanced between focus (50%) and stability (50%)
    double score;
    if (_profile == QAProfile.fast) {
      score = (focus.score * 0.6) + (stability.score * 0.4);
    } else {
      score = (focus.score * 0.5) + (stability.score * 0.5);
    }
    
    final assessment = QAAssessment(
      stability: stability,
      focusQuality: focus,
      hasDetectedLabels: false, // Disabled
      detectedCorners: [], // Disabled
      overallScore: score,
    );
    
    _assessmentController.add(assessment);
  }

  void dispose() {
    stop();
    _assessmentController.close();
    _stabilizer.dispose();
    _focusAnalyzer.dispose();
    _labelDetector.dispose();
  }
}

/// Device Stabilization Analysis
class DeviceStabilizer {
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  
  final List<double> _recentMovements = [];
  final int _sampleSize = 20; // Larger sample for more stable readings
  StabilityLevel _currentStability = StabilityLevel.fair;
  
  StabilityLevel get currentStability => _currentStability;

  void start() {
    _accelSubscription = accelerometerEventStream().listen(_onAccelerometerEvent);
    _gyroSubscription = gyroscopeEventStream().listen(_onGyroscopeEvent);
  }

  void stop() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    // Calculate movement magnitude
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    
    _recentMovements.add(magnitude);
    if (_recentMovements.length > _sampleSize) {
      _recentMovements.removeAt(0);
    }
    
    _updateStabilityLevel();
  }

  void _onGyroscopeEvent(GyroscopeEvent event) {
    // Add rotational movement to stability calculation
    final rotationMagnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    
    _recentMovements.add(rotationMagnitude * 2); // Weight rotation more heavily
    if (_recentMovements.length > _sampleSize) {
      _recentMovements.removeAt(0);
    }
    
    _updateStabilityLevel();
  }

  void _updateStabilityLevel() {
    if (_recentMovements.length < _sampleSize) return;
    
    // Calculate movement variance (lower = more stable)
    final mean = _recentMovements.reduce((a, b) => a + b) / _recentMovements.length;
    final variance = _recentMovements
        .map((x) => pow(x - mean, 2))
        .reduce((a, b) => a + b) / _recentMovements.length;
    
    // Determine stability level based on variance thresholds
    if (variance < 0.5) {
      _currentStability = StabilityLevel.excellent;
    } else if (variance < 1.0) {
      _currentStability = StabilityLevel.good;
    } else if (variance < 2.0) {
      _currentStability = StabilityLevel.fair;
    } else {
      _currentStability = StabilityLevel.poor;
    }
  }

  void dispose() {
    stop();
  }
}

/// Camera Focus Quality Analysis
class FocusAnalyzer {
  CameraController? _controller;
  FocusQuality _currentFocusQuality = FocusQuality.unknown;
  Timer? _focusCheckTimer;
  
  FocusQuality get currentFocusQuality => _currentFocusQuality;

  void start() {
    // Check focus state every 1 second for stable feedback
    _focusCheckTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      _checkFocusQuality();
    });
  }

  void stop() {
    _focusCheckTimer?.cancel();
  }

  void updateController(CameraController? controller) {
    _controller = controller;
  }

  void _checkFocusQuality() {
    if (_controller == null || !_controller!.value.isInitialized) {
      _currentFocusQuality = FocusQuality.unknown;
      return;
    }

    // In a real implementation, you would analyze the camera preview frames
    // For now, we'll simulate focus quality based on camera state
    
    // Simulate focus quality assessment
    // In practice, this would analyze frame sharpness
    _simulateFocusQuality();
  }

  void _simulateFocusQuality() {
    // This is a placeholder - in production you'd implement actual sharpness analysis
    // For now, we'll assume good focus most of the time with occasional soft focus
    final random = Random();
    final focusValue = random.nextDouble();
    
    if (focusValue > 0.8) {
      _currentFocusQuality = FocusQuality.sharp;
    } else if (focusValue > 0.6) {
      _currentFocusQuality = FocusQuality.good;
    } else if (focusValue > 0.3) {
      _currentFocusQuality = FocusQuality.soft;
    } else {
      _currentFocusQuality = FocusQuality.blurred;
    }
  }

  void dispose() {
    stop();
  }
}

/// Label Corner Detection (Placeholder for future ML implementation)
class LabelDetector {
  List<LabelCorner> _detectedCorners = [];
  Timer? _detectionTimer;
  
  List<LabelCorner> get detectedCorners => _detectedCorners;

  void start() {
    // Run detection every 300ms (less frequent than other checks)
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      _performDetection();
    });
  }

  void stop() {
    _detectionTimer?.cancel();
    _detectedCorners.clear();
  }

  void _performDetection() {
    // Placeholder for actual computer vision label detection
    // In production, this would use ML models or OpenCV to detect rectangular shapes
    
    final random = Random();
    _detectedCorners.clear();
    
    // Simulate occasional label detection
    if (random.nextDouble() > 0.7) {
      // Simulate 1-3 detected label corners
      final numLabels = random.nextInt(3) + 1;
      
      for (int i = 0; i < numLabels; i++) {
        _detectedCorners.add(
          LabelCorner(
            position: Offset(
              random.nextDouble() * 400 + 100, // x between 100-500
              random.nextDouble() * 300 + 200, // y between 200-500
            ),
            confidence: 0.7 + random.nextDouble() * 0.3, // 0.7-1.0
          ),
        );
      }
    }
  }

  void dispose() {
    stop();
  }
}
