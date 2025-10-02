import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/app_models.dart';
import 'components/camera_qa/camera_qa.dart';
import 'core/upload_queue/upload_queue.dart';
import 'core/upload_queue_initializer.dart';
import 'visit_summary_screen.dart';

// Professional color scheme
class CameraColors {
  static const Color primary = Color(0xFF1E1E5C); // Professional blue
  static const Color success = Color(0xFF27AE60); // Professional green
  static const Color warning = Color(0xFFFF9500); // Standout yellow/orange
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color overlay = Color(0x80000000);
}

class CameraScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final String? area;
  final String? aisle;
  final String? segment;
  final CameraMode cameraMode;
  final InstallationType? installationType;
  final int? aisleNumber;
  final Function(InstallationType, int?)? onCaptureComplete;

  const CameraScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    this.area,
    this.aisle,
    this.segment,
    required this.cameraMode,
    this.installationType,
    this.aisleNumber,
    this.onCaptureComplete,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver {  // 🔋 ADDED: WidgetsBindingObserver
  CameraController? _controller;
  bool _isInitialized = false;
  String _status = 'Initializing camera...';
  int _photoCount = 0;
  bool _isDisposed = false;
  bool _isCapturing = false;
  bool _hasSceneCapture = false;
  CameraMode _currentMode = CameraMode.sceneCapture;
  bool _isAppInBackground = false;  // 🔋 ADDED: Track app lifecycle
  
  late AnimationController _captureButtonController;
  late AnimationController _flashController;
  
  // QA System
  late CameraQASystem _qaSystem;
  QAAssessment? _currentQA;
  QAAssessment? _previousQA;
  StreamSubscription<QAAssessment>? _qaSubscription;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);  // 🔋 ADDED: Listen to lifecycle events
    _currentMode = widget.cameraMode;
    _initializeAnimations();
    _initializeQASystem();
    _initializeCamera();
    _updateUploadQueueLocation();
  }

  // 🔋 ADDED: Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App went to background - pause everything to save battery
        debugPrint('🔋 App backgrounded - pausing camera and QA system');
        _isAppInBackground = true;
        _stopQASystem();
        _controller?.pausePreview();
        break;
        
      case AppLifecycleState.resumed:
        // App came back to foreground - resume
        debugPrint('🔋 App resumed - restarting camera and QA system');
        _isAppInBackground = false;
        _controller?.resumePreview();
        _startQASystem();
        break;
        
      case AppLifecycleState.detached:
        // App is being terminated
        break;
    }
  }

  void _updateUploadQueueLocation() {
    // Update the visit session with current location
    UploadQueueInitializer.updateLocation(
      area: widget.area,
      aisle: widget.aisle,
      segment: widget.segment,
      installationType: widget.installationType,
      aisleNumber: widget.aisleNumber,
    );
  }

  void _initializeAnimations() {
    _captureButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  void _initializeQASystem() {
    _qaSystem = CameraQASystem();
    
    // Determine QA profile based on workflow
    // Profile A (fast): No installationType = direct capture workflow
    // Profile B (quality): Has installationType = location selection workflow
    final qaProfile = widget.installationType == null 
        ? QAProfile.fast    // Profile A - up to 2000 images, fast capture
        : QAProfile.quality; // Profile B - smaller fonts, more time
    
    _qaSystem.setProfile(qaProfile);
    
    debugPrint('🎯 QA Profile set to: ${qaProfile == QAProfile.fast ? "FAST (Profile A)" : "QUALITY (Profile B)"}');
    
    _qaSubscription = _qaSystem.assessmentStream.listen((assessment) {
      if (!mounted || _isDisposed || _isAppInBackground) return;  // 🔋 ADDED: Don't update UI if backgrounded
      
      setState(() {
        _previousQA = _currentQA;
        _currentQA = assessment;
      });
      
      // Provide haptic feedback for quality changes (only if app is active)
      if (!_isAppInBackground) {  // 🔋 ADDED: No haptics in background
        QAHapticManager.onQualityChange(assessment, _previousQA);
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      if (_isDisposed) return;
      
      final permission = await Permission.camera.request();
      
      if (_isDisposed || !mounted) return;
      
      if (permission != PermissionStatus.granted) {
        setState(() {
          _status = 'Camera permission required';
        });
        return;
      }

      final cameras = await availableCameras();
      
      if (_isDisposed || !mounted) return;
      
      if (cameras.isEmpty) {
        setState(() {
          _status = 'No camera found';
        });
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,  // Good balance for battery
        enableAudio: false,      // Save battery by not processing audio
        imageFormatGroup: ImageFormatGroup.jpeg,  // 🔋 ADDED: Use JPEG for efficiency
      );

      await _controller!.initialize();
      
      if (_isDisposed || !mounted) return;

      // 🔋 ADDED: Set optimal camera settings for battery life
      try {
        await _controller!.setFocusMode(FocusMode.auto);
        // Lock exposure after initial auto-exposure for battery savings
        await _controller!.setExposureMode(ExposureMode.auto);
      } catch (e) {
        debugPrint('⚠️ Could not set camera modes: $e');
      }

      setState(() {
        _isInitialized = true;
        _status = 'Camera ready';
      });

      // Start QA system after camera is ready
      _qaSystem.updateCameraController(_controller);
      _startQASystem();

    } catch (e) {
      if (_isDisposed || !mounted) return;
      setState(() {
        _status = 'Camera error';
      });
      debugPrint('Camera initialization error: $e');
    }
  }

  void _startQASystem() {
    if (!_isInitialized || _isAppInBackground) return;  // 🔋 ADDED: Don't start if backgrounded
    
    final enableLabelDetection = _currentMode == CameraMode.labelCapture;
    _qaSystem.start(enableLabelDetection: enableLabelDetection);
  }

  void _stopQASystem() {
    _qaSystem.stop();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isDisposed || _isCapturing) {
      return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });

      await _captureButtonController.forward();
      
      _flashController.forward().then((_) {
        _flashController.reverse();
      });

      // Enhanced haptic feedback based on quality
      if (_currentQA != null && _currentQA!.isExcellentQuality) {
        HapticFeedback.mediumImpact();
      } else if (_currentQA != null && _currentQA!.isGoodQuality) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.selectionClick();
      }

      final image = await _controller!.takePicture();
      
      if (_isDisposed || !mounted) return;

      // Process the captured image through the upload queue
      await _processCapture(image);
      
      setState(() {
        _photoCount++;
        _isCapturing = false;
        
        if (_currentMode == CameraMode.sceneCapture) {
          _hasSceneCapture = true;
        }
      });

      _captureButtonController.reverse();

      debugPrint('Photo uploaded to queue successfully');
      
      // Log QA info for this capture
      if (_currentQA != null) {
        debugPrint('Capture QA - Overall: ${(_currentQA!.overallScore * 100).toInt()}%, '
                   'Stability: ${_currentQA!.stability.label}, '
                   'Focus: ${_currentQA!.focusQuality.label}');
      }
      
      // Clean up original image file
      try {
        await File(image.path).delete();
      } catch (e) {
        debugPrint('Failed to delete original image: $e');
      }
      
    } catch (e) {
      if (_isDisposed || !mounted) return;
      setState(() {
        _isCapturing = false;
      });
      _captureButtonController.reverse();
      debugPrint('Capture error: $e');
      
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to capture image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processCapture(XFile image) async {
    // Determine capture type based on mode
    final captureType = _currentMode;

    // Get current context from visit session
    final context = VisitSessionManager.instance.currentContext;
    if (context == null) {
      throw Exception('No active visit session');
    }

    // Add to upload queue using the processor
    await CaptureProcessor.processCapture(
      originalImagePath: image.path,
      captureType: captureType,
      context: CaptureContext(
        operatorId: context.operatorId,
        operatorName: context.operatorName,
        sessionId: context.sessionId,
        visitId: context.visitId,
        storeId: context.storeId,
        storeName: context.storeName,
        area: widget.area,
        aisle: widget.aisle,
        segment: widget.segment,
        installationType: widget.installationType,
        aisleNumber: widget.aisleNumber,
      ),
      wasAutoCapture: false,
      qualityDetails: _currentQA != null ? {
        'overallScore': _currentQA!.overallScore,
        'stability': _currentQA!.stability.name,
        'focusQuality': _currentQA!.focusQuality.name,
      } : null,
    );

    debugPrint('Image processed and added to upload queue');
  }

  void _retakePhoto() {
    setState(() {
      if (_currentMode == CameraMode.sceneCapture) {
        _hasSceneCapture = false;
        _photoCount = 0;
      }
    });
    HapticFeedback.lightImpact();
    debugPrint('Retaking photo - previous image should be deleted');
  }

  void _switchToLabels() {
    setState(() {
      _currentMode = CameraMode.labelCapture;
    });
    
    // Restart QA system with label detection enabled
    _stopQASystem();
    _startQASystem();
    
    HapticFeedback.lightImpact();
  }

  void _nextLocation() {
    // Call completion callback BEFORE navigating away
    if (widget.onCaptureComplete != null && 
        widget.installationType != null && 
        _photoCount > 0) { // Only if photos were taken
      debugPrint('📊 Calling onCaptureComplete before navigation');
      widget.onCaptureComplete!(widget.installationType!, widget.aisleNumber);
    }
    
    // Navigate back to location selection
    Navigator.pop(context);
  }

  void _endVisit() async {
    // Get session context to pass to summary screen
    final context = VisitSessionManager.instance.currentContext;
    if (context == null) {
      debugPrint('❌ No session context available');
      Navigator.popUntil(this.context, (route) => route.isFirst);
      return;
    }

    // TODO: Get actual counts from database/session manager
    // For now, using placeholder values
    final locationCount = 1; // This should come from session data
    final imageCount = _photoCount; // Use current photo count

    // TODO: Get user profile - for now create a basic one
    final userProfile = UserProfile(
      name: context.operatorName,
      email: '', // Not available in context
      userType: widget.installationType != null ? UserType.inStorePromo : UserType.inStore,
      clientLogo: ClientLogo.rdas, // Default
    );

    debugPrint('🏁 Navigating to visit summary: locations=$locationCount, images=$imageCount');

    // Navigate to visit summary screen
    Navigator.push(
      this.context,
      MaterialPageRoute(
        builder: (buildContext) => VisitSummaryScreen(
          storeId: widget.storeId,
          storeName: widget.storeName,
          userProfile: userProfile,
          locationCount: locationCount,
          imageCount: imageCount,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);  // 🔋 ADDED: Remove lifecycle observer
    _stopQASystem();
    _qaSubscription?.cancel();
    _qaSystem.dispose();
    _controller?.dispose();
    _captureButtonController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔋 ADDED: Show "paused" overlay when app is backgrounded
    if (_isAppInBackground) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Camera Paused',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen camera preview
          if (_isInitialized && _controller != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize?.height ?? 1,
                  height: _controller!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_controller!),
                ),
              ),
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),

          // QA Overlay System
          if (_isInitialized && _currentQA != null)
            CameraQAOverlay(
              assessment: _currentQA!,
              isLabelMode: _currentMode == CameraMode.labelCapture,
              screenSize: MediaQuery.of(context).size,
            ),

          // Flash overlay
          AnimatedBuilder(
            animation: _flashController,
            builder: (context, child) {
              return _flashController.value > 0
                  ? Positioned.fill(
                      child: Container(
                        color: Colors.white.withOpacity(_flashController.value * 0.8),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),

          // Top overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20,
                right: 20,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTopButton(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(context),
                  ),
                  
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _currentMode == CameraMode.sceneCapture
                              ? CameraColors.primary.withOpacity(0.9)
                              : Colors.orange.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          _currentMode == CameraMode.sceneCapture ? 'SCENE' : 'LABELS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      if (_photoCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_photoCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  _buildTopButton(
                    icon: Icons.settings,
                    onTap: () => openAppSettings(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
                top: 40,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: _buildBottomControls(),
            ),
          ),

          // Status bar - only show if not ready
          if (!_isInitialized)
            Positioned(
              left: 20,
              right: 20,
              top: 120,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Upload queue status indicator (shows when processing)
          StreamBuilder<String>(
            stream: UploadQueueManager.instance.statusStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Positioned(
                left: 20,
                right: 20,
                top: _isInitialized ? 120 : 170,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: CameraColors.success.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_upload,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          snapshot.data!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final isInStorePromo = widget.installationType != null;
    
    if (_currentMode == CameraMode.sceneCapture && isInStorePromo) {
      // In-Store Promo Scene mode: Retake, Capture, Go to Labels
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Retake button (only if scene captured)
          if (_hasSceneCapture)
            _buildProfessionalButton(
              icon: Icons.refresh,
              label: 'Retake',
              onTap: _retakePhoto,
              color: CameraColors.primary,
            )
          else
            const SizedBox(width: 90),
          
          _buildCaptureButton(),
          
          // Go to Labels button (only actionable after scene capture)
          _buildProfessionalButton(
            icon: Icons.arrow_forward,
            label: 'Labels',
            onTap: _hasSceneCapture ? _switchToLabels : null,
            color: _hasSceneCapture ? CameraColors.warning : null, // Standout yellow when enabled
          ),
        ],
      );
    } else if (_currentMode == CameraMode.labelCapture && isInStorePromo) {
      // In-Store Promo Label mode: End Visit, Capture, Next Location (swapped for natural UX)
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfessionalButton(
            icon: Icons.check_circle,
            label: 'End Visit',
            onTap: _endVisit,
            color: CameraColors.success,
          ),
          
          _buildCaptureButton(),
          
          _buildProfessionalButton(
            icon: Icons.location_on,
            label: 'Next Location',
            onTap: _nextLocation,
            color: CameraColors.primary,
          ),
        ],
      );
    } else {
      // Direct In-Store Label mode (Profile A): Just capture and end
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 90),
          
          _buildCaptureButton(),
          
          _buildProfessionalButton(
            icon: Icons.check_circle,
            label: 'End Visit',
            onTap: _endVisit,
            color: CameraColors.success,
          ),
        ],
      );
    }
  }

  Widget _buildTopButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildProfessionalButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? color,
  }) {
    final isEnabled = onTap != null;
    final buttonColor = color ?? CameraColors.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 56,
        decoration: BoxDecoration(
          color: isEnabled ? buttonColor : Colors.grey.shade600,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: isEnabled ? [
            BoxShadow(
              color: buttonColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTapDown: (_) => _captureButtonController.forward(),
      onTapUp: (_) => _takePicture(),
      onTapCancel: () => _captureButtonController.reverse(),
      child: AnimatedBuilder(
        animation: _captureButtonController,
        builder: (context, child) {
          final scale = 1.0 - (_captureButtonController.value * 0.1);
          return Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // QA Quality Ring (only show when QA is active and decent quality)
                if (_currentQA != null && _currentQA!.overallScore > 0.3)
                  CaptureButtonQAIndicator(
                    assessment: _currentQA!,
                    size: 80,
                  ),
                
                // Main capture button
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _isCapturing
                      ? Container(
                          padding: const EdgeInsets.all(22),
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isInitialized ? Colors.black : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
