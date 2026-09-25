import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/constants/app_config.dart';
import '../models/user_session.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthService {
  Future<UserSession> login({
    required String username,
    required String password,
  });

  Future<void> logout(UserSession session);
}

class ApiAuthService implements AuthService {
  ApiAuthService({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<UserSession> login({
    required String username,
    required String password,
  }) async {
    try {
      final request = await _client.postUrl(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/login'),
      );
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({'username': username.trim(), 'password': password}),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final payload = jsonDecode(
        await utf8.decoder.bind(response).join(),
      ) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthException(
          payload['message']?.toString() ??
              'Đăng nhập không thành công. Vui lòng thử lại.',
        );
      }

      final data = payload['data'] as Map<String, dynamic>?;
      final account = data?['account'] as Map<String, dynamic>?;
      if (data == null ||
          account == null ||
          account['role'] != 'CUSTOMER' ||
          account['customerId'] == null) {
        throw const AuthException(
          'Ứng dụng mobile chỉ dành cho tài khoản khách hàng.',
        );
      }
      return UserSession(
        accessToken: data['accessToken'] as String,
        accountId: account['id'] as int,
        username: account['username'] as String,
        customerId: account['customerId'] as int,
      );
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException(
        'Máy chủ phản hồi quá lâu. Vui lòng kiểm tra kết nối và thử lại.',
      );
    } on SocketException {
      throw const AuthException(
        'Không thể kết nối đến máy chủ. Hãy kiểm tra backend đang chạy.',
      );
    } on FormatException {
      throw const AuthException('Dữ liệu phản hồi từ máy chủ không hợp lệ.');
    }
  }

  @override
  Future<void> logout(UserSession session) async {
    try {
      final request = await _client.postUrl(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/logout'),
      );
      request.headers
        ..contentType = ContentType.json
        ..set(HttpHeaders.authorizationHeader, 'Bearer ${session.accessToken}');
      await request.close().timeout(const Duration(seconds: 5));
    } catch (_) {
      // Backend logout is stateless; local session is cleared by AppController.
    }
  }
}

class MockAuthService implements AuthService {
  const MockAuthService();

  @override
  Future<UserSession> login({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (username.trim().isEmpty || password.isEmpty) {
      throw const AuthException('Vui lòng nhập tên đăng nhập và mật khẩu.');
    }
    return UserSession(
      accessToken: 'mock-token',
      accountId: 9,
      username: username.trim(),
      customerId: 1,
    );
  }

  @override
  Future<void> logout(UserSession session) async {}
}
