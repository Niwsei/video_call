// ทดสอบ token ใหม่ก่อนใส่ในแอป
// Run: dart test_new_token.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('========================================');
  print('🧪 TESTING NEW STREAM TOKEN');
  print('========================================\n');

  // ใส่ token ใหม่ตรงนี้
  print('Paste your new token from Stream Dashboard:');
  final newToken = stdin.readLineSync()?.trim() ?? '';

  if (newToken.isEmpty) {
    print('❌ Token is empty!');
    return;
  }

  const apiKey = 'r9mn4fsbzhub';

  print('\n🔍 Testing token...\n');

  // Decode token
  try {
    final parts = newToken.split('.');
    if (parts.length != 3) {
      print('❌ Invalid token format!');
      return;
    }

    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;

    print('✅ Token decoded successfully');
    print('   User ID: ${payloadMap['user_id']}');

    final exp = payloadMap['exp'] as int?;
    if (exp != null) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final isExpired = now >= exp;

      print('   Expires at: $expiresAt');
      print('   Status: ${isExpired ? "❌ EXPIRED" : "✅ VALID"}');

      if (!isExpired) {
        final remaining = Duration(seconds: exp - now);
        print('   Time remaining: ${remaining.inMinutes} minutes');
      }
    }
  } catch (e) {
    print('❌ Error decoding token: $e');
    return;
  }

  // Test with Stream API
  print('\n🌐 Testing with Stream API...');

  try {
    final url = Uri.parse('https://video.stream-io-api.com/api/v2/app?api_key=$apiKey');

    final response = await http.get(
      url,
      headers: {
        'Authorization': newToken,
        'Stream-Auth-Type': 'jwt',
      },
    ).timeout(const Duration(seconds: 10));

    print('   Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      print('   ✅ TOKEN IS VALID AND WORKING!');

      final data = jsonDecode(response.body);
      print('\n📱 App Info:');
      print('   Name: ${data['app']?['name'] ?? 'N/A'}');
      print('   ID: ${data['app']?['id'] ?? 'N/A'}');

      print('\n✅ SUCCESS! This token is correct.');
      print('Copy this token and paste it into lib/dev_manual_auth.dart');

    } else if (response.statusCode == 401) {
      print('   ❌ TOKEN AUTHENTICATION FAILED!');
      print('   Response: ${response.body}');
      print('\n❌ This token is NOT valid for API Key: $apiKey');
      print('Make sure you generated it from the correct app in Dashboard.');

    } else {
      print('   ⚠️ Unexpected response: ${response.statusCode}');
      print('   Response: ${response.body}');
    }

  } catch (e) {
    print('   ❌ Connection error: $e');
  }

  print('\n========================================');
}
