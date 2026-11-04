import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_session.dart';
import 'customer_api.dart';

class RememberedSession {
  static const _storage = FlutterSecureStorage();
  static const _key = 'garage.session';
  Future<void> save(String? token) => token == null
      ? _storage.delete(key: _key)
      : _storage.write(key: _key, value: token);

  Future<UserSession?> restore() async {
    final token = await _storage.read(key: _key);
    if (token == null) return null;
    try {
      final account = await CustomerApi(() => token).request('/auth/me');
      if (account['role'] == 'CUSTOMER' && account['customerId'] != null) {
        return UserSession(
          accessToken: token,
          accountId: account['id'],
          username: account['username'],
          customerId: account['customerId'],
        );
      }
    } on SessionExpired {
      // Remove only an invalid session. A network failure can be retried on next launch.
    }
    await save(null);
    return null;
  }

  static Duration remaining(String token) {
    final claims = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(token.split('.')[1]))),
    );
    return DateTime.fromMillisecondsSinceEpoch((claims['exp'] as int) * 1000)
        .difference(DateTime.now());
  }
}
