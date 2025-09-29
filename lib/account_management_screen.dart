import 'package:flutter/material.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  bool isExportingData = false;
  bool isDeletingAccount = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Account Management',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Info Section
            _buildSection(
              'Account Information',
              [
                _buildInfoTile('Email', 'user@example.com'),
                _buildInfoTile('Account Created', 'January 27, 2025'),
                _buildInfoTile('Last Login', 'Today at 2:30 PM'),
                _buildInfoTile('Data Usage', '156 captures this month'),
                _buildActionTile(
                  'Update Profile',
                  'Change email or account details',
                  Icons.edit,
                  () => _showComingSoon('Profile updates'),
                ),
              ],
            ),

            // Data Rights Section
            _buildSection(
              'Your Data Rights (GDPR)',
              [
                _buildActionTile(
                  'Download My Data',
                  'Export all your data in JSON format',
                  Icons.download,
                  _exportUserData,
                  isLoading: isExportingData,
                ),
                _buildActionTile(
                  'View Data Usage',
                  'See what data we collect and how it\'s used',
                  Icons.visibility,
                  () => _showDataUsageDialog(),
                ),
                _buildActionTile(
                  'Request Data Correction',
                  'Correct inaccurate personal information',
                  Icons.edit_note,
                  () => _showComingSoon('Data correction requests'),
                ),
                _buildActionTile(
                  'Data Portability',
                  'Transfer your data to another service',
                  Icons.import_export,
                  () => _showComingSoon('Data portability'),
                ),
              ],
            ),

            // Privacy Controls Section
            _buildSection(
              'Privacy Controls',
              [
                _buildActionTile(
                  'Manage Permissions',
                  'Review camera and location permissions',
                  Icons.security,
                  () => _showPermissionsDialog(),
                ),
                _buildActionTile(
                  'Data Retention Settings',
                  'Control how long data is stored locally',
                  Icons.schedule,
                  () => _showDataRetentionDialog(),
                ),
                _buildActionTile(
                  'Analytics Preferences',
                  'Control anonymous usage analytics',
                  Icons.analytics,
                  () => _showAnalyticsDialog(),
                ),
              ],
            ),

            // Danger Zone Section
            _buildSection(
              'Account Deletion',
              [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Permanent Account Deletion',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This action will permanently delete your account and all associated data. This cannot be undone.',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isDeletingAccount ? null : _deleteAccount,
                          icon: isDeletingAccount
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.delete_forever),
                          label: Text(isDeletingAccount ? 'Deleting...' : 'Delete Account'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Legal Links
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Legal Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'For questions about your data rights or privacy concerns, contact privacy@dtex.com',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
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
          ...children,
        ],
      ),
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

  Widget _buildActionTile(String title, String subtitle, IconData icon, 
      VoidCallback onTap, {bool isLoading = false}) {
    return ListTile(
      leading: isLoading 
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, color: Colors.blue[600]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: isLoading ? null : onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _exportUserData() async {
    setState(() {
      isExportingData = true;
    });

    // Simulate export process
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isExportingData = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Data Export Complete'),
          content: const Text(
            'Your data has been prepared for download. In the full version, this would provide a download link for a ZIP file containing all your data in JSON format.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you absolutely sure you want to delete your account? This action cannot be undone and will permanently delete:\n\n• All your captured data\n• Session history\n• Account preferences\n• Upload queue\n\nType "DELETE" to confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmAccountDeletion();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _confirmAccountDeletion() async {
    setState(() {
      isDeletingAccount = true;
    });

    // Simulate account deletion process
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      isDeletingAccount = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Account Deleted'),
          content: const Text(
            'Your account has been permanently deleted. In the full version, you would be logged out and redirected to the login screen.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showDataUsageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Usage Summary'),
        content: const SingleChildScrollView(
          child: Text(
            '''We collect and use your data as follows:

Camera Images:
• Purpose: Price data analysis
• Storage: 30 days locally, permanent on server
• Access: Only authorized personnel

Location Data:
• Purpose: Store identification and organization
• Storage: Indefinitely for business records
• Access: Your organization and Dtex

Usage Analytics:
• Purpose: App improvement
• Storage: 2 years, anonymized after 90 days
• Access: Dtex development team only

You can request detailed information about any specific data point at privacy@dtex.com''',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPermissionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Permissions'),
        content: const Text(
          '''Current permissions and their purpose:

📷 Camera: Required for capturing price labels and store displays

📍 Location: Used to identify store locations and organize data by geographic area

💾 Storage: Needed to save captured images locally before upload

🌐 Network: Required for uploading data and syncing with servers

You can modify these permissions in your device settings, but some features may not work without them.''',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDataRetentionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Retention Settings'),
        content: const Text(
          '''Current retention settings:

Local Images: 30 days (configurable: 7-90 days)
Session Data: Permanent until manual deletion
Upload Queue: Cleared after successful upload
Error Logs: 7 days
Usage Analytics: 90 days before anonymization

Server Data Retention:
Business data is retained according to your organization's data retention policy. Contact your administrator for details.''',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analytics Preferences'),
        content: const Text(
          '''We collect anonymous usage data to improve the app:

• Feature usage statistics
• Performance metrics
• Crash reports (no personal data)
• General usage patterns

This data helps us identify bugs, improve performance, and develop new features. No personal or business data is included in analytics.

You can opt out of analytics in the main Settings screen.''',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature will be available in a future update'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
