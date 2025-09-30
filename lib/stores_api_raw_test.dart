import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

/// Test screen to directly check the stores API response
class StoresApiRawTest extends StatefulWidget {
  const StoresApiRawTest({super.key});

  @override
  State<StoresApiRawTest> createState() => _StoresApiRawTestState();
}

class _StoresApiRawTestState extends State<StoresApiRawTest> {
  final _tokenController = TextEditingController(text: 'RDAS');
  String _result = '';
  bool _isLoading = false;
  final _dio = Dio();

  Future<void> _testApi() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing API...';
    });

    try {
      final token = _tokenController.text.trim();
      
      debugPrint('🔍 RAW API TEST: Calling stores API');
      debugPrint('🔍 RAW API TEST: Token: $token');
      
      final response = await _dio.post(
        'https://api-token-stores-951551492434.europe-west1.run.app',
        data: {
          'token': token,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      debugPrint('🔍 RAW API TEST: Response status: ${response.statusCode}');
      debugPrint('🔍 RAW API TEST: Response type: ${response.data.runtimeType}');
      
      setState(() {
        final prettyJson = const JsonEncoder.withIndent('  ').convert(response.data);
        
        // Count stores
        int storeCount = 0;
        if (response.data is List) {
          storeCount = (response.data as List).length;
        } else if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('results') && data['results'] is List) {
            storeCount = (data['results'] as List).length;
          } else if (data.containsKey('count')) {
            storeCount = data['count'] ?? 0;
          }
        }
        
        _result = '''
✅ API Response Received!

Status Code: ${response.statusCode}
Response Type: ${response.data.runtimeType}
Number of Stores: $storeCount

${storeCount == 0 ? '⚠️ WARNING: Token "$token" has no associated stores\n⚠️ Try using "RDAS" which is known to work\n\n' : ''}
Full Response:
$prettyJson
        ''';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('🔍 RAW API TEST: Error: $e');
      
      setState(() {
        _result = '''
❌ API Call Failed

Error: $e
Error Type: ${e.runtimeType}

${e is DioException ? 'Response: ${e.response?.data}' : ''}
        ''';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raw Stores API Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Direct API Call Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tests the stores API directly without any app logic',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Token',
                border: OutlineInputBorder(),
                helperText: 'Enter "RDAS" or any user token',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testApi,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: Text(_isLoading ? 'Testing...' : 'Test API'),
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
                  child: SelectableText(
                    _result.isEmpty ? 'Results will appear here...' : _result,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
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
    _tokenController.dispose();
    super.dispose();
  }
}
