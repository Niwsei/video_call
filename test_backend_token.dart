// ทดสอบ token จาก backend
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('========================================');
  print('🧪 TESTING TOKEN FROM BACKEND');
  print('========================================\n');

  const apiKey = 'r9mn4fsbzhub';
  const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiNjhhZDFiYWJkMDNjNDRlZjk0M2JiNmJiIiwidmFsaWRpdHlfaW5fc2Vjb25kcyI6MzYwMCwiaWF0IjoxNzU5ODA5MzE2LCJleHAiOjE3NTk4MTI5MTZ9.H0iD8ji-dkstjFyxb7-vSnEh4A8HYy7q-cltslFTTTM';

  // Decode token
  print('🔍 Decoding token...\n');
  try {
    final parts = token.split('.');
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;

    print('Token Payload:');
    print('  user_id: ${payloadMap['user_id']}');

    final exp = payloadMap['exp'] as int?;
    if (exp != null) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final isExpired = now >= exp;

      print('  Expires at: $expiresAt');
      print('  Status: ${isExpired ? "❌ EXPIRED" : "✅ VALID"}');

      if (!isExpired) {
        final remaining = Duration(seconds: exp - now);
        print('  Time remaining: ${remaining.inMinutes} minutes');
      }
    }
  } catch (e) {
    print('❌ Error decoding token: $e');
  }

  // Test with Stream API
  print('\n🌐 Testing with Stream API...\n');

  try {
    final url = Uri.parse('https://video.stream-io-api.com/api/v2/app?api_key=$apiKey');

    final response = await http.get(
      url,
      headers: {
        'Authorization': token,
        'Stream-Auth-Type': 'jwt',
      },
    ).timeout(const Duration(seconds: 10));

    print('Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      print('✅ TOKEN IS VALID!\n');

      final data = jsonDecode(response.body);
      print('App Info:');
      print('  Name: ${data['app']?['name']}');
      print('  ID: ${data['app']?['id']}');

      print('\n✅ SUCCESS! Backend is generating correct tokens.');

    } else if (response.statusCode == 401) {
      print('❌ AUTHENTICATION FAILED!\n');

      final data = jsonDecode(response.body);
      print('Error: ${data['message']}\n');

      print('🔧 PROBLEM: Backend STREAM_API_SECRET is incorrect!');
      print('\n📝 How to fix:');
      print('1. Go to Stream Dashboard: https://dashboard.getstream.io/');
      print('2. Select app with API Key: r9mn4fsbzhub');
      print('3. Go to Settings → General');
      print('4. Click "Show" or "Reveal" next to API Secret');
      print('5. Copy the FULL secret');
      print('6. Update backend .env file:');
      print('   STREAM_API_SECRET=the_secret_you_copied');
      print('7. Restart backend server');
      print('8. Generate new token from backend');
      print('9. Test again');

    } else {
      print('⚠️ Unexpected response: ${response.statusCode}');
      print('Response: ${response.body}');
    }

  } catch (e) {
    print('❌ Connection error: $e');
  }

  print('\n========================================');
}
