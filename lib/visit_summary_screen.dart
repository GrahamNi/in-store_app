import 'package:flutter/material.dart';
import 'models/app_models.dart';
import 'core/upload_queue/upload_queue.dart';

class VisitSummaryScreen extends StatelessWidget {
  final String storeId;
  final String storeName;
  final UserProfile userProfile;
  final int locationCount;
  final int imageCount;

  const VisitSummaryScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.userProfile,
    required this.locationCount,
    required this.imageCount,
  });

  bool get _isPromoMode => userProfile.userType == UserType.inStorePromo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Visit Summary'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1E5C),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header message based on mode
                    _buildHeaderMessage(context),
                    const SizedBox(height: 32),
                    
                    // Single summary card with all info
                    _buildSummaryCard(context),
                  ],
                ),
              ),
            ),
            
            // Action buttons at bottom (outside scroll view for safety)
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: _buildActionButtons(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderMessage(BuildContext context) {
    if (_isPromoMode) {
      // In-Store Promo (B) mode
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are You Complete?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 22.4, // 20% smaller than ~28
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1E5C),
                ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Review your visit summary and confirm when you\'re ready to finish.',
            style: TextStyle(
              fontSize: 12.8, // 20% smaller than 16
              color: Color(0xFF1A1E5C),
              height: 1.5,
            ),
          ),
        ],
      );
    } else {
      // In-Store (A) mode
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visit Summary',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 22.4, // 20% smaller than ~28
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1E5C),
                ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Do you wish to complete this visit or pause and return later?',
            style: TextStyle(
              fontSize: 12.8, // 20% smaller than 16
              color: Color(0xFF1A1E5C),
              height: 1.5,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store name (large and prominent)
          Text(
            storeName,
            style: const TextStyle(
              fontSize: 17.6, // 20% smaller than 22
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1E5C),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Divider
          Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
          
          const SizedBox(height: 24),
          
          // Stats row
          Row(
            children: [
              // Ends captured
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ends',
                      style: TextStyle(
                        fontSize: 11.2, // 20% smaller than 14
                        color: Color(0xFF1A1E5C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      locationCount.toString(),
                      style: const TextStyle(
                        fontSize: 25.6, // 20% smaller than 32
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1E5C),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Vertical divider
              Container(
                width: 1,
                height: 50,
                color: Colors.grey.shade300,
              ),
              
              const SizedBox(width: 24),
              
              // Images captured
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Images',
                      style: TextStyle(
                        fontSize: 11.2, // 20% smaller than 14
                        color: Color(0xFF1A1E5C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      imageCount.toString(),
                      style: const TextStyle(
                        fontSize: 25.6, // 20% smaller than 32
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1E5C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (_isPromoMode) {
      // In-Store Promo (B) mode: Single "Confirm and Exit" button
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _completeVisit(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Confirm and Exit',
                style: TextStyle(
                  fontSize: 14.4, // 20% smaller than 18
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Go Back',
              style: TextStyle(
                fontSize: 12.8, // 20% smaller than 16
                color: Color(0xFF1A1E5C),
              ),
            ),
          ),
        ],
      );
    } else {
      // In-Store (A) mode: "Complete Visit" and "Pause and Return" buttons
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _completeVisit(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Complete Visit',
                style: TextStyle(
                  fontSize: 14.4, // 20% smaller than 18
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _pauseVisit(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                side: const BorderSide(color: Color(0xFF1A1E5C), width: 2),
                foregroundColor: const Color(0xFF1A1E5C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Pause and Return Later',
                style: TextStyle(
                  fontSize: 14.4, // 20% smaller than 18
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  void _completeVisit(BuildContext context) {
    // End the visit session using the correct method name
    final visitContext = VisitSessionManager.instance.currentContext;
    if (visitContext != null) {
      VisitSessionManager.instance.endVisit();
      debugPrint('✅ Visit completed for store: $storeName');
    }

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Visit completed successfully'),
        backgroundColor: Color(0xFF27AE60),
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate back to home/store selection (first route)
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _pauseVisit(BuildContext context) {
    // Keep visit session active (don't call endVisit)
    final visitContext = VisitSessionManager.instance.currentContext;
    if (visitContext != null) {
      // TODO: Mark session as paused in database
      // For now, just keep the session active
      debugPrint('⏸️ Visit paused for store: $storeName - Session remains active');
    }

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Visit paused - You can continue from the home page'),
        backgroundColor: Color(0xFF1A1E5C),
        duration: Duration(seconds: 3),
      ),
    );

    // Navigate back to home page but keep session active
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
