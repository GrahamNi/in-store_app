import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/store_service.dart';

class AuthDiagnosticScreen extends StatefulWidget {
  const AuthDiagnosticScreen({super.key});

  @override
  State<AuthDiagnosticScreen> createState() => _AuthDiagnosticScreenState();
}

class _AuthDiagnosticScreenState extends State<AuthDiagnosticScreen> {
  Map<String, String?> _authData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _authData = {
        'user_id': prefs.getString('user_id'),
        'user_email': prefs.getString('user_email'),
        'user_name': prefs.getString('user_name'),
        'user_profile': prefs.getString('user_profile'),
        'user_service': prefs.getString('user_service'),
        'auth_token': prefs.getString('auth_token'),
      };
      _isLoading = false;
    });
    
    // Also check what StoreService sees
    final userId = await StoreService.getCurrentUserId();
    final hasValid = await StoreService.hasValidUserId();
    
    debugPrint('🔍 DIAGNOSTIC: StoreService user_id: $userId');
    debugPrint('🔍 DIAGNOSTIC: Has valid user_id: $hasValid');
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_profile');
    await prefs.remove('user_service');
    await prefs.remove('auth_token');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auth data cleared!')),
      );
      _loadAuthData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Diagnostic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAuthData,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearAuthData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection('Saved User Data', [
                  _buildDataRow('User ID', _authData['user_id']),
                  _buildDataRow('Email', _authData['user_email']),
                  _buildDataRow('Name', _authData['user_name']),
                  _buildDataRow('Profile', _authData['user_profile']),
                  _buildDataRow('Service', _authData['user_service']),
                  _buildDataRow('Token', 
                    _authData['auth_token'] != null 
                      ? '${_authData['auth_token']!.substring(0, 20)}...' 
                      : null
                  ),
                ]),
                
                const SizedBox(height: 24),
                
                _buildSection('Diagnostics', [
                  _buildStatusRow(
                    'User ID Present',
                    _authData['user_id'] != null,
                  ),
                  _buildStatusRow(
                    'User ID Valid',
                    _authData['user_id'] != null && 
                    _authData['user_id'] != 'unknown' &&
                    _authData['user_id']!.isNotEmpty,
                  ),
                  _buildStatusRow(
                    'Profile Set',
                    _authData['user_profile'] != null,
                  ),
                  _buildStatusRow(
                    'Token Present',
                    _authData['auth_token'] != null,
                  ),
                ]),
                
                const SizedBox(height: 24),
                
                _buildSection('Expected Behavior', [
                  const Text(
                    '✅ user_id should be present and not "unknown"\n'
                    '✅ user_profile should indicate "fmcgnz" or similar\n'
                    '✅ Store API will use user_id to fetch correct stores\n\n'
                    '❌ If user_id is missing/unknown, API falls back to "RDAS"\n'
                    '❌ This causes wrong stores to be loaded',
                    style: TextStyle(fontSize: 14),
                  ),
                ]),
                
                const SizedBox(height: 24),
                
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '(not set)',
              style: TextStyle(
                color: value == null ? Colors.red : Colors.black,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isOk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.error,
            color: isOk ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
