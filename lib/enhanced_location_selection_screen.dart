import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/app_models.dart';
import 'core/design_system.dart';
import 'camera_screen.dart';

// Define local constants to avoid const expression errors
class AppColors {
  static const Color primary = Color(0xFF007AFF);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color backgroundGrey = Color(0xFFF2F2F7);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class EnhancedLocationSelectionScreen extends StatefulWidget {
  final String storeId;
  final String storeName;

  const EnhancedLocationSelectionScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<EnhancedLocationSelectionScreen> createState() => _EnhancedLocationSelectionScreenState();
}

class _EnhancedLocationSelectionScreenState extends State<EnhancedLocationSelectionScreen> {
  VisitProgress visitProgress = VisitProgress(
    storeId: '',
    visitId: DateTime.now().millisecondsSinceEpoch.toString(),
  );
  
  InstallationType? selectedInstallationType;
  int? selectedAisleNumber;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    visitProgress = VisitProgress(
      storeId: widget.storeId,
      visitId: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    // Load REAL progress from database/storage instead of mock data
    _loadRealProgress();
  }

  Future<void> _loadRealProgress() async {
    // Load actual visit progress from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressKey = 'visit_progress_${widget.storeId}';
      final progressJson = prefs.getString(progressKey);
      
      if (progressJson != null) {
        final json = jsonDecode(progressJson);
        final loadedProgress = VisitProgress.fromJson(json);
        
        // Check if progress has expired (older than 3 days)
        if (loadedProgress.isExpired) {
          debugPrint('⏰ Progress expired for store ${widget.storeId}, clearing...');
          await prefs.remove(progressKey);
          // Keep default empty progress
        } else {
          setState(() {
            visitProgress = loadedProgress;
          });
          debugPrint('✅ Loaded progress for store ${widget.storeId}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading progress: $e');
      // Keep default empty progress on error
    }
  }

  void _selectInstallationType(InstallationType type) async {
    HapticFeedback.lightImpact();
    setState(() {
      selectedInstallationType = type;
    });
    
    // Brief delay to show selection
    await Future.delayed(const Duration(milliseconds: 200));

    if (type.requiresAisle) {
      _showAisleSelection(type);
    } else {
      _navigateToCamera(type, null);
    }
  }

  void _showAisleSelection(InstallationType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAisleSelectionBottomSheet(type),
    );
  }

  void _selectAisle(InstallationType type, int aisle) async {
    setState(() {
      selectedAisleNumber = aisle;
    });
    
    // Brief delay to show selection
    await Future.delayed(const Duration(milliseconds: 200));
    
    Navigator.pop(context); // Close bottom sheet
    _navigateToCamera(type, aisle);
  }

