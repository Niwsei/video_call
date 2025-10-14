// ตรวจสอบการตั้งค่า Stream และทดสอบ connection
// Run: dart verify_stream_config.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('========================================');
  print('🔍 VERIFYING STREAM CONFIGURATION');
  print('========================================\n');

  // ข้อมูลจาก dev_manual_auth.dart
  const apiKey = 'r9mn4fsbzhub';
  const userAId = '6721f3f8cd5644f9dc80f4f9';
  const userAToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNjcyMWYzZjhjZDU2NDRmOWRjODBmNGY5IiwidmFsaWRpdHlfaW5fc2Vjb25kcyI6MzYwMCwiaWF0IjoxNzU5ODA2MTA0LCJleHAiOjE3NTk4MDk3MDR9.TDderLmOXPviB2k_EoKDKNmj23QPhg-V1H0UPnaroY4';

  print('📋 Configuration:');
  print('   API Key: $apiKey');
  print('   User A ID: $userAId');
  print('   Token (first 20 chars): ${userAToken.substring(0, 20)}...\n');

  // Decode JWT token
  try {
    final parts = userAToken.split('.');
    if (parts.length == 3) {
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;

      print('🔑 Token Payload:');
      print('   user_id: ${payloadMap['user_id']}');

      final iat = payloadMap['iat'] as int?;
      final exp = payloadMap['exp'] as int?;

      if (iat != null) {
        final issuedAt = DateTime.fromMillisecondsSinceEpoch(iat * 1000);
        print('   Issued at: $issuedAt');
      }

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

      // Check if user_id in token matches
      final tokenUserId = payloadMap['user_id'] as String?;
      if (tokenUserId != userAId) {
        print('\n⚠️ WARNING: user_id in token ($tokenUserId) does not match userAId ($userAId)!');
      }

      print('');
    }
  } catch (e) {
    print('❌ Error decoding token: $e\n');
  }

  // Test Stream API connection
  print('🌐 Testing Stream API connection...');

  try {
    // Try to get app settings
    final url = Uri.parse('https://video.stream-io-api.com/api/v2/app?api_key=$apiKey');

    final response = await http.get(
      url,
      headers: {
        'Authorization': userAToken,
        'Stream-Auth-Type': 'jwt',
      },
    ).timeout(const Duration(seconds: 10));

    print('   Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      print('   ✅ Successfully connected to Stream API');

      final data = jsonDecode(response.body);
      print('\n📱 App Info:');
      print('   Name: ${data['app']?['name'] ?? 'N/A'}');
      print('   ID: ${data['app']?['id'] ?? 'N/A'}');

    } else if (response.statusCode == 401) {
      print('   ❌ Authentication failed!');
      print('   Response: ${response.body}');
      print('\n🔧 Possible issues:');
      print('   1. API Key is incorrect');
      print('   2. Token is invalid or expired');
      print('   3. Token does not match API Key');

    } else {
      print('   ⚠️ Unexpected response: ${response.statusCode}');
      print('   Response: ${response.body}');
    }

  } catch (e) {
    print('   ❌ Connection error: $e');
    print('\n🔧 Possible issues:');
    print('   1. Network/Firewall blocking Stream API');
    print('   2. Internet connection issue');
  }

  print('\n========================================');
  print('📝 NEXT STEPS');
  print('========================================');
  print('1. Go to Stream Dashboard: https://dashboard.getstream.io/');
  print('2. Find your app with API Key: $apiKey');
  print('3. Check if users exist:');
  print('   - User A: $userAId');
  print('   - User B: 68a2eccfbffc43ed49cdf13f');
  print('4. If users don\'t exist, generate new tokens from Dashboard');
  print('5. Make sure you\'re looking at the correct app in Dashboard logs');
  print('========================================');
}
