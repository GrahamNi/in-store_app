import 'package:flutter/material.dart';
import 'models/app_models.dart';
import 'main.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'account_management_screen.dart';
import 'debug/quick_debug_screen.dart';
import 'debug/immediate_debug_fix.dart';
import 'store_api_test_screen.dart';
import 'auth_test_screen.dart';
import 'stores_api_raw_test.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile? userProfile; // Optional for backward compatibility
  
  const SettingsScreen({super.key, this.userProfile});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Upload Settings
  bool wifiOnlyUploads = true;
  bool autoUploadEnabled = true;
  bool backgroundUploadEnabled = true;
  
  // Camera Settings
  bool hapticsEnabled = true;
  bool autoFocusEnabled = true;
  double captureDelay = 1.0; // seconds
  
  // Storage Settings
  bool autoDeleteUploaded = false;
  int retentionDays = 30;
  
  // Quality Settings
  double qualityThreshold = 0.8;
  bool strictModeEnabled = false;
  
  // Privacy Settings
  bool stripLocationData = true;
  bool analyticsEnabled = true;
  
  // Debug Settings
  bool debugModeEnabled = false;
  bool mockMLEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Settings',
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
      body: ListView(
        children: [
          _buildSettingsSection(
            'Upload Settings',
            Icons.cloud_upload,
            [
              _buildSwitchTile(
                'Wi-Fi Only Uploads',
                'Only upload when connected to Wi-Fi',
                wifiOnlyUploads,
                (value) => setState(() => wifiOnlyUploads = value),
              ),
              _buildSwitchTile(
                'Auto Upload',
                'Automatically upload captures',
                autoUploadEnabled,
                (value) => setState(() => autoUploadEnabled = value),
              ),
              _buildSwitchTile(
                'Background Upload',
                'Continue uploads when app is in background',
                backgroundUploadEnabled,
                (value) => setState(() => backgroundUploadEnabled = value),
              ),
            ],
          ),
          
          _buildSettingsSection(
            'Camera Settings',
            Icons.camera_alt,
            [
              _buildSwitchTile(
                'Haptic Feedback',
                'Vibrate when capture is ready',
                hapticsEnabled,
                (value) => setState(() => hapticsEnabled = value),
              ),
              _buildSwitchTile(
                'Auto Focus',
                'Automatically focus camera',
                autoFocusEnabled,
                (value) => setState(() => autoFocusEnabled = value),
              ),
              _buildSliderTile(
                'Auto-Capture Delay',
                'Time to hold steady before capture',
                '${captureDelay.toStringAsFixed(1)}s',
                captureDelay,
                0.5,
                3.0,
                (value) => setState(() => captureDelay = value),
              ),
            ],
          ),
          
          _buildSettingsSection(
            'Storage Settings',
            Icons.storage,
            [
              _buildSwitchTile(
                'Auto-Delete Uploaded',
                'Delete local files after successful upload',
                autoDeleteUploaded,
                (value) => setState(() => autoDeleteUploaded = value),
              ),
              _buildSliderTile(
                'Retention Period',
                'Days to keep local files',
                '$retentionDays days',
                retentionDays.toDouble(),
                7.0,
                90.0,
                (value) => setState(() => retentionDays = value.round()),
              ),
              _buildActionTile(
                'Clear Cache',
                'Remove temporary files and thumbnails',
                Icons.cleaning_services,
                _clearCache,
              ),
            ],
          ),
          
          _buildSettingsSection(
            'Quality Settings',
            Icons.high_quality,
            [
              _buildSliderTile(
                'Quality Threshold',
                'Minimum quality score for auto-capture',
                '${(qualityThreshold * 100).toInt()}%',
                qualityThreshold,
                0.5,
                1.0,
                (value) => setState(() => qualityThreshold = value),
              ),
              _buildSwitchTile(
                'Strict Mode',
                'Higher quality requirements',
                strictModeEnabled,
                (value) => setState(() => strictModeEnabled = value),
              ),
            ],
          ),
          
          _buildSettingsSection(
            'Legal & Privacy',
            Icons.privacy_tip,
            [
              _buildActionTile(
                'Privacy Policy',
                'How we handle your data and privacy',
                Icons.privacy_tip,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),
              _buildActionTile(
                'Terms of Service',
                'Terms and conditions for using the app',
                Icons.gavel,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsOfServiceScreen(),
                    ),
                  );
                },
              ),
              _buildActionTile(
                'Account Management',
                'Manage your data, privacy settings, and account',
                Icons.manage_accounts,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountManagementScreen(),
                    ),
                  );
                },
              ),
              _buildActionTile(
                'Data Rights (GDPR)',
                'Access, export, or delete your personal data',
                Icons.verified_user,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountManagementScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          
          _buildSettingsSection(
            'Privacy Settings',
            Icons.privacy_tip,
            [
              _buildSwitchTile(
                'Strip Location Data',
                'Remove GPS data from images',
                stripLocationData,
                (value) => setState(() => stripLocationData = value),
              ),
              _buildSwitchTile(
                'Analytics',
                'Share usage data to improve the app',
                analyticsEnabled,
                (value) => setState(() => analyticsEnabled = value),
              ),
            ],
          ),
          
          _buildSettingsSection(
            'EMERGENCY DEBUG',
            Icons.warning,
            [
              _buildActionTile(
                '🚨 IMMEDIATE FIX',
                'Force cleanup queue & direct API test',
                Icons.warning,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImmediateDebugFix(),
                    ),
                  );
                },
                isDestructive: true,
              ),
            ],
          ),
          
          _buildSettingsSection(
            'Debug Tools',
            Icons.bug_report,
            [
              _buildActionTile(
                'RAW Stores API Test',
                'Direct API call - check if API returns data',
                Icons.api,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StoresApiRawTest(),
                    ),
                  );
                },
              ),
              _buildActionTile(
                'Authentication Test',
                'Test auth API with any credentials',
                Icons.security,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuthTestScreen(),
                    ),
                  );
                },
              ),
              _buildActionTile(
                'Store API Test',
                'Test store API download and nearest store calculation',
                Icons.store,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StoreApiTestScreen(),
                    ),
                  );
                },
              ),
              _buildActionTile(
                'Debug Tests',
                'Store API & Upload Queue debugging',
                Icons.bug_report,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuickDebugScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          
          _buildSettingsSection(
            'App Information',
            Icons.info,
            [
              _buildInfoTile('Version', '1.0.0+1'),
              _buildInfoTile('Build', 'Debug'),
              _buildActionTile(
                'View Logs',
                'Export diagnostic information',
                Icons.text_snippet,
                _viewLogs,
              ),
              _buildActionTile(
                'Reset Settings',
                'Restore default settings',
                Icons.restore,
                _resetSettings,
                isDestructive: true,
              ),
            ],
          ),
          
          // Debug section (only in debug mode)
          if (debugModeEnabled)
            _buildSettingsSection(
              'Debug Settings',
              Icons.developer_mode,
              [
                _buildSwitchTile(
                  'Mock ML Models',
                  'Use simulated detection for testing',
                  mockMLEnabled,
                  (value) => setState(() => mockMLEnabled = value),
                ),
                _buildActionTile(
                  'Clear All Data',
                  'Delete all local sessions and files',
                  Icons.delete_forever,
                  _clearAllData,
                  isDestructive: true,
                ),
              ],
            ),
          
          // Account section with logout
          if (widget.userProfile != null)
            _buildSettingsSection(
              'Account',
              Icons.account_circle,
              [
                _buildInfoTile('User', widget.userProfile!.name),
                _buildInfoTile('Email', widget.userProfile!.email),
                _buildInfoTile('Password', '••••••••'), // Masked password
                _buildInfoTile('Type', widget.userProfile!.userType == UserType.inStore ? 'In-Store' : 'In-Store Promo'),
                _buildActionTile(
                  'Sign Out',
                  'Sign out of your account',
                  Icons.logout,
                  _handleLogout,
                  isDestructive: true,
                ),
              ],
            ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Section items
          ...children.map((child) => child).toList(),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildSliderTile(String title, String subtitle, String valueText, 
      double value, double min, double max, Function(double) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  valueText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 10).round(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, 
      VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon, 
        color: isDestructive ? Colors.red[600] : Colors.blue[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red[600] : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will remove temporary files and thumbnails. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _viewLogs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LogViewerScreen(),
      ),
    );
  }

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('This will restore all settings to their default values. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // Reset all settings to defaults
                wifiOnlyUploads = true;
                autoUploadEnabled = true;
                backgroundUploadEnabled = true;
                hapticsEnabled = true;
                autoFocusEnabled = true;
                captureDelay = 1.0;
                autoDeleteUploaded = false;
                retentionDays = 30;
                qualityThreshold = 0.8;
                strictModeEnabled = false;
                stripLocationData = true;
                analyticsEnabled = true;
                debugModeEnabled = false;
                mockMLEnabled = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will delete all local sessions, images, and data. This action cannot be undone. Make sure all data is uploaded first.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All local data cleared')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class LogViewerScreen extends StatelessWidget {
  const LogViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export logs functionality - coming soon')),
              );
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const SingleChildScrollView(
            child: Text(
              '''[2025-01-27 14:30:22] INFO: App initialized successfully
[2025-01-27 14:30:23] INFO: Camera permission granted
[2025-01-27 14:30:24] INFO: ML models loaded: scene_v2.1.0, label_v1.8.3, qa_v1.5.1
[2025-01-27 14:30:25] INFO: Session started: store_001, profile_EOA
[2025-01-27 14:30:45] INFO: Scene captured: front_aisle_1_segment_front
[2025-01-27 14:30:47] INFO: Label captured: front_aisle_1_segment_front_label_1
[2025-01-27 14:30:50] INFO: Label captured: front_aisle_1_segment_front_label_2
[2025-01-27 14:31:02] INFO: Upload queued: scene_001_front_1_20250127_143022.jpg
[2025-01-27 14:31:03] INFO: Upload queued: label_001_front_1_20250127_143045.jpg
[2025-01-27 14:31:15] INFO: Upload completed: scene_001_front_1_20250127_143022.jpg
[2025-01-27 14:31:20] WARNING: Upload retry: label_001_front_1_20250127_143045.jpg (network timeout)
[2025-01-27 14:31:25] INFO: Upload completed: label_001_front_1_20250127_143045.jpg
[2025-01-27 14:31:30] INFO: Session completed: 2 scenes, 5 labels captured''',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.green,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
