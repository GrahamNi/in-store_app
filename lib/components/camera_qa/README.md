# Camera QA System Documentation

## Overview

The Camera QA (Quality Assurance) system provides real-time feedback to operators to help capture high-quality images without hindering their workflow. The system is **non-intrusive** and **assistive** rather than restrictive.

## QA Features Implemented

### 1. 📱 Device Stabilization
- **Real-time tilt/shake detection** using accelerometer and gyroscope
- **Visual indicator** (top-left): Green = Excellent, Yellow = Fair, Red = Poor
- **Subtle haptic feedback** when device becomes stable
- **Threshold-based assessment** with smooth transitions

### 2. 🎯 Focus Quality Detection
- **Focus confidence indicator** (top-right circle)
- **Color-coded feedback**: Green = Sharp, Orange = Soft, Red = Blurred
- **Camera focus state monitoring** with automatic assessment
- **Non-blocking** - operator can capture anytime

### 3. 🏷️ Label Corner Detection
- **Active only in Label Capture mode** (not Scene mode)
- **Highlighted rectangular overlays** for detected labels
- **Confidence percentage** displayed for each detection
- **Corner markers** showing label boundaries

### 4. 📊 QA Overlay System
- **Contextual hints** appear only when quality is poor
- **Auto-hiding overlays** that don't obstruct the interface
- **Smooth animations** with minimal visual distraction
- **Smart positioning** to avoid UI conflicts

### 5. 💫 Enhanced Capture Experience
- **Quality ring** around capture button showing overall assessment
- **Progressive color coding**: Green (excellent) → Orange (fair) → Red (poor)
- **Enhanced haptic feedback** based on image quality
- **QA logging** for debugging and analysis

## Visual Indicators

### Stability Indicator (Top Left)
```
🟢 Excellent - Device very stable
🟡 Good     - Minor movement detected  
🟠 Fair     - Moderate shake
🔴 Poor     - Significant movement
```

### Focus Indicator (Top Right)
```
🟢 Sharp   - Perfect focus achieved
🟡 Good    - Acceptable focus quality
🟠 Soft    - Slightly out of focus
🔴 Blurred - Poor focus quality
⚪ Unknown - Camera focusing
```

### Quality Hints (Bottom Center - Only When Needed)
- "Hold device steady for better quality"
- "Tap to focus on label"  
- "Position label in frame"

## Operator Experience

### What Operators See:
1. **Discrete indicators** that don't block the camera view
2. **Helpful hints** only when quality could be improved
3. **Smooth animations** that provide feedback without distraction
4. **Enhanced capture button** with quality visualization

### What Operators Feel:
1. **Light vibration** when excellent quality is achieved
2. **Medium vibration** for good quality captures
3. **Selection click** for poor quality (gentle warning)
4. **No blocking** - can always capture regardless of quality

## Technical Implementation

### System Architecture
```
CameraQASystem
├── DeviceStabilizer (Sensors)
├── FocusAnalyzer (Camera State)
├── LabelDetector (Computer Vision)
└── QAAssessment (Overall Score)
```

### Performance Optimizations
- **10 FPS assessment rate** for smooth feedback
- **Sensor throttling** to preserve battery
- **Smart activation** - label detection only in label mode
- **Memory efficient** with automatic cleanup

### Integration Points
- **Camera Screen**: Seamless overlay integration
- **Capture Button**: Enhanced with quality ring
- **Mode Switching**: Automatic QA reconfiguration
- **Haptic System**: Quality-based feedback

## Configuration Options

### Stability Thresholds
- Excellent: < 0.5 variance
- Good: < 1.0 variance  
- Fair: < 2.0 variance
- Poor: ≥ 2.0 variance

### Quality Scoring
- Overall Score = (Stability × 40%) + (Focus × 40%) + (Label Detection × 20%)
- Excellent: ≥ 90%
- Good: ≥ 70%
- Poor: < 60%

## Testing the QA System

### Manual Testing Steps

1. **Stability Test**
   - Launch camera
   - Move device around while watching top-left indicator
   - Verify color changes based on movement

2. **Focus Test**  
   - Tap to focus on different objects
   - Watch top-right circle color changes
   - Verify focus confidence feedback

3. **Label Mode Test**
   - Switch to Labels mode (Profile B workflow)
   - Point at rectangular objects
   - Look for label corner detection overlays

4. **Quality Ring Test**
   - Watch capture button for colored ring
   - Note ring color changes with overall quality
   - Test capture with different quality levels

5. **Haptic Test**
   - Feel for different vibration patterns
   - Excellent quality = medium impact
   - Good quality = light impact
   - Poor quality = selection click

### Expected Behaviors

#### Scene Mode (Profile B)
- ✅ Stability and focus indicators active
- ❌ Label detection disabled
- ✅ Quality hints for stability/focus only

#### Label Mode (Profile A & B)
- ✅ All QA features active
- ✅ Label corner detection enabled
- ✅ Full quality assessment

## Troubleshooting

### Common Issues

**QA indicators not showing:**
- Check camera permission granted
- Verify sensors_plus dependency
- Ensure QA system started after camera init

**Poor stability detection:**
- Check device sensor calibration
- Verify threshold settings appropriate
- Test on different devices

**Focus quality always "Unknown":**
- Camera controller not properly connected
- Focus simulation may need real implementation
- Check camera initialization sequence

**Label detection not working:**
- Only active in label capture mode
- Currently uses simulation data
- ML model integration pending

## Future Enhancements

### Phase 2 Improvements
1. **Real ML Integration** - Replace simulated label detection
2. **Adaptive Thresholds** - Learn from user patterns
3. **Advanced Focus Analysis** - Frame sharpness calculation
4. **Light Condition Assessment** - Exposure optimization
5. **Custom QA Profiles** - Per-store configuration

### Performance Optimizations
1. **Background Processing** - Move analysis off UI thread
2. **Smart Sampling** - Reduce sensor polling when stable
3. **ML Model Optimization** - Edge-optimized inference
4. **Battery Management** - Intelligent power usage

## API Reference

### Core Classes

#### `CameraQASystem`
Main controller for the QA system.

```dart
final qaSystem = CameraQASystem();

// Start with label detection
qaSystem.start(enableLabelDetection: true);

// Listen to assessments
qaSystem.assessmentStream.listen((assessment) {
  // Handle QA updates
});

// Update camera reference
qaSystem.updateCameraController(controller);

// Stop and cleanup
qaSystem.stop();
qaSystem.dispose();
```

#### `QAAssessment`
Contains all quality metrics for current frame.

```dart
class QAAssessment {
  final StabilityLevel stability;     // Device movement
  final FocusQuality focusQuality;   // Camera focus
  final bool hasDetectedLabels;      // Label detection
  final double overallScore;         // 0.0 - 1.0
  
  bool get isGoodQuality;           // >= 70%
  bool get isExcellentQuality;      // >= 90%
}
```

#### `CameraQAOverlay`
Visual overlay widget for camera screen.

```dart
CameraQAOverlay(
  assessment: currentAssessment,
  isLabelMode: cameraMode == CameraMode.labelCapture,
  screenSize: MediaQuery.of(context).size,
)
```

This QA system provides professional-grade assistance while maintaining the fast, efficient workflow your operators need.
