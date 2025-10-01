import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugPrefsScreen extends StatefulWidget {
  const DebugPrefsScreen({super.key});

  @override
  State<DebugPrefsScreen> createState() => _DebugPrefsScreenState();
}

class _DebugPrefsScreenState extends State<DebugPrefsScreen> {
  Map<String, dynamic> _prefs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefs = {
        'user_id': prefs.getString('user_id'),
        'user_email': prefs.getString('user_email'),
        'user_name': prefs.getString('user_name'),
        'auth_token': prefs.getString('auth_token'),
        'user_profile': prefs.getString('user_profile'),
        'user_service': prefs.getString('user_service'),
        'ALL_KEYS': prefs.getKeys().toList(),
      };
      _isLoading = false;
    });
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint('🗑️ Cleared all SharedPreferences');
    _loadPrefs();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All preferences cleared! Please restart app.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug: SharedPreferences'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrefs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current SharedPreferences:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._prefs.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${entry.key}:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '${entry.value}',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      color: entry.value == null || entry.value == 'unknown'
                                          ? Colors.red
                                          : Colors.green[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('CLEAR ALL & FORCE FRESH LOGIN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
                const Card(
                  color: Colors.orange,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '⚠️ After clearing, you MUST restart the app completely (stop and re-run).',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
