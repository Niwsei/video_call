import 'dart:convert';

class TokenChecker {
  /// ตรวจสอบว่า JWT token หมดอายุหรือยัง
  static bool isTokenExpired(String token) {
    try {
      // แยกส่วน payload จาก JWT token (format: header.payload.signature)
      final parts = token.split('.');
      if (parts.length != 3) {
        return true; // Invalid token format
      }

      // Decode Base64 payload
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;

      // ดึง exp (expiration time) ออกมา
      final exp = payloadMap['exp'] as int?;
      if (exp == null) {
        return true; // No expiration time
      }

      // เปรียบเทียบกับเวลาปัจจุบัน
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final isExpired = now >= exp;

      if (isExpired) {
        final expiredAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        print('⚠️ Token expired at: $expiredAt');
      } else {
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        final remaining = Duration(seconds: exp - now);
        print('✅ Token valid, expires at: $expiresAt (in ${remaining.inMinutes} minutes)');
      }

      return isExpired;
    } catch (e) {
      print('❌ Error checking token expiry: $e');
      return true; // Treat errors as expired
    }
  }

  /// ดึงข้อมูล user ID จาก token
  static String? getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;

      return payloadMap['user_id'] as String?;
    } catch (e) {
      print('❌ Error extracting user_id from token: $e');
      return null;
    }
  }

  /// แสดงข้อมูลทั้งหมดใน token (สำหรับ debug)
  static void printTokenInfo(String token, String label) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('❌ Invalid token format for $label');
        return;
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;

      print('========================================');
      print('🔑 TOKEN INFO: $label');
      print('User ID: ${payloadMap['user_id']}');

      final iat = payloadMap['iat'] as int?;
      if (iat != null) {
        final issuedAt = DateTime.fromMillisecondsSinceEpoch(iat * 1000);
        print('Issued at: $issuedAt');
      }

      final exp = payloadMap['exp'] as int?;
      if (exp != null) {
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final isExpired = now >= exp;

        print('Expires at: $expiresAt');
        print('Status: ${isExpired ? "❌ EXPIRED" : "✅ VALID"}');

        if (!isExpired) {
          final remaining = Duration(seconds: exp - now);
          print('Time remaining: ${remaining.inMinutes} minutes');
        }
      }

      print('========================================');
    } catch (e) {
      print('❌ Error printing token info: $e');
    }
  }
}
