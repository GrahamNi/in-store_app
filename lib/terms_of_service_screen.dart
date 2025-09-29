import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
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
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.gavel, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Effective Date: ${DateTime.now().toString().split(' ')[0]}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildSection(
              'Agreement to Terms',
              '''By downloading, installing, or using the Label Scanner application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.

These Terms constitute a legally binding agreement between you and Dtex ("Company", "we", "us", or "our").''',
            ),
            
            _buildSection(
              'Description of Service',
              '''Label Scanner is a business application designed for:
• Capturing and analyzing retail price data
• Managing in-store data collection sessions
• Organizing and uploading business data
• Providing analytical tools for retail operations

The App is intended for business use by authorized personnel in retail environments.''',
            ),
            
            _buildSection(
              'Authorized Use',
              '''You may use the App only if:
• You are 18 years of age or older
• You are authorized by your employer to collect retail data
• You have proper permissions to photograph in retail locations
• Your use complies with all applicable laws and regulations
• You use the App solely for legitimate business purposes

Unauthorized use includes but is not limited to:
• Personal photography unrelated to business purposes
• Capturing confidential or proprietary information without permission
• Using the App in locations where photography is prohibited
• Sharing login credentials with unauthorized users''',
            ),
            
            _buildSection(
              'User Responsibilities',
              '''You are responsible for:
• Maintaining the confidentiality of your account credentials
• All activities that occur under your account
• Ensuring you have proper authorization to photograph in retail locations
• Complying with store policies and local laws
• Reporting any security breaches or unauthorized access immediately
• Using the App in a professional and ethical manner
• Backing up any critical data before major app updates''',
            ),
            
            _buildSection(
              'Prohibited Activities',
              '''You may not use the App to:
• Violate any laws, regulations, or third-party rights
• Capture images of people without their consent
• Photograph confidential, proprietary, or sensitive information without authorization
• Interfere with or disrupt the App's operation or security
• Attempt to gain unauthorized access to our systems or other users' accounts
• Use the App for any fraudulent or deceptive purposes
• Reverse engineer, decompile, or attempt to extract source code
• Transmit viruses, malware, or other malicious code''',
            ),
            
            _buildSection(
              'Intellectual Property',
              '''• The App and all its content, features, and functionality are owned by Dtex
• You retain ownership of the data you capture using the App
• We grant you a limited, non-exclusive license to use the App for business purposes
• You may not copy, modify, distribute, or create derivative works of the App
• All trademarks, logos, and brand names are the property of their respective owners
• You grant us permission to process and store your captured data as described in our Privacy Policy''',
            ),
            
            _buildSection(
              'Data and Privacy',
              '''• Your use of the App is subject to our Privacy Policy
• You are responsible for ensuring compliance with data protection laws
• We will process your data in accordance with applicable privacy regulations
• You must have proper consent or authorization for any personal data captured
• We are not responsible for data captured without proper authorization
• You may request deletion of your data as outlined in our Privacy Policy''',
            ),
            
            _buildSection(
              'Service Availability',
              '''• We strive to maintain high service availability but cannot guarantee 100% uptime
• The App may be temporarily unavailable for maintenance, updates, or technical issues
• We reserve the right to modify, suspend, or discontinue the service with reasonable notice
• Critical security updates may be applied without advance notice
• Some features may require internet connectivity to function properly''',
            ),
            
            _buildSection(
              'Limitation of Liability',
              '''TO THE MAXIMUM EXTENT PERMITTED BY LAW:

• THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND
• WE DISCLAIM ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
• WE ARE NOT LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES
• OUR TOTAL LIABILITY SHALL NOT EXCEED THE AMOUNT YOU PAID FOR THE APP IN THE LAST 12 MONTHS
• WE ARE NOT RESPONSIBLE FOR DATA LOSS, BUSINESS INTERRUPTION, OR LOST PROFITS
• YOU ASSUME ALL RISKS ASSOCIATED WITH YOUR USE OF THE APP''',
            ),
            
            _buildSection(
              'Indemnification',
              '''You agree to indemnify and hold harmless Dtex and its affiliates from any claims, damages, losses, or expenses (including legal fees) arising from:
• Your use of the App in violation of these Terms
• Your violation of any laws or third-party rights
• Unauthorized data capture or privacy violations
• Any content you submit through the App
• Your negligent or wrongful conduct''',
            ),
            
            _buildSection(
              'Termination',
              '''• You may terminate your account at any time through the App settings
• We may terminate or suspend your access for violations of these Terms
• Upon termination, your right to use the App ceases immediately
• Provisions regarding liability, indemnification, and dispute resolution survive termination
• You may request deletion of your data following account termination''',
            ),
            
            _buildSection(
              'Updates and Changes',
              '''• We may update these Terms from time to time
• Material changes will be communicated through the App or email
• Continued use after changes constitutes acceptance of new Terms
• If you disagree with changes, you may terminate your account
• We may update the App's features and functionality without notice''',
            ),
            
            _buildSection(
              'Governing Law',
              '''These Terms are governed by and construed in accordance with the laws of [Your Jurisdiction], without regard to conflict of law principles. Any disputes arising from these Terms or your use of the App shall be resolved in the courts of [Your Jurisdiction].''',
            ),
            
            _buildSection(
              'Contact Information',
              '''For questions about these Terms:

Legal Department
Email: legal@dtex.com
Subject: "Label Scanner Terms Inquiry"

General Support:
Email: support@dtex.com

Business Address:
Dtex Legal Department
[Company Address]
[City, State, ZIP]''',
            ),
            
            const SizedBox(height: 32),
            
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
                        'Important Notice',
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
                    'Always ensure you have proper authorization before capturing data in retail locations. Respect store policies and customer privacy.',
                    style: TextStyle(color: Colors.red[700]),
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