  void _navigateToCamera(InstallationType type, int? aisle) async {
    // ALL installation types should start with scene capture first
    // Only direct In-Store profile (Profile A) goes straight to labels
    final cameraMode = CameraMode.sceneCapture; // Always start with scene

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          storeId: widget.storeId,
          storeName: widget.storeName,
          installationType: type,
          aisleNumber: aisle,
          cameraMode: cameraMode,
          onCaptureComplete: _onCaptureComplete,
        ),
      ),
    );
    
    // Reload progress when returning from camera
    debugPrint('🔄 Returned from camera, reloading progress...');
    await _loadRealProgress();
  }

  void _onCaptureComplete(InstallationType type, int? aisle) {
    debugPrint('📥 onCaptureComplete called: ${type.displayName} ${aisle != null ? "Aisle $aisle" : "(off location)"}');
    
    setState(() {
      if (type.requiresAisle && aisle != null) {
        visitProgress = visitProgress.markAisleComplete(type, aisle);
        debugPrint('✅ Marked aisle complete in state');
      } else {
        visitProgress = visitProgress.addOffLocationCapture(type);
        debugPrint('✅ Added off location capture in state');
      }
    });
    
    HapticFeedback.mediumImpact();
    
    // Persist progress to SharedPreferences
    _saveProgress();
    
    debugPrint('✅ Capture complete: ${type.displayName} ${aisle != null ? "Aisle $aisle" : "(off location)"}');
  }
  
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressKey = 'visit_progress_${widget.storeId}';
      final json = jsonEncode(visitProgress.toJson());
      await prefs.setString(progressKey, json);
      debugPrint('💾 Progress saved for store ${widget.storeId}');
    } catch (e) {
      debugPrint('❌ Error saving progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          'Select Installation Type',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStoreHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAisleInstallationsSection(),
                  const SizedBox(height: 24),
                  _buildOffLocationsSection(),
                  const SizedBox(height: 32),
                  _buildProgressSummary(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Icon(
                Icons.store,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.storeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Store ID: ${widget.storeId}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAisleInstallationsSection() {
    final aisleTypes = InstallationType.values.where((type) => type.requiresAisle).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🛒 AISLE INSTALLATIONS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: aisleTypes.length,
          itemBuilder: (context, index) {
            final type = aisleTypes[index];
            return _buildInstallationTypeCard(type, true);
          },
        ),
      ],
    );
  }

  Widget _buildOffLocationsSection() {
    final offLocationTypes = InstallationType.values.where((type) => !type.requiresAisle).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏪 OFF LOCATIONS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.grey[700],
          ),
        ),
        Text(
          'Multiple captures allowed',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: offLocationTypes.length,
          itemBuilder: (context, index) {
            final type = offLocationTypes[index];
            return _buildInstallationTypeCard(type, false);
          },
        ),
      ],
    );
  }

  Widget _buildInstallationTypeCard(InstallationType type, bool isAisleType) {
    final completionCount = visitProgress.getCompletionCount(type);
    final maxCount = isAisleType ? 20 : null;
    final isSelected = selectedInstallationType == type;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _selectInstallationType(type),
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.success.withOpacity(0.3),
        highlightColor: AppColors.success.withOpacity(0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? AppColors.success.withOpacity(0.15) : Colors.transparent,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getInstallationIcon(type),
                size: 32,
                color: _getInstallationColor(type, completionCount),
              ),
              const SizedBox(height: 4),
              Text(
                type.displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              _buildProgressIndicator(type, completionCount, maxCount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(InstallationType type, int completionCount, int? maxCount) {
    if (type.requiresAisle) {
      // Show X/20 format for aisle installations
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getProgressBackgroundColor(completionCount, maxCount!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$completionCount/$maxCount done',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _getProgressTextColor(completionCount, maxCount),
          ),
        ),
      );
    } else {
      // Show capture count for off locations
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: completionCount > 0 ? AppColors.success.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '📸 $completionCount captures',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: completionCount > 0 ? AppColors.success : Colors.grey[600],
          ),
        ),
      );
    }
  }

  Color _getInstallationColor(InstallationType type, int completionCount) {
    if (completionCount == 0) return Colors.grey[400]!;
    if (type.requiresAisle) {
      if (completionCount >= 20) return AppColors.success;
      return AppColors.warning;
    }
    return AppColors.success;
  }

  Color _getProgressBackgroundColor(int current, int max) {
    if (current == 0) return Colors.grey[100]!;
    if (current >= max) return AppColors.success.withOpacity(0.1);
    return AppColors.warning.withOpacity(0.1);
  }

  Color _getProgressTextColor(int current, int max) {
    if (current == 0) return Colors.grey[600]!;
    if (current >= max) return AppColors.success;
    return AppColors.warning;
  }

  IconData _getInstallationIcon(InstallationType type) {
    switch (type) {
      case InstallationType.end:
        return Icons.view_column;
      case InstallationType.front:
        return Icons.arrow_upward;
      case InstallationType.frontLeftWing:
        return Icons.arrow_back;
      case InstallationType.frontRightWing:
        return Icons.arrow_forward;
      case InstallationType.back:
        return Icons.arrow_downward;
      case InstallationType.backLeftWing:
        return Icons.south_west;
      case InstallationType.backRightWing:
        return Icons.south_east;
      case InstallationType.freezer:
        return Icons.ac_unit;
      case InstallationType.deli:
        return Icons.lunch_dining; // Ham/sandwich icon
      case InstallationType.entrance:
        return Icons.login;
      case InstallationType.pos:
        return Icons.point_of_sale;
    }
  }

  Widget _buildAisleSelectionBottomSheet(InstallationType type) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(_getInstallationIcon(type), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${type.displayName} - Select Aisle',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select an available aisle number (1-20)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Aisle grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 20,
                itemBuilder: (context, index) {
                  final aisleNumber = index + 1;
                  final isCompleted = visitProgress.isAisleInstallationComplete(type, aisleNumber);
                  
                  return _buildAisleNumberButton(type, aisleNumber, isCompleted);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAisleNumberButton(InstallationType type, int aisleNumber, bool isCompleted) {
    final isSelected = selectedAisleNumber == aisleNumber;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected && !isCompleted 
            ? AppColors.success.withOpacity(0.3) 
            : isCompleted 
                ? AppColors.success 
                : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted ? AppColors.success : Colors.grey[300]!,
          width: isSelected && !isCompleted ? 2 : 1,
        ),
        boxShadow: isCompleted ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCompleted ? null : () => _selectAisle(type, aisleNumber),
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: isCompleted
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                      Text(
                        '$aisleNumber',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Text(
                    '$aisleNumber',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.success : Colors.black,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSummary() {
    final totalAisleInstallations = InstallationType.values
        .where((type) => type.requiresAisle)
        .map((type) => visitProgress.getCompletionCount(type))
        .fold(0, (sum, count) => sum + count);
    
    final totalOffLocationCaptures = InstallationType.values
        .where((type) => !type.requiresAisle)
        .map((type) => visitProgress.getCompletionCount(type))
        .fold(0, (sum, count) => sum + count);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Session Progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalAisleInstallations',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text('Aisle Installations'),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$totalOffLocationCaptures',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    const Text('Off Location Captures'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
