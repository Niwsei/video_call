import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../app_keys.dart';

class StreamAuth {
  final String apiKey;
  final String userId;
  final String token;
  final int? expiresAt;
  final String? fullName;
  final String? role;

  const StreamAuth({
    required this.apiKey,
    required this.userId,
    required this.token,
    this.expiresAt,
    this.fullName,
    this.role,
  });

  factory StreamAuth.fromJson(Map<String, dynamic> json) => StreamAuth(
        apiKey: json['apiKey'] as String,
        userId: (json['userId'] ?? json['id']) as String,
        token: json['token'] as String,
        expiresAt: json['expiresAt'] is int ? json['expiresAt'] as int : null,
        fullName: json['fullName'] as String?,
        role: json['role'] as String?,
      );
}

class TokenService {
  static String _resolveBaseUrl() {
    // Note: 10.0.2.2 only works on Android emulators. On real devices,
    // set BACKEND_BASE_URL to your machine IP (e.g. http://192.168.x.x:8181).
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AppKeys.backendBaseUrl.replaceFirst('localhost', '10.0.2.2');
    }
    return AppKeys.backendBaseUrl;
  }

  /// Calls POST {baseUrl}/v1/api/callStreams to obtain a Stream user token.
  /// Expects backend to optionally require Authorization Bearer (AppKeys.backendBearerToken).
  static Future<StreamAuth> fetchStreamAuth({
    Map<String, dynamic>? body,
    String? accessToken,
  }) async {
    final base = _resolveBaseUrl();
    final uri = Uri.parse('$base/v1/api/callStreams');

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final bearer = accessToken?.trim().isNotEmpty == true
        ? accessToken!.trim()
        : AppKeys.backendBearerToken;
    if (bearer.isNotEmpty) {
      headers['Authorization'] = 'Bearer $bearer';
    }

    try {
      final res = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
        return StreamAuth.fromJson(jsonMap);
      }

      debugPrint('Token endpoint error ${res.statusCode}: ${res.body}');
      throw Exception('Token endpoint error: ${res.statusCode}');
    } on TimeoutException catch (e) {
      debugPrint('Token endpoint TimeoutException: $e');
      throw Exception('Token endpoint timeout');
    }
  }
}
