import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Last Updated: ${DateTime.now().toString().split(' ')[0]}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              'Overview',
              'Label Scanner is a business application designed for retail price data collection. We are committed to protecting your privacy and being transparent about how we handle your data.',
            ),
            
            _buildSection(
              'Information We Collect',
              '''We collect only the information necessary to provide our service:

• Camera Images: Photos of price labels and store displays for data analysis
• Location Data: Store location for organizing captured data (approximate location only)
• Device Information: Basic device details for app functionality and support
• Usage Data: How you interact with the app to improve performance
• Account Information: Email address and profile information for authentication

We do NOT collect:
• Personal photos or images outside of work sessions
• Precise location tracking or movement patterns
• Personal contacts, messages, or other apps data
• Biometric information or facial recognition data''',
            ),
            
            _buildSection(
              'How We Use Your Information',
              '''Your data is used exclusively for business purposes:

• Processing and analyzing retail price data
• Organizing captures by store location and session
• Providing upload progress and session management
• Improving app performance and fixing bugs
• Providing customer support when requested

We do NOT:
• Sell your data to third parties
• Use your data for advertising purposes
• Share images outside of your organization
• Access your data for any non-business purposes''',
            ),
            
            _buildSection(
              'Data Storage & Security',
              '''• Local Storage: Images and data are stored securely on your device
• Cloud Upload: Data is transmitted using encrypted connections (TLS/SSL)
• Server Storage: Uploaded data is stored on secure business servers
• Access Control: Only authorized personnel can access uploaded data
• Retention: Local data is kept for 30 days by default (configurable in settings)
• Backup: Uploaded data is backed up according to business requirements''',
            ),
            
            _buildSection(
              'Your Rights & Controls',
              '''You have full control over your data:

• Access: View all data collected about you
• Export: Download your data in a standard format
• Delete: Remove your account and all associated data
• Modify: Update your profile and preferences
• Withdraw Consent: Stop data collection at any time
• Portability: Transfer your data to another service

To exercise these rights, use the account management options in Settings or contact support.''',
            ),
            
            _buildSection(
              'Third-Party Services',
              '''We use minimal third-party services:

• Cloud Storage: For secure data backup and synchronization
• Analytics: Basic app performance metrics (no personal data)
• Authentication: Secure login and account management

All third parties are bound by strict data protection agreements and cannot access your business data.''',
            ),
            
            _buildSection(
              'International Transfers',
              '''If your data is transferred internationally, we ensure:

• Adequate protection equivalent to GDPR standards
• Standard contractual clauses for data protection
• Your explicit consent for any transfers outside secure regions
• Regular audits of international data handling practices''',
            ),
            
            _buildSection(
              'Children\'s Privacy',
              '''Label Scanner is designed for business use by adults (18+). We do not knowingly collect data from children under 18. If we discover such data has been collected, we will delete it immediately.''',
            ),
            
            _buildSection(
              'Changes to This Policy',
              '''We may update this privacy policy to reflect changes in our practices or legal requirements. When we make significant changes:

• We will notify you within the app
• The "Last Updated" date will be revised
• You will be asked to review and accept changes
• You can always access the current version in Settings''',
            ),
            
            _buildSection(
              'Contact Information',
              '''For privacy-related questions or requests:

Email: privacy@dtex.com
Subject Line: "Label Scanner Privacy Request"

For urgent privacy concerns or data breaches:
Email: security@dtex.com

For general support:
Email: support@dtex.com

Postal Address:
Dtex Privacy Officer
[Company Address]
[City, State, ZIP]''',
            ),
            
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Your Data Rights',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can manage your data and privacy settings in the Account Management section of Settings.',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
