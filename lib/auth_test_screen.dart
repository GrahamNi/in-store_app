import 'package:flutter/material.dart';
import 'services/auth_service.dart';

/// Quick test screen to validate authentication API behavior
class AuthTestScreen extends StatefulWidget {
  const AuthTestScreen({super.key});

  @override
  State<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends State<AuthTestScreen> {
  final _usernameController = TextEditingController(text: 'a');
  final _passwordController = TextEditingController(text: 'a');
  String _result = '';
  bool _isLoading = false;

  Future<void> _testAuth() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing...';
    });

    try {
      final response = await AuthService.authenticate(
        _usernameController.text,
        _passwordController.text,
      );
      
      setState(() {
        _result = '''
✅ Authentication SUCCEEDED (This might be wrong!)

Response:
- User ID: ${response.userId}
- Token: ${response.token ?? 'null'}
- Service: ${response.service ?? 'null'}
- Profile: ${response.profile ?? 'null'}
- Name: ${response.name ?? 'null'}
- Email: ${response.email ?? 'null'}
- Is Profile A: ${response.isProfileA}

Raw Data:
${response.rawData}
        ''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = '❌ Authentication FAILED (Expected):\n\n$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth API Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test what the auth API returns for invalid credentials',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAuth,
              child: Text(_isLoading ? 'Testing...' : 'Test Authentication'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Text(
                    _result.isEmpty ? 'Results will appear here...' : _result,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
