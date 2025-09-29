import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'camera_screen.dart';
import 'models/app_models.dart';

class QATestScreen extends StatelessWidget {
  const QATestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QA System Test'),
        backgroundColor: const Color(0xFF1E1E5C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test QA Features',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'QA Features Implemented:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            
            _buildFeatureItem('✅ Device Stabilization', 'Real-time tilt/shake detection'),
            _buildFeatureItem('✅ Focus Quality', 'Camera focus confidence indicators'),
            _buildFeatureItem('✅ QA Overlay System', 'Visual feedback framework'),
            _buildFeatureItem('✅ Label Corner Detection', 'Active only in label capture mode'),
            _buildFeatureItem('✅ Haptic Feedback', 'Quality-based vibration'),
            _buildFeatureItem('✅ Capture Button Enhancement', 'Quality ring indicator'),
            
            const SizedBox(height: 30),
            
            const Text(
              'Test Instructions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            
            _buildInstructionItem('1. Stability Test', 'Move device while camera is active - watch top-left indicator'),
            _buildInstructionItem('2. Focus Test', 'Tap to focus - observe top-right circle changing color'),
            _buildInstructionItem('3. Label Mode', 'Switch to Labels mode to see corner detection'),
            _buildInstructionItem('4. Quality Ring', 'Watch capture button for quality arc animation'),
            _buildInstructionItem('5. Haptic Feedback', 'Feel different vibrations based on image quality'),
            
            const Spacer(),
            
            ElevatedButton(
              onPressed: () => _testSceneMode(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E5C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Test Scene Mode QA', style: TextStyle(fontSize: 16)),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: () => _testLabelMode(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9500),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Test Label Mode QA', style: TextStyle(fontSize: 16)),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(description, style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String step, String instruction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E5C),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                    text: step,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: ': '),
                  TextSpan(text: instruction),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _testSceneMode(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(
          storeId: 'test_001',
          storeName: 'QA Test Store',
          cameraMode: CameraMode.sceneCapture,
          installationType: InstallationType.end,
          aisleNumber: 1,
        ),
      ),
    );
  }

  void _testLabelMode(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(
          storeId: 'test_002',
          storeName: 'QA Test Store',
          cameraMode: CameraMode.labelCapture,
        ),
      ),
    );
  }
}
